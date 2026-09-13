import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'native_reminder_bridge.dart';

/// Everything that has to be switched on for a reminder to take over the
/// screen in every state (locked, home screen, inside another app).
enum ReminderSetupItem {
  /// POST_NOTIFICATIONS (Android 13+). Without it nothing shows at all.
  notifications,

  /// "Display over other apps" (SYSTEM_ALERT_WINDOW). Lets the app open the
  /// reminder itself while the phone is unlocked; a full-screen intent alone
  /// only produces a heads-up banner there.
  overlay,

  /// USE_FULL_SCREEN_INTENT (user-controlled on Android 14+). Covers the
  /// locked / screen-off case even without [overlay].
  fullScreen,

  /// Exact alarms (Android 12+), so reminders fire on the minute.
  exactAlarm,

  /// Battery optimisation exemption, so the OS doesn't defer the alarm.
  battery,
}

/// Android skins that may add their own lock-screen / pop-up / background
/// toggles on top of stock Android, which no API can read or grant. The
/// reminder itself only uses standard Android APIs; this just picks the most
/// helpful setup instructions. [other] covers every remaining manufacturer.
enum OemVendor { xiaomi, vivo, oppo, samsung, other }

class ReminderPermissions {
  static Future<Map<ReminderSetupItem, bool>> check() async {
    if (!Platform.isAndroid) {
      return {for (final item in ReminderSetupItem.values) item: true};
    }
    return {
      ReminderSetupItem.notifications: await Permission.notification.isGranted,
      ReminderSetupItem.overlay: await Permission.systemAlertWindow.isGranted,
      ReminderSetupItem.fullScreen:
          await NativeReminderBridge.canUseFullScreenIntent(),
      ReminderSetupItem.exactAlarm:
          await NativeReminderBridge.canScheduleExactAlarms(),
      ReminderSetupItem.battery:
          await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }

  static Future<bool> allGranted() async =>
      (await check()).values.every((granted) => granted);

  /// Opens the system prompt or settings page for [item].
  static Future<void> request(ReminderSetupItem item) async {
    switch (item) {
      case ReminderSetupItem.notifications:
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) await openAppSettings();
      case ReminderSetupItem.overlay:
        await Permission.systemAlertWindow.request();
      case ReminderSetupItem.fullScreen:
        await NativeReminderBridge.openFullScreenIntentSettings();
      case ReminderSetupItem.exactAlarm:
        await NativeReminderBridge.openExactAlarmSettings();
      case ReminderSetupItem.battery:
        await Permission.ignoreBatteryOptimizations.request();
    }
  }

  /// Returns null only for stock Android (Google Pixel), which has no extra
  /// toggles beyond the standard permissions above.
  static Future<OemVendor?> oemVendor() async {
    if (!Platform.isAndroid) return null;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final maker = '${info.manufacturer} ${info.brand}'.toLowerCase();
      if (maker.contains('google')) return null;
      if (maker.contains('xiaomi') ||
          maker.contains('redmi') ||
          maker.contains('poco')) {
        return OemVendor.xiaomi;
      }
      if (maker.contains('vivo') || maker.contains('iqoo')) {
        return OemVendor.vivo;
      }
      if (maker.contains('oppo') ||
          maker.contains('realme') ||
          maker.contains('oneplus')) {
        return OemVendor.oppo;
      }
      if (maker.contains('samsung')) return OemVendor.samsung;
    } catch (_) {}
    return OemVendor.other;
  }
}
