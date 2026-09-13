import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to MainActivity's platform channel for reminder-related settings:
/// - Android 14+ (API 34) Full Screen Intent permission check and settings intent
/// - Android 12+ (API 31) Exact Alarm permission check and settings intent
/// - Manufacturer-specific permission pages (Xiaomi, Vivo, Oppo)
///
/// Only available in the main app engine. The alarm isolate uses
/// `ReminderLauncher`; the reminder screen uses `ReminderScreenChannel`.
class NativeReminderBridge {
  static const MethodChannel _channel =
      MethodChannel('com.example.smriti/native_reminders');

  /// Registers what to run when the reminder screen (a separate engine)
  /// asks this engine to sync after the elder responds.
  static void onSyncRequested(Future<void> Function() sync) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'syncNow') await sync();
    });
  }

  /// Checks if the app has permission to use Full Screen Intents.
  ///
  /// On Android 14+ (API 34), `USE_FULL_SCREEN_INTENT` may be revoked by default
  /// unless granted or declared for an Alarm/Calling app.
  /// On Android 10-13, this is granted automatically and returns true.
  static Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? true;
    } catch (e) {
      debugPrint('[NativeReminderBridge] Error checking FSI permission: $e');
      return true;
    }
  }

  /// Opens the Android system settings screen where the user or caregiver
  /// can toggle "Allow full-screen intent notifications" for this app.
  static Future<bool> openFullScreenIntentSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('openFullScreenIntentSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('[NativeReminderBridge] Error opening FSI settings: $e');
      return false;
    }
  }

  /// Checks if the app can schedule exact alarms.
  ///
  /// On Android 12+ (API 31), exact alarms require permission.
  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return result ?? true;
    } catch (e) {
      debugPrint(
          '[NativeReminderBridge] Error checking exact alarm permission: $e');
      return true;
    }
  }

  /// Opens the Android system settings screen for "Alarms & Reminders" permission.
  static Future<bool> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('openExactAlarmSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('[NativeReminderBridge] Error opening exact alarm settings: $e');
      return false;
    }
  }

  /// Opens the manufacturer's extra permission page (Xiaomi "Other
  /// permissions", Vivo/Oppo equivalents), falling back to app details.
  static Future<bool> openOemPermissionSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('openOemPermissionSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('[NativeReminderBridge] Error opening OEM settings: $e');
      return false;
    }
  }
}
