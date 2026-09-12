import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'native_reminder_bridge.dart';

/// Result of a health check operation.
class HealthCheckReport {
  const HealthCheckReport({
    required this.allPermissionsGranted,
    required this.grantedPermissions,
    required this.missingPermissions,
    required this.oemType,
    required this.autostartSettingsOpened,
    required this.testAlarmScheduled,
    required this.testAlarmVerified,
    this.error,
  });

  final bool allPermissionsGranted;
  final List<String> grantedPermissions;
  final List<String> missingPermissions;
  final String oemType;
  final bool autostartSettingsOpened;
  final bool testAlarmScheduled;
  final bool testAlarmVerified;
  final String? error;

  bool get passed => 
      allPermissionsGranted && 
      (oemType == 'unknown' || autostartSettingsOpened) &&
      testAlarmVerified;
}

/// Performs health check to verify OEM compatibility and required permissions.
///
/// Per APP-BUILD-SPEC.md §10 and §12: OEM battery optimization can break
/// background alarms. This health check detects the OEM, requests required
/// permissions, opens autostart settings if needed, and schedules a test alarm
/// to verify everything works.
class HealthCheck {
  /// Required permissions for the app to work correctly.
  static const List<String> requiredPermissions = [
    'android.permission.SCHEDULE_EXACT_ALARM',
    'android.permission.USE_EXACT_ALARM',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.WAKE_LOCK',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
    'android.permission.USE_FULL_SCREEN_INTENT',
    'android.permission.RECORD_AUDIO',
    'android.permission.READ_EXTERNAL_STORAGE',
  ];

  /// OEM-specific package names for autostart settings.
  static const Map<String, String> oemAutostartPackages = {
    'xiaomi': 'com.miui.securitycenter',
    'oppo': 'com.coloros.safecenter',
    'vivo': 'com.iqoo.secure',
    'huawei': 'com.huawei.systemmanager',
    'samsung': 'com.samsung.android.lool',
  };

  /// OEM-specific autostart intent actions.
  static const Map<String, String> oemAutostartActions = {
    'xiaomi': 'com.miui.securitycenter.autostartActivity',
    'oppo': 'com.coloros.safecenter.startupapp',
    'vivo': 'com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity',
    'huawei': 'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
    'samsung': 'com.samsung.android.lool.asset.action.STARTActivity',
  };

  /// Detects the device OEM (manufacturer).
  Future<String> _detectOem() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      
      for (final oem in oemAutostartPackages.keys) {
        if (manufacturer.contains(oem)) {
          return oem;
        }
      }
      
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Checks if all required permissions are granted.
  Future<Map<String, PermissionStatus>> _checkPermissions() async {
    final permissions = <String, PermissionStatus>{};
    
    // Check Android-specific capabilities via NativeReminderBridge
    final canFsi = await NativeReminderBridge.canUseFullScreenIntent();
    permissions['android.permission.USE_FULL_SCREEN_INTENT'] =
        canFsi ? PermissionStatus.granted : PermissionStatus.denied;

    final canExact = await NativeReminderBridge.canScheduleExactAlarms();
    permissions['android.permission.SCHEDULE_EXACT_ALARM'] =
        canExact ? PermissionStatus.granted : PermissionStatus.denied;
    permissions['android.permission.USE_EXACT_ALARM'] =
        canExact ? PermissionStatus.granted : PermissionStatus.denied;

    // Check standard permissions via permission_handler
    permissions['android.permission.POST_NOTIFICATIONS'] =
        await Permission.notification.status;
    permissions['android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'] =
        await Permission.ignoreBatteryOptimizations.status;
    permissions['android.permission.RECORD_AUDIO'] =
        await Permission.microphone.status;
    permissions['android.permission.READ_EXTERNAL_STORAGE'] =
        await Permission.storage.status;
    
    // System permissions that are granted on manifest declaration
    permissions['android.permission.RECEIVE_BOOT_COMPLETED'] =
        PermissionStatus.granted;
    permissions['android.permission.WAKE_LOCK'] =
        PermissionStatus.granted;
    
    return permissions;
  }

