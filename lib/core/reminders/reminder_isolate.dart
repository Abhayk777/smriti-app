import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../repo/content_repo.dart';
import '../repo/event_repo.dart';
import 'alarm_scheduler.dart';
import 'reminder_launcher.dart';
import 'reminder_screen_channel.dart';

/// `reminder_events.channel` for reminders the device itself shows (ladder
/// steps 0 and 1), per APP-BUILD-SPEC.md §10. Older builds wrote
/// 'fullscreen', which EventPusher maps to this on upload.
const String reminderChannelInApp = 'in_app';

/// Ladder step configuration.
class LadderConfig {
  /// Step 0: Immediate full-screen notification with caregiver's voice
  static const int step0DelayMinutes = 0;
  
  /// Step 1: Repeat notification, louder (15 minutes after Step 0)
  static const int step1DelayMinutes = 15;
  
  /// Step 2: Write to EscalationRequests table -> server places real phone call
  static const int step2DelayMinutes = 30;
}

/// The reminder callback that fires when a medication alarm goes off.
///
/// This is the main entry point for medication reminders. It:
/// 1. Opens its own Drift connection (NO main isolate access)
/// 2. Gets the medication from the database
/// 3. If inactive, returns (no action)
/// 4. Creates a ReminderEvent row
/// 5. Shows the full-screen reminder (native ReminderActivity, which also
///    plays the caregiver's voice note once it is visible)
/// 7. Schedules ladder steps: Step 1 (15 min later), Step 2 (30 min later)
/// 8. Schedules next medication occurrence
/// 9. Closes database connection
///
/// Per AGENTS.md non-negotiable #6: Alarm callbacks run in a separate isolate
/// with no access to main isolate state.
///
/// Per APP-BUILD-SPEC.md §10: This is a top-level function with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> fireReminderCallback(int id, Map<String, dynamic> params) async {
  // Step 1: Initialize bindings for isolate
  WidgetsFlutterBinding.ensureInitialized();
  // DartPluginRegistrant is available on Android through flutter plugins
  // For Windows, we don't need it
  if (Platform.isAndroid) {
    // This will be resolved at runtime on Android
    try {
      DartPluginRegistrant.ensureInitialized();
    } catch (_) {
      // On platforms where it's not available, continue without it
    }
  }
  
  // Step 2: Open own Drift connection
  final db = await _openDatabaseConnection();
  if (db == null) return;
  
  try {
    final medicationId = params['medicationId'] as String?;
    final dayOfWeek = params['dayOfWeek'] as int?;
    
    if (medicationId == null || dayOfWeek == null) return;
    
    // Step 3: Get medication from database
    final contentRepo = ContentRepo(db);
    final med = await contentRepo.getMedication(medicationId);
    
    if (med == null || !med.active) {
      // Medication is inactive or doesn't exist - clean up and return
      await db.close();
      return;
    }

    // An alarm left over from before the caregiver changed the days must not
    // fire (or reschedule itself) on a day the medicine is no longer taken.
    if (!AlarmScheduler.parseDaysOfWeek(med.daysOfWeek).contains(dayOfWeek)) {
      await db.close();
      return;
    }

    final eventRepo = EventRepo(db);
    final now = DateTime.now();
    final alarmScheduler = AlarmScheduler(db: db, contentRepo: contentRepo);

    // A duplicate alarm for a reminder that just fired (within 2 minutes)
    // must not show it again. Snoozes fire 10 minutes later, so pass.
    final recentFire = await (db.select(db.reminderEvents)
          ..where((t) =>
              t.medicationId.equals(medicationId) &
              t.ladderStep.equals(0) &
              t.outcome.isNull() &
              t.firedAt.isBiggerOrEqualValue(
                  now.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch))
          ..limit(1))
        .getSingleOrNull();
    if (recentFire != null) {
      await alarmScheduler.scheduleNextOccurrence(med, dayOfWeek);
      await db.close();
      return;
    }

    // Step 4: Create ReminderEvent row
    final reminderEventId = const Uuid().v4();

    await eventRepo.insertReminderEvent(
      ReminderEventsCompanion.insert(
        id: reminderEventId,
        medicationId: medicationId,
        scheduledAt: now.millisecondsSinceEpoch,
        firedAt: Value(now.millisecondsSinceEpoch),
        channel: reminderChannelInApp,
        ladderStep: 0,
        synced: const Value(false),
      ),
    );
    
    // Step 5: Show the full-screen reminder
    await ReminderLauncher.showMedication(med, reminderEventId);

    // Step 7: Schedule ladder steps
    await _scheduleLadderStep(
      reminderEventId: reminderEventId,
      medicationId: medicationId,
      step: 1,
      delayMinutes: LadderConfig.step1DelayMinutes,
    );
    
    await _scheduleLadderStep(
      reminderEventId: reminderEventId,
      medicationId: medicationId,
      step: 2,
      delayMinutes: LadderConfig.step2DelayMinutes,
    );
    
    // Step 8: Schedule next medication occurrence
    await alarmScheduler.scheduleNextOccurrence(med, dayOfWeek);
    
    // Step 9: Close database connection
    await db.close();
    
  } catch (e) {
    // Ensure database is closed even on error
    try {
      await db.close();
    } catch (_) {}
    
    // Log error silently - elder should never see errors
    // In production, this would be written to a log file for diagnostics
  }
}

