import '../db/dao/app_configs_dao.dart';
import '../repo/event_repo.dart';
import 'remote_rows.dart';
import 'sync_gateway.dart';

/// Flushes pending escalation requests to the `escalations` table.
///
/// This is the device's entire role in the ladder's step 2: a fire-and-forget
/// write. The server's escalation worker picks the row up and places the real
/// phone call — that side is already live and tested, and nothing here waits
/// on it or reads it back.
///
/// Ids are deterministic (`{reminderEventId}_{step}`, AGENTS.md #2), so a retry
/// after a crash or a lost response can never place a second call.
class EscalationWriter {
  EscalationWriter({
    required this.eventRepo,
    required this.configs,
    this.gateway = const SupabaseSyncGateway(),
    this.batchSize = 100,
  });

  final EventRepo eventRepo;
  final AppConfigsDao configs;
  final SyncGateway gateway;
  final int batchSize;

  static const String patientIdKey = 'patientId';

  Future<int> flush() async {
    final patientId = await configs.getValue(patientIdKey);
    if (patientId == null || patientId.isEmpty) return 0;

    final rows = await eventRepo.unsyncedEscalations(limit: batchSize);
    if (rows.isEmpty) return 0;

    // A cancelled escalation must never reach the server — the elder already
    // took the dose.
    final pending = rows.where((row) => !row.cancelled).toList();

    if (pending.isNotEmpty) {
      await gateway.upsert(
        RemoteRows.escalationsTable,
        [for (final row in pending) RemoteRows.escalation(row, patientId)],
      );
    }

    // Cancelled rows are marked synced too: there is nothing left to send.
    await eventRepo.markEscalationsSynced([for (final row in rows) row.id]);
    return pending.length;
  }
}
