import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/event_repo.dart';

import '_test_db.dart';

void main() {
  late SmritiDatabase db;
  late EventRepo repo;

  setUp(() {
    db = newTestDb();
    repo = EventRepo(db);
  });

  tearDown(() async => db.close());

  TrialEventsCompanion trial(String id, int index) => TrialEventsCompanion.insert(
        id: id,
        sessionId: 's1',
        gameId: 'market_basket',
        domain: 'memory',
        itemId: 'item_$index',
        itemDifficulty: -0.266,
        thetaBefore: 1.0,
        correct: true,
        initiationMs: 900,
        movementMs: 1400,
        responseTimeMs: 2300,
        chosenId: const Value('item_wrong'),
        errorClass: const Value('semantic'),
        trialIndex: index,
        trialContext: const Value('{"basketSize":4}'),
        hintLevel: const Value(1),
        metrics: const Value('{"taps":2}'),
        ts: 1757200000000,
        hourOfDay: 9,
        tzOffsetMin: 330,
      );

  test('round-trips a fully-populated trial event', () async {
    await repo.insertSession(
      SessionsCompanion.insert(
        id: 's1',
        startedAt: 1757199000000,
        gameIds: 'market_basket',
      ),
    );
    await repo.insertTrial(trial('t1', 0));

    final rows = await repo.getTrialsForSession('s1');
    expect(rows, hasLength(1));

    final t = rows.single;
    expect(t.id, 't1');
    expect(t.sessionId, 's1');
    expect(t.gameId, 'market_basket');
    expect(t.domain, 'memory');
    expect(t.itemId, 'item_0');
    expect(t.itemDifficulty, closeTo(-0.266, 1e-9));
    expect(t.thetaBefore, 1.0);
    expect(t.correct, isTrue);
    expect(t.initiationMs, 900);
    expect(t.movementMs, 1400);
    expect(t.responseTimeMs, 2300);
    expect(t.chosenId, 'item_wrong');
    expect(t.errorClass, 'semantic');
    expect(t.trialIndex, 0);
    expect(t.trialContext, '{"basketSize":4}');
    expect(t.hintLevel, 1);
    expect(t.metrics, '{"taps":2}');
    expect(t.ts, 1757200000000);
    expect(t.hourOfDay, 9);
    expect(t.tzOffsetMin, 330);
    expect(t.synced, isFalse);
  });

  test('round-trips a session and closes it exactly once', () async {
    await repo.insertSession(
      SessionsCompanion.insert(
        id: 's1',
        startedAt: 1757199000000,
        gameIds: 'market_basket,face_match',
      ),
    );

    final open = await repo.getSession('s1');
    expect(open!.startedAt, 1757199000000);
    expect(open.gameIds, 'market_basket,face_match');
    expect(open.endedAt, isNull);
    expect(open.completed, isFalse);
    expect(open.demoReplays, 0);

    await repo.bumpDemoReplays('s1');
    await repo.bumpDemoReplays('s1');
    expect((await repo.getSession('s1'))!.demoReplays, 2);

    await repo.endSession(
      id: 's1',
      endedAt: 1757199360000,
      completed: true,
    );

    final closed = await repo.getSession('s1');
    expect(closed!.endedAt, 1757199360000);
    expect(closed.completed, isTrue);

    // A finalized row is never mutated again.
    await repo.endSession(id: 's1', endedAt: 999, completed: false);
    await repo.bumpDemoReplays('s1');
    final after = await repo.getSession('s1');
    expect(after!.endedAt, 1757199360000);
    expect(after.completed, isTrue);
    expect(after.demoReplays, 2);
  });

  test('round-trips reminder events and escalation requests', () async {
    await repo.insertReminderEvent(
      ReminderEventsCompanion.insert(
        id: 're1',
        medicationId: 'm1',
        scheduledAt: 1757200000000,
        firedAt: const Value(1757200005000),
        respondedAt: const Value(1757200060000),
        outcome: const Value('taken'),
        channel: 'fullscreen',
        ladderStep: 0,
      ),
    );

    final re = await repo.getReminderEvent('re1');
    expect(re!.medicationId, 'm1');
    expect(re.scheduledAt, 1757200000000);
    expect(re.firedAt, 1757200005000);
    expect(re.respondedAt, 1757200060000);
    expect(re.outcome, 'taken');
    expect(re.channel, 'fullscreen');
    expect(re.ladderStep, 0);
    expect(re.synced, isFalse);

    // Deterministic ID: {reminderEventId}_{step}. Re-inserting is a no-op.
    await repo.insertEscalation(
      EscalationRequestsCompanion.insert(
        id: 're1_1',
        reminderEventId: 're1',
        medicationId: 'm1',
        step: 1,
        requestedAt: 1757200600000,
      ),
    );
    await repo.insertEscalation(
      EscalationRequestsCompanion.insert(
        id: 're1_1',
        reminderEventId: 're1',
        medicationId: 'm1',
        step: 1,
        requestedAt: 9999999999999,
      ),
    );

    final esc = await repo.getEscalation('re1_1');
    expect(esc!.requestedAt, 1757200600000);
    expect(esc.step, 1);
    expect(esc.cancelled, isFalse);
    expect(await repo.unsyncedEscalations(), hasLength(1));
  });

  test('unsynced reads and synced flags work across all four tables', () async {
    await repo.insertSession(
      SessionsCompanion.insert(
        id: 's1',
        startedAt: 1757199000000,
        gameIds: 'market_basket',
      ),
    );
    await repo.insertTrials([trial('t1', 0), trial('t2', 1)]);
    await repo.insertReminderEvent(
      ReminderEventsCompanion.insert(
        id: 're1',
        medicationId: 'm1',
        scheduledAt: 1757200000000,
        channel: 'fullscreen',
        ladderStep: 0,
      ),
    );
    await repo.insertEscalation(
      EscalationRequestsCompanion.insert(
        id: 're1_1',
        reminderEventId: 're1',
        medicationId: 'm1',
        step: 1,
        requestedAt: 1757200600000,
      ),
    );

    expect(await repo.unsyncedSessions(), hasLength(1));
    expect(await repo.unsyncedTrials(), hasLength(2));
    expect(await repo.unsyncedReminderEvents(), hasLength(1));
    expect(await repo.unsyncedEscalations(), hasLength(1));

    await repo.markTrialsSynced(['t1']);
    expect((await repo.unsyncedTrials()).map((t) => t.id), ['t2']);

    await repo.markSessionsSynced(['s1']);
    await repo.markReminderEventsSynced(['re1']);
    await repo.markEscalationsSynced(['re1_1']);
    await repo.markTrialsSynced(['t2']);

    expect(await repo.unsyncedSessions(), isEmpty);
    expect(await repo.unsyncedTrials(), isEmpty);
    expect(await repo.unsyncedReminderEvents(), isEmpty);
    expect(await repo.unsyncedEscalations(), isEmpty);

    // Marking synced touches nothing else on the row.
    final t = (await repo.getTrialsForSession('s1')).first;
    expect(t.responseTimeMs, 2300);
    expect(t.synced, isTrue);

    await repo.markTrialsSynced([]);
  });

  group('trialsForGameBetween', () {
    setUp(() async {
      await repo.insertSession(
        SessionsCompanion.insert(
          id: 's1',
          startedAt: 1000,
          gameIds: 'market_basket',
        ),
      );
    });

    TrialEventsCompanion trialAt(String id, int ts, {String gameId = 'market_basket'}) =>
        TrialEventsCompanion.insert(
          id: id,
          sessionId: 's1',
          gameId: gameId,
          domain: 'memory',
          itemId: 'item_$id',
          itemDifficulty: 0,
          thetaBefore: 0,
          correct: true,
          initiationMs: 100,
          movementMs: 100,
          responseTimeMs: 200,
          trialIndex: 0,
          ts: ts,
          hourOfDay: 9,
          tzOffsetMin: 330,
        );

    test('includes the from boundary and excludes the to boundary', () async {
      await repo.insertTrials([
        trialAt('before', 999),
        trialAt('atFrom', 1000),
        trialAt('middle', 1500),
        trialAt('atTo', 2000),
        trialAt('after', 2001),
      ]);

      final rows = await repo.trialsForGameBetween('market_basket', 1000, 2000);
      expect(rows.map((r) => r.id), ['atFrom', 'middle']);
    });

    test('orders oldest first', () async {
      await repo.insertTrials([
        trialAt('c', 300),
        trialAt('a', 100),
        trialAt('b', 200),
      ]);

      final rows = await repo.trialsForGameBetween('market_basket', 0, 1000);
      expect(rows.map((r) => r.id), ['a', 'b', 'c']);
    });

    test('filters by gameId', () async {
      await repo.insertTrials([
        trialAt('mb', 100),
        trialAt('other', 100, gameId: 'sort_harvest'),
      ]);

      final rows = await repo.trialsForGameBetween('market_basket', 0, 1000);
      expect(rows.map((r) => r.id), ['mb']);
    });
  });

  group('sessionsBetween', () {
    test('includes the from boundary and excludes the to boundary, oldest first', () async {
      await repo.insertSession(
        SessionsCompanion.insert(id: 'before', startedAt: 999, gameIds: 'g'),
      );
      await repo.insertSession(
        SessionsCompanion.insert(id: 'atFrom', startedAt: 1000, gameIds: 'g'),
      );
      await repo.insertSession(
        SessionsCompanion.insert(id: 'middle', startedAt: 1500, gameIds: 'g'),
      );
      await repo.insertSession(
        SessionsCompanion.insert(id: 'atTo', startedAt: 2000, gameIds: 'g'),
      );

      final rows = await repo.sessionsBetween(1000, 2000);
      expect(rows.map((r) => r.id), ['atFrom', 'middle']);
    });
  });

  group('trialCountsBySessionBetween', () {
    test('counts trials per sessionId within the window only', () async {
      await repo.insertSession(
        SessionsCompanion.insert(id: 's1', startedAt: 0, gameIds: 'g'),
      );
      await repo.insertSession(
        SessionsCompanion.insert(id: 's2', startedAt: 0, gameIds: 'g'),
      );

      TrialEventsCompanion t(String id, String sessionId, int ts) =>
          TrialEventsCompanion.insert(
            id: id,
            sessionId: sessionId,
            gameId: 'market_basket',
            domain: 'memory',
            itemId: 'item_$id',
            itemDifficulty: 0,
            thetaBefore: 0,
            correct: true,
            initiationMs: 100,
            movementMs: 100,
            responseTimeMs: 200,
            trialIndex: 0,
            ts: ts,
            hourOfDay: 9,
            tzOffsetMin: 330,
          );

      await repo.insertTrials([
        t('a', 's1', 1000),
        t('b', 's1', 1100),
        t('c', 's2', 1200),
        t('outside', 's1', 5000),
      ]);

      final counts = await repo.trialCountsBySessionBetween(0, 2000);
      expect(counts, {'s1': 2, 's2': 1});
    });

    test('returns an empty map when nothing is in range', () async {
      final counts = await repo.trialCountsBySessionBetween(0, 100);
      expect(counts, isEmpty);
    });
  });
}
