import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';
import '../repo/content_repo.dart';
import 'reminder_isolate.dart';

/// Schedules medication alarms using AndroidAlarmManager.
///
/// Per AGENTS.md non-negotiable #6: Alarm callbacks run in a separate isolate
/// with no access to main isolate state. Each alarm opens its own Drift connection.
///
/// Alarm IDs are deterministic: `(medId.hashCode & 0x00FFFFFF) * 10 + dayOfWeek`
/// per APP-BUILD-SPEC.md §10.
class AlarmScheduler {
  AlarmScheduler({
    required this.db,
    required this.contentRepo,
  });

  final SmritiDatabase db;
  final ContentRepo contentRepo;

  /// Calculates a deterministic alarm ID for a medication and day of week.
  ///
  /// The ID is used to uniquely identify each scheduled alarm so it can be
  /// cancelled or rescheduled later.
  int _alarmId(String medId, int dayOfWeek) {
    return (medId.hashCode & 0x00FFFFFF) * 10 + dayOfWeek;
  }

  /// Reschedules all medication alarms.
  ///
  /// Called after:
  /// - Content pull (medications may have changed)
  /// - Device boot (alarms need to be recreated)
  /// - Manual request
  ///
  /// For each active medication and each day of week it's scheduled for:
  /// 1. Cancels any existing alarm for that medication/day
  /// 2. Calculates the next occurrence
  /// 3. Schedules a new alarm
  Future<void> rescheduleAll() async {
    // Cancel everything scheduled last time. This runs after the content swap,
    // so the current medication list no longer knows about deleted medicines
    // or removed days; only the stored ID set does.
    for (final id in await _loadScheduledIds()) {
      await AndroidAlarmManager.cancel(id);
    }
    await _cancelAllAlarms();

    // Get all active medications
    final medications = await contentRepo.getMedications(activeOnly: true);

    // Schedule alarms for each medication
    final scheduled = <int>{};
    for (final med in medications) {
      scheduled.addAll(await _scheduleMedicationAlarms(med));
    }
    await db.appConfigsDao.setValue(_scheduledIdsKey, scheduled.join(','));
  }

  /// AppConfigs key holding the comma-separated alarm IDs from the last
  /// [rescheduleAll].
  static const String _scheduledIdsKey = 'scheduledAlarmIds';

  Future<Set<int>> _loadScheduledIds() async {
    final raw = await db.appConfigsDao.getValue(_scheduledIdsKey);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').map(int.tryParse).whereType<int>().toSet();
  }

  /// Whether this medication's reminder has fired within [window]. A reminder
  /// that already went off must not be "caught up" again by a reschedule
  /// (e.g. the sync that runs right after the elder taps "I Have Taken It").
  Future<bool> _firedRecently(String medId, Duration window) async {
    final since = DateTime.now().subtract(window).millisecondsSinceEpoch;
    final row = await (db.select(db.reminderEvents)
          ..where((t) =>
              t.medicationId.equals(medId) &
              t.firedAt.isBiggerOrEqualValue(since))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Schedules alarms for a single medication and returns their IDs.
  Future<List<int>> _scheduleMedicationAlarms(Medication med) async {
    // Parse days of week (1-7, where 1=Monday)
    final days = parseDaysOfWeek(med.daysOfWeek);
    final ids = <int>[];
    final allowCatchUp = !await _firedRecently(med.id, _catchUpWindow * 2);

    for (final day in days) {
      // Calculate next occurrence for this day
      final nextTime =
          _nextOccurrence(day, med.chosenTimeMin, allowCatchUp: allowCatchUp);
      
      if (nextTime == null) {
        // Shouldn't happen, but skip if we can't calculate
        continue;
      }

      final alarmId = _alarmId(med.id, day);

      // Schedule the alarm
      await AndroidAlarmManager.oneShotAt(
        nextTime,
        alarmId,
        fireReminderCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        alarmClock: true,
        rescheduleOnReboot: true,
        params: {
          'medicationId': med.id,
          'dayOfWeek': day,
        },
      );
      ids.add(alarmId);
    }
    return ids;
  }

  /// Cancels all existing medication alarms.
  Future<void> _cancelAllAlarms() async {
    final medications = await contentRepo.getMedications(activeOnly: true);

    for (final med in medications) {
      final days = parseDaysOfWeek(med.daysOfWeek);
      for (final day in days) {
        final alarmId = _alarmId(med.id, day);
        await AndroidAlarmManager.cancel(alarmId);
      }
    }
  }

  /// Cancels alarms for a specific medication.
  Future<void> cancelForMedication(String medId) async {
    final med = await contentRepo.getMedication(medId);
    if (med == null) return;

    final days = parseDaysOfWeek(med.daysOfWeek);
    for (final day in days) {
      final alarmId = _alarmId(med.id, day);
      await AndroidAlarmManager.cancel(alarmId);
    }
  }

  /// Parses the daysOfWeek string into a list of day indices.
  ///
  /// Format: comma-separated day indices (1-7, where 1=Monday)
  static List<int> parseDaysOfWeek(String daysOfWeek) {
    return daysOfWeek
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  /// How long after its time a reminder that hasn't fired yet (e.g. the
  /// caregiver just set it for "now") is still fired immediately.
  static const Duration _catchUpWindow = Duration(minutes: 2);

  /// Calculates the next occurrence time for a medication on a given day.
  ///
  /// With [allowCatchUp], a time that passed less than [_catchUpWindow] ago
  /// fires in 3 seconds instead of waiting a week. It must be false right
  /// after a reminder fires, or the reminder re-fires in a loop.
  ///
  /// Returns null if the medication is not scheduled for any upcoming time.
  DateTime? _nextOccurrence(
    int dayOfWeek,
    int chosenTimeMin, {
    bool allowCatchUp = false,
  }) {
    final now = DateTime.now();
    final today = now.weekday; // 1=Monday, 7=Sunday

    // chosenTimeMin is minutes from midnight
    final todayTime = DateTime(
      now.year,
      now.month,
      now.day,
      chosenTimeMin ~/ 60,
      chosenTimeMin % 60,
    );

    // If today is the target day
    if (today == dayOfWeek) {
      if (todayTime.isAfter(now)) {
        return todayTime;
      } else if (allowCatchUp && now.difference(todayTime) < _catchUpWindow) {
        // Just scheduled for the current minute or right now - fire in 3 seconds!
        return now.add(const Duration(seconds: 3));
      }
    }

    // Find the next day of week
    int daysToAdd = 0;

    if (today < dayOfWeek) {
      daysToAdd = dayOfWeek - today;
    } else if (today > dayOfWeek) {
      daysToAdd = 7 - (today - dayOfWeek);
    } else {
      // Same day but time has passed - schedule for next week
      daysToAdd = 7;
    }

    return DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      chosenTimeMin ~/ 60,
      chosenTimeMin % 60,
    );
  }

  /// Schedules the next occurrence of a medication after one fires.
  ///
  /// Called by the reminder callback after an alarm fires, so never catches
  /// up: the time that just passed is the one that fired.
  Future<void> scheduleNextOccurrence(Medication med, int dayOfWeek) async {
    final nextTime = _nextOccurrence(dayOfWeek, med.chosenTimeMin);
    if (nextTime == null) return;

    final alarmId = _alarmId(med.id, dayOfWeek);
    
    await AndroidAlarmManager.oneShotAt(
      nextTime,
      alarmId,
      fireReminderCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      alarmClock: true,
      rescheduleOnReboot: true,
      params: {
        'medicationId': med.id,
        'dayOfWeek': dayOfWeek,
      },
    );
  }
}