/// Opens a database connection for the isolate.
///
/// The isolate cannot access the main app's database connection, so it
/// must open its own.
Future<SmritiDatabase?> _openDatabaseConnection() async {
  try {
    final executor = await openConnectionForIsolate();
    return SmritiDatabase.connect(executor);
  } catch (_) {
    return null;
  }
}

/// Test alarm ID used by the setup screen and diagnostics.
const int testReminderAlarmId = 9998;

/// Schedules a test reminder [delay] from now through the real alarm path,
/// so the caregiver can lock the phone (or open another app) and confirm the
/// full-screen reminder appears. Writes no ReminderEvent.
Future<void> scheduleTestReminder({
  Duration delay = const Duration(seconds: 15),
}) async {
  await AndroidAlarmManager.oneShotAt(
    DateTime.now().add(delay),
    testReminderAlarmId,
    fireTestReminderCallback,
    exact: true,
    wakeup: true,
    allowWhileIdle: true,
    alarmClock: true,
    params: const {},
  );
}

@pragma('vm:entry-point')
Future<void> fireTestReminderCallback(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();
  final testEventId = '${ReminderRequest.testEventPrefix}${const Uuid().v4()}';

  Medication? med;
  final db = await _openDatabaseConnection();
  if (db != null) {
    try {
      final meds = await ContentRepo(db).getMedications(activeOnly: true);
      med = meds.isNotEmpty ? meds.first : null;
    } catch (_) {
    } finally {
      await db.close();
    }
  }

  if (med != null) {
    await ReminderLauncher.showMedication(med, testEventId);
  } else {
    await ReminderLauncher.show(
      medicationId: 'test',
      reminderEventId: testEventId,
      title: 'Test reminder',
      body: 'This is how medicine reminders will look',
    );
  }
}

/// Schedules a ladder step for later execution.
///
/// Ladder steps:
/// - Step 0: Immediate (handled by fireReminderCallback itself)
/// - Step 1: 15 minutes later - repeat notification
/// - Step 2: 30 minutes later - escalation (phone call)
Future<void> _scheduleLadderStep({
  required String reminderEventId,
  required String medicationId,
  required int step,
  required int delayMinutes,
}) async {
  try {
    final alarmTime = DateTime.now().add(Duration(minutes: delayMinutes));
    final alarmId = _ladderAlarmId(reminderEventId, step);
    
    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarmId,
      _fireLadderCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      alarmClock: true,
      rescheduleOnReboot: true,
      params: {
        'reminderEventId': reminderEventId,
        'medicationId': medicationId,
        'step': step,
      },
    );
    
  } catch (_) {
    // Ladder step scheduling failed
  }
}