  /// Requests all missing permissions.
  Future<void> _requestPermissions(List<String> missing) async {
    if (missing.isEmpty) return;
    
    // Request standard permissions
    if (missing.contains('android.permission.POST_NOTIFICATIONS')) {
      await Permission.notification.request();
    }
    if (missing.contains('android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS')) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    if (missing.contains('android.permission.RECORD_AUDIO')) {
      await Permission.microphone.request();
    }
    if (missing.contains('android.permission.READ_EXTERNAL_STORAGE')) {
      await Permission.storage.request();
    }

    // Request Android 14+ FSI and Android 12+ Exact Alarm settings if needed
    if (missing.contains('android.permission.USE_FULL_SCREEN_INTENT')) {
      await NativeReminderBridge.openFullScreenIntentSettings();
    }
    if (missing.contains('android.permission.SCHEDULE_EXACT_ALARM')) {
      await NativeReminderBridge.openExactAlarmSettings();
    }
  }

  /// Opens autostart settings for the detected OEM.
  Future<bool> _openAutostartSettings(String oem) async {
    if (oem == 'unknown' || !oemAutostartPackages.containsKey(oem)) {
      return false;
    }
    
    try {
      final package = oemAutostartPackages[oem]!;
      final action = oemAutostartActions[oem]!;
      
      final intent = AndroidIntent(
        action: action,
        package: package,
      );
      
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Performs the complete health check.
  ///
  /// Steps:
  /// 1. Detect OEM
  /// 2. Check all required permissions
  /// 3. Request missing permissions
  /// 4. Open autostart settings for OEM-specific apps
  /// 5. Schedule a test alarm
  /// 6. Return comprehensive report
  Future<HealthCheckReport> run() async {
    try {
      // Step 1: Detect OEM
      final oem = await _detectOem();
      
      // Step 2: Check permissions
      final permissionStatuses = await _checkPermissions();
      
      final granted = <String>[];
      final missing = <String>[];
      
      for (final entry in permissionStatuses.entries) {
        if (entry.value.isGranted) {
          granted.add(entry.key);
        } else {
          missing.add(entry.key);
        }
      }
      
      // Step 3: Request missing permissions
      if (missing.isNotEmpty) {
        await _requestPermissions(missing);
        
        // Re-check after requesting
        final newStatuses = await _checkPermissions();
        granted.clear();
        missing.clear();
        
        for (final entry in newStatuses.entries) {
          if (entry.value.isGranted) {
            granted.add(entry.key);
          } else {
            missing.add(entry.key);
          }
        }
      }
      
      // Step 4: Open autostart settings for OEM
      bool autostartOpened = false;
      if (oem != 'unknown' && missing.isNotEmpty) {
        autostartOpened = await _openAutostartSettings(oem);
      }
      
      // Step 5: Schedule test alarm (handled by caller)
      // The caller will schedule a test alarm and verify it fires
      
      return HealthCheckReport(
        allPermissionsGranted: missing.isEmpty,
        grantedPermissions: granted,
        missingPermissions: missing,
        oemType: oem,
        autostartSettingsOpened: autostartOpened,
        testAlarmScheduled: false, // Set by caller
        testAlarmVerified: false, // Set by caller after test
      );
      
    } catch (e) {
      return HealthCheckReport(
        allPermissionsGranted: false,
        grantedPermissions: const [],
        missingPermissions: requiredPermissions.toList(),
        oemType: 'unknown',
        autostartSettingsOpened: false,
        testAlarmScheduled: false,
        testAlarmVerified: false,
        error: e.toString(),
      );
    }
  }

  /// Returns a human-readable list of missing permissions.
  Future<List<String>> getMissingPermissions() async {
    final statuses = await _checkPermissions();
    return statuses.entries
        .where((e) => !e.value.isGranted)
        .map((e) => e.key)
        .toList();
  }

  /// Returns whether all required permissions are granted.
  Future<bool> get allPermissionsGranted async {
    final statuses = await _checkPermissions();
    return statuses.values.every((s) => s.isGranted);
  }
}
