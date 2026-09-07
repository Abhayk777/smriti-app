import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/event_repo.dart';
import 'package:smriti/core/sync/escalation_writer.dart';
import 'package:smriti/core/sync/event_pusher.dart';

import '../repo/_test_db.dart';
import '_fake_sync_gateway.dart';

void main() {
  late SmritiDatabase db;
  late EventRepo eventRepo;

  setUp(() async {
    db = newTestDb();
    eventRepo = EventRepo(db);
    await db.appConfigsDao.setValue('patientId', 'pat-1');
  });

  tearDown(() async => db.close());

  Future<void> seedSession({String id = 'ses-1'}) => eventRepo.insertSession(
        SessionsCompanion.insert(
          id: id,
          startedAt: 1757199000000,
          gameIds: 'market_basket',
        ),
      );

  Future<void> seedTrial({String id = 'tri-1', String sessionId = 'ses-1'}) =>
      eventRepo.insertTrial(
        TrialEventsCompanion.insert(
          id: id,
          sessionId: sessionId,
          gameId: 'market_basket',
          domain: 'memory',
          itemId: 'mb_rice-dal',
          itemDifficulty: -0.266,
          thetaBefore: 1.0,
          correct: true,
          initiationMs: 900,
          movementMs: 1400,
          responseTimeMs: 2300,
          chosenId: const Value('rice'),
          errorClass: const Value('semantic_near'),
          trialIndex: 0,
          trialContext: const Value('{"listLength":3}'),
          hintLevel: const Value(1),
          metrics: const Value('{"picked":3}'),
          ts: 1757200000000,
          hourOfDay: 9,
          tzOffsetMin: 330,
        ),
      );

  test('pushes sessions, trials and reminder events, then marks them synced',
      () async {
    await seedSession();
    await seedTrial();
    await eventRepo.insertReminderEvent(
      ReminderEventsCompanion.insert(
        id: 'rem-1',
        medicationId: 'med-1',
        scheduledAt: 1757200000000,
        firedAt: const Value(1757200005000),
        outcome: const Value('taken'),
        channel: 'fullscreen',
        ladderStep: 0,
      ),
    );

    final gateway = FakeSyncGateway();
    final pushed = await EventPusher(
      eventRepo: eventRepo,
      configs: db.appConfigsDao,
      gateway: gateway,
    ).push();

    expect(pushed, 3);

    // Sessions go before the trials that reference them.
    expect(gateway.calls, [
      'upsert:sessions',
      'upsert:events',
      'upsert:reminder_events',
    ]);

    // Every trial column travels, with the patient id attached.
    final trial = gateway.rowsFor('events').single;
    expect(trial['id'], 'tri-1');
    expect(trial['patient_id'], 'pat-1');
    expect(trial['session_id'], 'ses-1');
    expect(trial['game_id'], 'market_basket');
    expect(trial['domain'], 'memory');
    expect(trial['item_id'], 'mb_rice-dal');
    expect(trial['item_difficulty'], closeTo(-0.266, 1e-9));
    expect(trial['theta_before'], 1.0);
    expect(trial['correct'], isTrue);
    expect(trial['initiation_ms'], 900);
    expect(trial['movement_ms'], 1400);
    expect(trial['response_time_ms'], 2300);
    expect(trial['chosen_id'], 'rice');
    expect(trial['error_class'], 'semantic_near');
    expect(trial['trial_index'], 0);
    // trial_context is a `text` column: the encoded string is the value.
    expect(trial['trial_context'], '{"listLength":3}');
    expect(trial['hint_level'], 1);
    // metrics is `jsonb`: it must arrive as an object, or queries like
    // metrics->>'picked' silently return null.
    expect(trial['metrics'], isA<Map<String, dynamic>>());
    expect(trial['metrics'], {'picked': 3});
    expect(trial['ts'], 1757200000000);
    expect(trial['hour_of_day'], 9);
    expect(trial['tz_offset_min'], 330);

    final session = gateway.rowsFor('sessions').single;
    expect(session['id'], 'ses-1');
    expect(session['patient_id'], 'pat-1');
    expect(session['game_ids'], 'market_basket');
    expect(session['demo_replays'], 0);

    final reminder = gateway.rowsFor('reminder_events').single;
    expect(reminder['medication_id'], 'med-1');
    expect(reminder['outcome'], 'taken');
    expect(reminder['ladder_step'], 0);

    // Nothing is left queued.
    expect(await eventRepo.unsyncedSessions(), isEmpty);
    expect(await eventRepo.unsyncedTrials(), isEmpty);
    expect(await eventRepo.unsyncedReminderEvents(), isEmpty);
    expect(await eventRepo.unsyncedCount(), 0);
  });

  test('every timestamp goes up as an epoch-ms int, matching bigint columns',
      () async {
    await seedSession();
    await seedTrial();
    await eventRepo.insertReminderEvent(
      ReminderEventsCompanion.insert(
        id: 'rem-1',
        medicationId: 'med-1',
        scheduledAt: 1757200000000,
        firedAt: const Value(1757200005000),
        respondedAt: const Value(1757200060000),
        channel: 'fullscreen',
        ladderStep: 0,
      ),
    );
    await eventRepo.insertEscalation(
      EscalationRequestsCompanion.insert(
        id: 'rem-1_2',
        reminderEventId: 'rem-1',
        medicationId: 'med-1',
        step: 2,
        requestedAt: 1757200600000,
      ),
    );
    await eventRepo.endSession(
      id: 'ses-1',
      endedAt: 1757199360000,
      completed: false,
      abandonedAtMs: 120000,
    );

    final gateway = FakeSyncGateway();
    await EventPusher(
      eventRepo: eventRepo,
      configs: db.appConfigsDao,
      gateway: gateway,
    ).push();
    await EscalationWriter(
      eventRepo: eventRepo,
      configs: db.appConfigsDao,
      gateway: gateway,
    ).flush();

    // No ISO-8601 strings anywhere: these columns are all bigint.
    expect(gateway.rowsFor('events').single['ts'], isA<int>());
    final session = gateway.rowsFor('sessions').single;
    expect(session['started_at'], isA<int>());
    expect(session['ended_at'], 1757199360000);
    expect(session['abandoned_at_ms'], 120000);
    final reminder = gateway.rowsFor('reminder_events').single;
    expect(reminder['scheduled_at'], isA<int>());
    expect(reminder['fired_at'], 1757200005000);
    expect(reminder['responded_at'], 1757200060000);
    expect(gateway.rowsFor('escalations').single['requested_at'], isA<int>());
  });

  test('nullable columns travel as null, not as empty strings', () async {
    await seedSession();
    await eventRepo.insertTrial(
      TrialEventsCompanion.insert(
        id: 'tri-2',
        sessionId: 'ses-1',
        gameId: 'market_basket',
        domain: 'memory',
        itemId: 'mb_rice',
        itemDifficulty: 0.0,
        thetaBefore: 0.0,
        correct: true,
        initiationMs: 100,
        movementMs: 200,
        responseTimeMs: 300,
        trialIndex: 0,
        ts: 1757200000000,
        hourOfDay: 9,
        tzOffsetMin: 330,
      ),
    );

    final gateway = FakeSyncGateway();
    await EventPusher(
      eventRepo: eventRepo,
      configs: db.appConfigsDao,
      gateway: gateway,
    ).push();

    final trial = gateway.rowsFor('events').single;
    expect(trial['chosen_id'], isNull);
    expect(trial['error_class'], isNull);
    expect(trial['trial_context'], isNull);
    expect(trial['metrics'], isNull, reason: 'jsonb null, not "null"');
  });

  test('a failed push leaves rows queued for the next run', () async {
    await seedSession();
    await seedTrial();

    final gateway = FakeSyncGateway(failUpsertOn: 'events');
    final pusher = EventPusher(
      eventRepo: eventRepo,
      configs: db.appConfigsDao,
      gateway: gateway,
    );

    await expectLater(pusher.push(), throwsA(isA<Exception>()));

    // The session made it, so it is marked; the trial did not.
    expect(await eventRepo.unsyncedSessions(), isEmpty);
    expect(await eventRepo.unsyncedTrials(), hasLength(1),
        reason: 'never mark synced on a write that threw');

    // Retrying with a working gateway drains it.
    final retry = FakeSyncGateway();
    await EventPusher(
      eventRepo: eventRepo,
      configs: db.appConfigsDao,
      gateway: retry,
    ).push();
    expect(retry.rowsFor('events'), hasLength(1));
    expect(await eventRepo.unsyncedTrials(), isEmpty);
  });

  test('nothing is pushed before pairing', () async {
    await db.appConfigsDao.deleteValue('patientId');
    await seedSession();

    final gateway = FakeSyncGateway();
    final pushed = await EventPusher(
      eventRepo: eventRepo,
      configs: db.appConfigsDao,
      gateway: gateway,
    ).push();

    expect(pushed, 0);
    expect(gateway.calls, isEmpty);
    expect(await eventRepo.unsyncedSessions(), hasLength(1));
  });

  test('an empty queue makes no calls at all', () async {
    final gateway = FakeSyncGateway();
    expect(
      await EventPusher(
        eventRepo: eventRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ).push(),
      0,
    );
    expect(gateway.calls, isEmpty);
  });

  group('EscalationWriter', () {
    test('writes requested escalations with a deterministic id', () async {
      await eventRepo.insertEscalation(
        EscalationRequestsCompanion.insert(
          id: 'rem-1_2',
          reminderEventId: 'rem-1',
          medicationId: 'med-1',
          step: 2,
          requestedAt: 1757200600000,
        ),
      );

      final gateway = FakeSyncGateway();
      final written = await EscalationWriter(
        eventRepo: eventRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ).flush();

      expect(written, 1);
      final row = gateway.rowsFor('escalations').single;
      expect(row['id'], 'rem-1_2');
      expect(row['patient_id'], 'pat-1');
      expect(row['reminder_event_id'], 'rem-1');
      expect(row['medication_id'], 'med-1');
      expect(row['step'], 2);
      expect(row['requested_at'], 1757200600000);
      // The device only ever writes 'requested' (spec 7).
      expect(row['status'], 'requested');

      expect(await eventRepo.unsyncedEscalations(), isEmpty);
    });

    test('a cancelled escalation is never sent, but stops being pending',
        () async {
      await eventRepo.insertEscalation(
        EscalationRequestsCompanion.insert(
          id: 'rem-1_2',
          reminderEventId: 'rem-1',
          medicationId: 'med-1',
          step: 2,
          requestedAt: 1757200600000,
          cancelled: const Value(true),
        ),
      );

      final gateway = FakeSyncGateway();
      final written = await EscalationWriter(
        eventRepo: eventRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ).flush();

      expect(written, 0);
      expect(gateway.calls, isEmpty,
          reason: 'the elder already took the dose - never call anyone');
      expect(await eventRepo.unsyncedEscalations(), isEmpty);
    });

    test('re-flushing the same escalation cannot place a second call',
        () async {
      await eventRepo.insertEscalation(
        EscalationRequestsCompanion.insert(
          id: 'rem-1_2',
          reminderEventId: 'rem-1',
          medicationId: 'med-1',
          step: 2,
          requestedAt: 1757200600000,
        ),
      );

      final gateway = FakeSyncGateway();
      final writer = EscalationWriter(
        eventRepo: eventRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      );

      expect(await writer.flush(), 1);
      expect(await writer.flush(), 0);
      expect(gateway.rowsFor('escalations'), hasLength(1));
    });
  });
}
