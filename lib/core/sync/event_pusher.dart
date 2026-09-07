import '../db/dao/app_configs_dao.dart';
import '../repo/event_repo.dart';
import 'remote_rows.dart';
import 'sync_gateway.dart';

/// Ships locally-committed sessions, trials and reminder events upstream.
///
/// Everything here is fire-and-forget: rows are upserted with
/// `ignoreDuplicates`, never read back (AGENTS.md #4), and only marked synced
/// once the write returned without throwing. A push that dies mid-batch simply
/// re-sends those rows next time — the deterministic ids make that harmless.
class EventPusher {
  EventPusher({
    required this.eventRepo,
    required this.configs,
    this.gateway = const SupabaseSyncGateway(),
    this.batchSize = 200,
  });

  final EventRepo eventRepo;
  final AppConfigsDao configs;
  final SyncGateway gateway;
  final int batchSize;

  static const String patientIdKey = 'patientId';

  /// Pushes in dependency order: sessions before the trials that reference
  /// them, so a foreign key on the server never sees an orphan.
  Future<int> push() async {
    final patientId = await configs.getValue(patientIdKey);
    if (patientId == null || patientId.isEmpty) return 0;

    var pushed = 0;
    pushed += await _pushSessions(patientId);
    pushed += await _pushTrials(patientId);
    pushed += await _pushReminderEvents(patientId);
    return pushed;
  }

  Future<int> _pushSessions(String patientId) async {
    final rows = await eventRepo.unsyncedSessions(limit: batchSize);
    if (rows.isEmpty) return 0;

    await gateway.upsert(
      RemoteRows.sessionsTable,
      [for (final row in rows) RemoteRows.session(row, patientId)],
    );
    await eventRepo.markSessionsSynced([for (final row in rows) row.id]);
    return rows.length;
  }

  Future<int> _pushTrials(String patientId) async {
    final rows = await eventRepo.unsyncedTrials(limit: batchSize);
    if (rows.isEmpty) return 0;

    await gateway.upsert(
      RemoteRows.eventsTable,
      [for (final row in rows) RemoteRows.trial(row, patientId)],
    );
    await eventRepo.markTrialsSynced([for (final row in rows) row.id]);
    return rows.length;
  }

  Future<int> _pushReminderEvents(String patientId) async {
    final rows = await eventRepo.unsyncedReminderEvents(limit: batchSize);
    if (rows.isEmpty) return 0;

    await gateway.upsert(
      RemoteRows.reminderEventsTable,
      [for (final row in rows) RemoteRows.reminderEvent(row, patientId)],
    );
    await eventRepo.markReminderEventsSynced([for (final row in rows) row.id]);
    return rows.length;
  }
}
