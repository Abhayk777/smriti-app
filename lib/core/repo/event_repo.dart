import 'package:drift/drift.dart';

import '../db/database.dart';

/// Append-only store for everything the sync layer later pushes upstream:
/// trials, sessions, reminder events and escalation requests.
///
/// AGENTS.md non-negotiable #3: these tables are INSERT-only in application
/// code. The only permitted updates are flipping `synced`, and closing a
/// still-open session via [endSession] / [bumpDemoReplays]. Nothing here ever
/// mutates a finalized row, and nothing here touches Supabase.
class EventRepo {
  EventRepo(this.db);

  final SmritiDatabase db;

  // SESSIONS

  Future<void> insertSession(SessionsCompanion session) async {
    await db.into(db.sessions).insert(session);
  }

  Future<Session?> getSession(String id) {
    return (db.select(db.sessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Closes an open session. Refuses to touch one that already ended, so a
  /// finalized row can never be rewritten.
  Future<void> endSession({
    required String id,
    required int endedAt,
    required bool completed,
    int? abandonedAtMs,
  }) async {
    await (db.update(db.sessions)
          ..where((t) => t.id.equals(id) & t.endedAt.isNull()))
        .write(
      SessionsCompanion(
        endedAt: Value(endedAt),
        completed: Value(completed),
        abandonedAtMs: Value(abandonedAtMs),
      ),
    );
  }

  /// Increments the ghost-hand demo replay count on an open session.
  Future<void> bumpDemoReplays(String id) async {
    await db.customUpdate(
      'UPDATE sessions SET demo_replays = demo_replays + 1 '
      'WHERE id = ? AND ended_at IS NULL',
      variables: [Variable<String>(id)],
      updates: {db.sessions},
    );
  }

  // TRIAL EVENTS

  Future<void> insertTrial(TrialEventsCompanion trial) async {
    await db.into(db.trialEvents).insert(trial);
  }

  Future<void> insertTrials(List<TrialEventsCompanion> trials) async {
    await db.batch((batch) => batch.insertAll(db.trialEvents, trials));
  }

  Future<List<TrialEvent>> getTrialsForSession(String sessionId) {
    return (db.select(db.trialEvents)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm(expression: t.trialIndex)]))
        .get();
  }

  // REMINDER EVENTS

  Future<void> insertReminderEvent(ReminderEventsCompanion event) async {
    await db.into(db.reminderEvents).insert(event);
  }

  Future<ReminderEvent?> getReminderEvent(String id) {
    return (db.select(db.reminderEvents)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ESCALATION REQUESTS

  /// Escalation IDs are deterministic (`{reminderEventId}_{step}`), so a retry
  /// after a crash must not fail or duplicate — hence insert-or-ignore.
  Future<void> insertEscalation(EscalationRequestsCompanion request) async {
    await db
        .into(db.escalationRequests)
        .insert(request, mode: InsertMode.insertOrIgnore);
  }

  Future<EscalationRequest?> getEscalation(String id) {
    return (db.select(db.escalationRequests)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // UNSYNCED READS — used by the sync layer to build push batches

  Future<int> unsyncedCount() async {
    // Count all unsynced items across all sync tables
    final sessionsCount = await (db.select(db.sessions)
          ..where((t) => t.synced.equals(false)))
        .get()
        .then((list) => list.length);
    
    final trialsCount = await (db.select(db.trialEvents)
          ..where((t) => t.synced.equals(false)))
        .get()
        .then((list) => list.length);
    
    final reminderEventsCount = await (db.select(db.reminderEvents)
          ..where((t) => t.synced.equals(false)))
        .get()
        .then((list) => list.length);
    
    final escalationsCount = await (db.select(db.escalationRequests)
          ..where((t) => t.synced.equals(false)))
        .get()
        .then((list) => list.length);
    
    return sessionsCount + trialsCount + reminderEventsCount + escalationsCount;
  }

  Future<List<Session>> unsyncedSessions({int limit = 200}) {
    return (db.select(db.sessions)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.startedAt)])
          ..limit(limit))
        .get();
  }

  Future<List<TrialEvent>> unsyncedTrials({int limit = 500}) {
    return (db.select(db.trialEvents)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.ts)])
          ..limit(limit))
        .get();
  }

  Future<List<ReminderEvent>> unsyncedReminderEvents({int limit = 200}) {
    return (db.select(db.reminderEvents)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)])
          ..limit(limit))
        .get();
  }

  Future<List<EscalationRequest>> unsyncedEscalations({int limit = 200}) {
    return (db.select(db.escalationRequests)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.requestedAt)])
          ..limit(limit))
        .get();
  }

  // SYNC FLAGS — the only permitted update on these rows

  Future<void> markSessionsSynced(List<String> ids) =>
      _markSynced(db.sessions, ids);

  Future<void> markTrialsSynced(List<String> ids) =>
      _markSynced(db.trialEvents, ids);

  Future<void> markReminderEventsSynced(List<String> ids) =>
      _markSynced(db.reminderEvents, ids);

  Future<void> markEscalationsSynced(List<String> ids) =>
      _markSynced(db.escalationRequests, ids);

  Future<void> _markSynced(TableInfo table, List<String> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.customUpdate(
      'UPDATE ${table.actualTableName} SET synced = 1 '
      'WHERE id IN ($placeholders)',
      variables: [for (final id in ids) Variable<String>(id)],
      updates: {table},
    );
  }
}
