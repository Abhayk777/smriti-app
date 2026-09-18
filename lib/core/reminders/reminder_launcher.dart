import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../i18n/app_strings.dart';

/// Hands a fired reminder to the native `ReminderReceiver`, which posts the
/// notification and opens the full-screen `ReminderActivity`.
///
/// Called from the alarm isolate. That isolate runs in its own FlutterEngine
/// with no access to MainActivity's MethodChannel, but android_intent_plus is
/// registered in every engine, so an explicit broadcast gets through.
/// Extra keys must match `Reminder.kt`.
class ReminderLauncher {
  static const String _package = 'com.example.smriti';
  static const String _receiver = 'com.example.smriti.ReminderReceiver';
  static const String _action = 'com.example.smriti.action.SHOW_REMINDER';

  static Future<void> show({
    required String medicationId,
    required String reminderEventId,
    required String title,
    required String body,
    String? photoPath,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await AndroidIntent(
        action: _action,
        package: _package,
        componentName: _receiver,
        arguments: {
          'medicationId': medicationId,
          'reminderEventId': reminderEventId,
          'title': title,
          'body': body,
          if (photoPath != null && photoPath.isNotEmpty) 'photoPath': photoPath,
        },
      ).sendBroadcast();
    } catch (e) {
      debugPrint('[ReminderLauncher] Could not send reminder broadcast: $e');
    }
  }

  static Future<void> showMedication(
    Medication med,
    String reminderEventId, [
    String lang = 'en',
  ]) {
    return show(
      medicationId: med.id,
      reminderEventId: reminderEventId,
      title: AppStrings.timeForMedication(lang, med.name),
      body: med.dose,
      photoPath: med.pillPhotoPath,
    );
  }
}
