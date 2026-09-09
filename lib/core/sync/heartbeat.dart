import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database.dart';
import '../repo/event_repo.dart';

/// Result of a heartbeat operation.
class HeartbeatResult {
  const HeartbeatResult({
    required this.serverTimeMs,
    required this.clockSkewMs,
    this.error,
  });

  final int serverTimeMs;
  final int clockSkewMs;
  final String? error;

  bool get success => error == null;
}

/// Sends device heartbeat to Supabase to keep the server aware of device status.
///
/// The server watchdog uses this to detect devices that have gone quiet and
/// triggers phone call escalations if doses are missed.
/// Only this class may import supabase_flutter outside core/auth (AGENTS.md #1).
class Heartbeat {
  Heartbeat({
    required this.db,
    required this.eventRepo,
    String? patientId,
    String? appVersion,
  })  : _patientId = patientId,
        _appVersion = appVersion;

  final SmritiDatabase db;
  final EventRepo eventRepo;
  String? _patientId;
  String? _appVersion;

  /// Patient ID from AppConfigs
  Future<String> _getPatientId() async {
    return _patientId ??= 
        await db.appConfigsDao.getValue('patientId') ?? 
        (throw Exception('No patientId configured'));
  }

  /// App version - cached after first call
  Future<String> _getAppVersion() async {
    if (_appVersion != null) return _appVersion!;
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      return _appVersion!;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Sends heartbeat to Supabase.
  ///
  /// Calls the `device_heartbeat` RPC with patient_id, app_version, pending_events count,
  /// and device time. Returns server time and clock skew.
  Future<HeartbeatResult> send() async {
    try {
      final pid = await _getPatientId();
      final version = await _getAppVersion();
      final pendingEvents = await eventRepo.unsyncedCount();
      final deviceTimeMs = DateTime.now().millisecondsSinceEpoch;
      
      final response = await Supabase.instance.client.rpc(
        'device_heartbeat',
        params: {
          'p_patient_id': pid,
          'p_app_version': version,
          'p_pending_events': pendingEvents,
          'p_device_time_ms': deviceTimeMs,
        },
      );
      
      final Map<String, dynamic>? data = response is Map
          ? Map<String, dynamic>.from(response)
          : null;
      
      if (data != null && data.containsKey('server_time_ms')) {
        final serverTimeMs = (data['server_time_ms'] as num).toInt();
        final clockSkewMs = (data['clock_skew_ms'] as num?)?.toInt() ?? 0;
        
        // Store clock skew for timestamp adjustments
        if (clockSkewMs != 0) {
          await db.appConfigsDao.setValue('clockSkewMs', clockSkewMs.toString());
        }
        
        return HeartbeatResult(
          serverTimeMs: serverTimeMs,
          clockSkewMs: clockSkewMs,
        );
      }
      
      return HeartbeatResult(
        serverTimeMs: DateTime.now().millisecondsSinceEpoch,
        clockSkewMs: 0,
        error: 'Invalid response format: $response',
      );
      
    } catch (e) {
      return HeartbeatResult(
        serverTimeMs: DateTime.now().millisecondsSinceEpoch,
        clockSkewMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Returns the current clock skew from AppConfigs.
  Future<int> getClockSkew() async {
    final skewStr = await db.appConfigsDao.getValue('clockSkewMs');
    if (skewStr != null) {
      return int.tryParse(skewStr) ?? 0;
    }
    return 0;
  }
}
