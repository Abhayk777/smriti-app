import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../db/dao/app_configs_dao.dart';
import 'alarm_scheduler.dart';

/// One thing the setup check needs from the OS.
enum CheckOutcome { granted, denied, unavailable }

/// What the caregiver is told at the end of setup.
class HealthCheckReport {
  const HealthCheckReport({
    required this.exactAlarm,
    required this.notifications,
    required this.batteryExemption,
    required this.microphone,
    required this.manufacturer,
    required this.autostartOpened,
    required this.testAlarmFired,
  });

  final CheckOutcome exactAlarm;
  final CheckOutcome notifications;
  final CheckOutcome batteryExemption;
  final CheckOutcome microphone;

  final String manufacturer;

  /// Whether the OEM's autostart screen was actually opened. False on a device
  /// with no known autostart manager, which is fine.
  final bool autostartOpened;

  /// The live proof. Null until the test alarm has been scheduled and
  /// confirmed.
  final bool? testAlarmFired;

  /// Whether this device is trusted to deliver a dose reminder.
  ///
  /// Permissions alone are never enough: OEM battery managers kill background
  /// work regardless of what was granted, so the live test alarm is the only
  /// real evidence (APP-BUILD-SPEC.md §10).
  bool get isReady =>
      exactAlarm == CheckOutcome.granted &&
      notifications == CheckOutcome.granted &&
      testAlarmFired == true;

  /// What still needs fixing, for the caregiver-facing summary.
  List<String> get problems => [
        if (exactAlarm != CheckOutcome.granted) 'Exact alarms not permitted',
        if (notifications != CheckOutcome.granted) 'Notifications not permitted',
        if (batteryExemption != CheckOutcome.granted)
          'Battery optimisation still on',
        if (microphone != CheckOutcome.granted) 'Microphone not permitted',
        if (testAlarmFired == null) 'Test alarm not confirmed yet',
        if (testAlarmFired == false) 'Test alarm did not fire',
      ];
}

/// Permission requests, behind a seam so the check can be tested.
abstract class PermissionGateway {
  Future<CheckOutcome> requestExactAlarm();

  Future<CheckOutcome> requestNotifications();

  Future<CheckOutcome> requestBatteryExemption();

  Future<CheckOutcome> requestMicrophone();
}

class DevicePermissionGateway implements PermissionGateway {
  const DevicePermissionGateway();

  @override
  Future<CheckOutcome> requestExactAlarm() =>
      _request(Permission.scheduleExactAlarm);

  @override
  Future<CheckOutcome> requestNotifications() =>
      _request(Permission.notification);

  @override
  Future<CheckOutcome> requestBatteryExemption() =>
      _request(Permission.ignoreBatteryOptimizations);

  @override
  Future<CheckOutcome> requestMicrophone() => _request(Permission.microphone);

  static Future<CheckOutcome> _request(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted ? CheckOutcome.granted : CheckOutcome.denied;
    } catch (_) {
      // Not every permission exists on every API level.
      return CheckOutcome.unavailable;
    }
  }
}

/// Opens the manufacturer's autostart / background-restriction screen.
abstract class OemGateway {
  Future<String> manufacturer();

  /// Returns true if some autostart screen was opened.
  Future<bool> openAutostartSettings(String manufacturer);
}

class AndroidOemGateway implements OemGateway {
  const AndroidOemGateway();

  /// Component names vary by ROM and version, and a wrong one throws. Each is
  /// tried in turn and failures are swallowed — this is best-effort guidance,
  /// never something that can break setup.
  static const Map<String, List<List<String>>> autostartComponents = {
    'xiaomi': [
      ['com.miui.securitycenter',
          'com.miui.permcenter.autostart.AutoStartManagementActivity'],
    ],
    'redmi': [
      ['com.miui.securitycenter',
          'com.miui.permcenter.autostart.AutoStartManagementActivity'],
    ],
    'poco': [
      ['com.miui.securitycenter',
          'com.miui.permcenter.autostart.AutoStartManagementActivity'],
    ],
    'oppo': [
      ['com.coloros.safecenter',
          'com.coloros.safecenter.permission.startup.StartupAppListActivity'],
      ['com.coloros.safecenter',
          'com.coloros.safecenter.startupapp.StartupAppListActivity'],
      ['com.oppo.safe', 'com.oppo.safe.permission.startup.StartupAppListActivity'],
    ],
    'realme': [
      ['com.coloros.safecenter',
          'com.coloros.safecenter.permission.startup.StartupAppListActivity'],
    ],
    'vivo': [
      ['com.vivo.permissionmanager',
          'com.vivo.permissionmanager.activity.BgStartUpManagerActivity'],
      ['com.iqoo.secure',
          'com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity'],
    ],
    'huawei': [
      ['com.huawei.systemmanager',
          'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity'],
      ['com.huawei.systemmanager',
          'com.huawei.systemmanager.optimize.process.ProtectActivity'],
    ],
    'honor': [
      ['com.huawei.systemmanager',
          'com.huawei.systemmanager.optimize.process.ProtectActivity'],
    ],
    'samsung': [
      ['com.samsung.android.lool',
          'com.samsung.android.sm.ui.battery.BatteryActivity'],
      ['com.samsung.android.sm',
          'com.samsung.android.sm.ui.battery.BatteryActivity'],
    ],
  };