/// Generates a deterministic alarm ID for ladder steps.
int _ladderAlarmId(String reminderEventId, int step) {
  return (reminderEventId.hashCode & 0x00FFFFFF) * 10 + step;
}

/// The callback for ladder steps (Step 1 and Step 2).
///
/// This is a separate callback from the main reminder because ladder steps
/// have different timing and behavior.
@pragma('vm:entry-point')
Future<void> _fireLadderCallback(int id, Map<String, dynamic> params) async {
  // Initialize bindings
  WidgetsFlutterBinding.ensureInitialized();
  // DartPluginRegistrant is available on Android through flutter plugins
  // For Windows, we don't need it
  if (defaultTargetPlatform == TargetPlatform.android) {
    // This will be resolved at runtime on Android
    try {
      DartPluginRegistrant.ensureInitialized();
    } catch (_) {
      // On platforms where it's not available, continue without it
    }
  }
  
  final db = await _openDatabaseConnection();
  if (db == null) return;
  
  try {
    final reminderEventId = params['reminderEventId'] as String?;
    final medicationId = params['medicationId'] as String?;
    final step = params['step'] as int?;
    
    if (reminderEventId == null || medicationId == null || step == null) {
      await db.close();
      return;
    }
    
    final eventRepo = EventRepo(db);
    final contentRepo = ContentRepo(db);
    
    // Get the original reminder event
    final originalEvent = await eventRepo.getReminderEvent(reminderEventId);
    if (originalEvent == null) {
      await db.close();
      return;
    }
    
    // Get the medication
    final med = await contentRepo.getMedication(medicationId);
    if (med == null || !med.active) {
      await db.close();
      return;
    }
    
    // Create ladder step event
    final now = DateTime.now();
    await eventRepo.insertReminderEvent(
      ReminderEventsCompanion.insert(
        id: const Uuid().v4(),
        medicationId: medicationId,
        scheduledAt: originalEvent.scheduledAt,
        firedAt: Value(now.millisecondsSinceEpoch),
        channel: step == 1 ? reminderChannelInApp : 'escalation',
        ladderStep: step,
        synced: const Value(false),
      ),
    );
    
    // Handle step-specific actions
    switch (step) {
      case 1:
        // Step 1: Show the reminder again (same event, so the same
        // notification is re-alerted and an open screen replays the voice)
        await ReminderLauncher.showMedication(med, reminderEventId);
        break;
      
      case 2:
        // Step 2: Escalation - write to EscalationRequests table
        // The server-side escalation-worker will handle the phone call
        await _writeEscalationRequest(db, reminderEventId, medicationId, step);
        break;
    }
    
    await db.close();
    
  } catch (e) {
    try {
      await db.close();
    } catch (_) {}
  }
}

/// Writes an escalation request to the database.
///
/// The server-side escalation-worker Edge Function will detect this and
/// place a real phone call to the caregiver.
Future<void> _writeEscalationRequest(
  SmritiDatabase db,
  String reminderEventId,
  String medicationId,
  int step,
) async {
  try {
    final eventRepo = EventRepo(db);
    final now = DateTime.now();
    
    // Escalation ID is deterministic per AGENTS.md #3
    final escalationId = '${reminderEventId}_$step';
    
    await eventRepo.insertEscalation(
      EscalationRequestsCompanion.insert(
        id: escalationId,
        reminderEventId: reminderEventId,
        medicationId: medicationId,
        step: step,
        requestedAt: now.millisecondsSinceEpoch,
        cancelled: Value(false),
        synced: Value(false),
      ),
    );
    
  } catch (_) {
    // Escalation write failed
  }
}
