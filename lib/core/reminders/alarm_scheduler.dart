import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../db/app_database.dart';
import '../db/database.dart';
import '../repo/content_repo.dart';

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
    // Cancel all existing alarms first
    await _cancelAllAlarms();

    // Get all active medications
    final medications = await contentRepo.getMedications(activeOnly: true);

    // Schedule alarms for each medication
    for (final med in medications) {
      await _scheduleMedicationAlarms(med);
    }
  }

  /// Schedules alarms for a single medication.
  Future<void> _scheduleMedicationAlarms(Medication med) async {
    // Parse days of week (1-7, where 1=Monday)
    final days = _parseDaysOfWeek(med.daysOfWeek);

    for (final day in days) {
      // Calculate next occurrence for this day
      final nextTime = _nextOccurrence(day, med.chosenTimeMin);
      
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
        rescheduleOnReboot: true,
        params: {
          'medicationId': med.id,
          'dayOfWeek': day,
        },
      );
    }
  }

  /// Cancels all existing medication alarms.
  Future<void> _cancelAllAlarms() async {
    final medications = await contentRepo.getMedications(activeOnly: true);

    for (final med in medications) {
      final days = _parseDaysOfWeek(med.daysOfWeek);
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

    final days = _parseDaysOfWeek(med.daysOfWeek);
    for (final day in days) {
      final alarmId = _alarmId(med.id, day);
      await AndroidAlarmManager.cancel(alarmId);
    }
  }

  /// Parses the daysOfWeek string into a list of day indices.
  ///
  /// Format: comma-separated day indices (1-7, where 1=Monday)
  List<int> _parseDaysOfWeek(String daysOfWeek) {
    return daysOfWeek
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  /// Calculates the next occurrence time for a medication on a given day.
  ///
  /// Returns null if the medication is not scheduled for any upcoming time.
  DateTime? _nextOccurrence(int dayOfWeek, int chosenTimeMin) {
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

    // If today is the target day and the time hasn't passed yet
    if (today == dayOfWeek && todayTime.isAfter(now)) {
      return todayTime;
    }

    // Find the next day of week
    int nextDay = dayOfWeek;
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
  /// Called by the reminder callback after an alarm fires.
  Future<void> scheduleNextOccurrence(Medication med, int dayOfWeek) async {
    final nextTime = _nextOccurrence(dayOfWeek, med.chosenTimeMin);
    if (nextTime == null) return;

    final alarmId = _alarmId(med.id, dayOfWeek);
    
    await AndroidAlarmManager.oneShotAt(
      nextTime,
      alarmId,
      _fireReminderCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      params: {
        'medicationId': med.id,
        'dayOfWeek': dayOfWeek,
      },
    );
  }
}

/// The alarm callback that fires when a medication reminder is due.
///
/// This is a top-level function so it can be used with AndroidAlarmManager.
/// It opens its own Drift connection and has no access to main isolate state.
///
/// Per AGENTS.md non-negotiable #6.
@pragma('vm:entry-point')
Future<void> _fireReminderCallback(int id, Map<String, dynamic> params) async {
  // This callback needs to:
  // 1. Initialize Flutter bindings
  // 2. Open its own database connection
  // 3. Get the medication
  // 4. Create a ReminderEvent
  // 5. Show full-screen notification
  // 6. Play caregiver audio
  // 7. Schedule ladder steps
  // 8. Schedule next occurrence
  // 9. Close database connection
  
  // For now, this is a placeholder. The full implementation requires:
  // - Proper database initialization in isolate
  // - Notification system setup
  // - Audio playback
  // - Alarm rescheduling
  
  // TODO: Implement full reminder callback
}
