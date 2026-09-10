import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../db/database.dart';
import '../repo/content_repo.dart';
import '../repo/event_repo.dart';
import 'alarm_scheduler.dart';

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
/// 5. Shows full-screen notification
/// 6. Plays caregiver audio (med.voicePath)
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
    
    // Step 4: Create ReminderEvent row
    final eventRepo = EventRepo(db);
    final now = DateTime.now();
    final reminderEventId = const Uuid().v4();
    
    await eventRepo.insertReminderEvent(
      ReminderEventsCompanion.insert(
        id: reminderEventId,
        medicationId: medicationId,
        scheduledAt: now.millisecondsSinceEpoch,
        firedAt: Value(now.millisecondsSinceEpoch),
        channel: 'fullscreen',
        ladderStep: 0,
        synced: const Value(false),
      ),
    );
    
    // Step 5: Show full-screen notification
    await _showFullScreenNotification(reminderEventId, med);
    
    // Step 6: Play caregiver audio
    await _playCaregiverAudio(med.voicePath);
    
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
    final alarmScheduler = AlarmScheduler(db: db, contentRepo: contentRepo);
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

/// Shows a full-screen notification for the medication reminder.
Future<void> _showFullScreenNotification(String reminderEventId, Medication med) async {
  try {
    // Initialize notifications
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'medication_reminder',
      'Medication Reminder',
      channelDescription: 'Full-screen medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      showWhen: false,
      autoCancel: false,
      ongoing: true,
    );
    
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    
    // Show notification
    await flutterLocalNotificationsPlugin.show(
      reminderEventId.hashCode,
      'Time for: ${med.name}',
      med.dose,
      platformChannelSpecifics,
      payload: 'medication_reminder:$reminderEventId',
    );
    
    // Wake up the device
    await WakelockPlus.enable();
    
  } catch (_) {
    // Notification failed - may not be configured properly
  }
}

/// Plays the caregiver's voice recording for the medication.
Future<void> _playCaregiverAudio(String? voicePath) async {
  if (voicePath == null || voicePath.isEmpty) return;
  
  try {
    final file = File(voicePath);
    if (!await file.exists()) return;
    
    final player = AudioPlayer();
    await player.setFilePath(voicePath);
    await player.play();
    
    // Don't await - let it play in background
    // The player will be garbage collected when done
  } catch (_) {
    // Audio playback failed
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
        channel: step == 1 ? 'fullscreen' : 'escalation',
        ladderStep: step,
        synced: const Value(false),
      ),
    );
    
    // Handle step-specific actions
    switch (step) {
      case 1:
        // Step 1: Repeat notification, louder
        await _showFullScreenNotification(reminderEventId, med);
        await _playCaregiverAudio(med.voicePath);
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