  @override
  Future<String> manufacturer() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.manufacturer.toLowerCase();
    } catch (_) {
      return 'unknown';
    }
  }

  @override
  Future<bool> openAutostartSettings(String manufacturer) async {
    final candidates = autostartComponents[manufacturer.toLowerCase()];
    if (candidates == null) return false;

    for (final component in candidates) {
      try {
        await AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: component[0],
          componentName: component[1],
        ).launch();
        return true;
      } catch (_) {
        // Wrong component for this ROM; try the next.
        continue;
      }
    }
    return false;
  }
}

/// Setup health check (task A12, APP-BUILD-SPEC.md §10).
///
/// Requests what the reminders need, points the caregiver at the OEM's
/// autostart screen, then schedules a **real** alarm 60 seconds out. Nothing is
/// reported as ready until that alarm has actually fired: granted permissions
/// do not mean alarms fire.
class SetupHealthCheck {
  SetupHealthCheck({
    required this.configs,
    required this.scheduler,
    this.permissions = const DevicePermissionGateway(),
    this.oem = const AndroidOemGateway(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppConfigsDao configs;
  final AlarmScheduler scheduler;
  final PermissionGateway permissions;
  final OemGateway oem;
  final DateTime Function() _now;

  /// Written by the test alarm's own isolate; read back here.
  static const String testAlarmFiredKey = 'healthCheckTestAlarmFiredAt';
  static const String testAlarmScheduledKey =
      'healthCheckTestAlarmScheduledAt';

  static const Duration testAlarmDelay = Duration(seconds: 60);

  /// Requests permissions and offers the OEM autostart screen.
  Future<HealthCheckReport> run({bool openAutostart = true}) async {
    final exactAlarm = await permissions.requestExactAlarm();
    final notifications = await permissions.requestNotifications();
    final battery = await permissions.requestBatteryExemption();
    final microphone = await permissions.requestMicrophone();

    final manufacturer = await oem.manufacturer();
    var autostartOpened = false;
    if (openAutostart) {
      try {
        autostartOpened = await oem.openAutostartSettings(manufacturer);
      } catch (_) {
        autostartOpened = false;
      }
    }

    return HealthCheckReport(
      exactAlarm: exactAlarm,
      notifications: notifications,
      batteryExemption: battery,
      microphone: microphone,
      manufacturer: manufacturer,
      autostartOpened: autostartOpened,
      testAlarmFired: await testAlarmFired(),
    );
  }

  /// Arms a real alarm 60 seconds from now.
  ///
  /// Deliberately goes through the same AndroidAlarmManager path as a dose, so
  /// what is being tested is the mechanism that matters.
  Future<void> scheduleTestAlarm() async {
    final scheduledAt = _now();
    await configs.setAll({
      testAlarmScheduledKey: '${scheduledAt.millisecondsSinceEpoch}',
    });
    // Clear any previous result, so a stale success cannot be mistaken for a
    // fresh one.
    await configs.deleteValue(testAlarmFiredKey);

    await scheduler.scheduleTestAlarm(
      fireAt: scheduledAt.add(testAlarmDelay),
    );
  }

  /// Whether the test alarm has fired since it was last scheduled.
  Future<bool?> testAlarmFired() async {
    final scheduled = await configs.getValue(testAlarmScheduledKey);
    if (scheduled == null) return null;

    final fired = await configs.getValue(testAlarmFiredKey);
    if (fired == null) return null;

    final scheduledMs = int.tryParse(scheduled);
    final firedMs = int.tryParse(fired);
    if (scheduledMs == null || firedMs == null) return null;

    // Must have fired after it was armed, or it is a leftover from last time.
    return firedMs >= scheduledMs;
  }

  /// True once the test alarm is overdue and still has not fired — the signal
  /// that an OEM battery manager is killing background work.
  Future<bool> testAlarmOverdue() async {
    final scheduled = await configs.getValue(testAlarmScheduledKey);
    final scheduledMs = int.tryParse(scheduled ?? '');
    if (scheduledMs == null) return false;
    if (await testAlarmFired() == true) return false;

    final due = DateTime.fromMillisecondsSinceEpoch(scheduledMs)
        .add(testAlarmDelay)
        .add(const Duration(seconds: 30));
    return _now().isAfter(due);
  }
}
