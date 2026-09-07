import '../db/dao/app_configs_dao.dart';
import '../repo/event_repo.dart';
import 'sync_gateway.dart';

/// Tells the server this device is alive, and records the clock skew it
/// reports back.
///
/// The server-side watchdog is already live: it independently detects a device
/// gone quiet or a dose never reported and triggers the same real phone-call
/// escalation. Nothing here implements that — the only job is to fire often
/// enough that `device_last_seen_at` stays accurate (APP-BUILD-SPEC.md §9).
class Heartbeat {
  Heartbeat({
    required this.eventRepo,
    required this.configs,
    this.gateway = const SupabaseSyncGateway(),
    this.appVersion = '1.0.0',
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final EventRepo eventRepo;
  final AppConfigsDao configs;
  final SyncGateway gateway;

  /// Injected rather than read from `package_info_plus`, which is not a
  /// dependency yet.
  final String appVersion;

  final DateTime Function() _now;

  static const String patientIdKey = 'patientId';
  static const String clockSkewKey = 'clockSkewMs';
  static const String lastSyncAtKey = 'lastSyncAt';

  Future<void> send() async {
    final patientId = await configs.getValue(patientIdKey);
    if (patientId == null || patientId.isEmpty) return;

    final deviceTimeMs = _now().millisecondsSinceEpoch;

    final response = await gateway.rpc('device_heartbeat', {
      'p_patient_id': patientId,
      'p_app_version': appVersion,
      'p_pending_events': await eventRepo.unsyncedCount(),
      'p_device_time_ms': deviceTimeMs,
    });

    final updates = <String, String>{lastSyncAtKey: '$deviceTimeMs'};

    // The server is the authority on time; a large skew is what makes a missed
    // dose look like a device problem rather than a patient one.
    final skew = response?['clock_skew_ms'];
    if (skew != null) updates[clockSkewKey] = '$skew';

    await configs.setAll(updates);
  }
}
