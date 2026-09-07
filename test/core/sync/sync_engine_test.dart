import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/ability_repo.dart';
import 'package:smriti/core/repo/content_repo.dart';
import 'package:smriti/core/repo/event_repo.dart';
import 'package:smriti/core/repo/memo_repo.dart';
import 'package:smriti/core/sync/content_puller.dart';
import 'package:smriti/core/sync/escalation_writer.dart';
import 'package:smriti/core/sync/event_pusher.dart';
import 'package:smriti/core/sync/heartbeat.dart';
import 'package:smriti/core/sync/media_downloader.dart';
import 'package:smriti/core/sync/memo_uploader.dart';
import 'package:smriti/core/sync/sync_engine.dart';
import 'package:smriti/games/cognitive_game.dart';
import 'package:smriti/games/market_basket/market_basket_game.dart';
import 'package:smriti/games/session_runner.dart';

import '../repo/_test_db.dart';
import '_fake_sync_gateway.dart';
import 'content_puller_test.dart' show FakeMediaFetcher, TempMediaStorage;

void main() {
  late SmritiDatabase db;
  late EventRepo eventRepo;
  late Directory root;

  setUp(() async {
    db = newTestDb();
    eventRepo = EventRepo(db);
    root = await Directory.systemTemp.createTemp('smriti_engine_');
    await db.appConfigsDao.setValue('patientId', 'pat-1');
  });

  tearDown(() async {
    await db.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  SyncEngine newEngine(
    FakeSyncGateway gateway, {
    bool online = true,
    bool authed = true,
    ContentGateway? contentGateway,
    DateTime Function()? now,
  }) {
    return SyncEngine(
      eventPusher: EventPusher(
        eventRepo: eventRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ),
      escalationWriter: EscalationWriter(
        eventRepo: eventRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ),
      memoUploader: MemoUploader(
        memoRepo: MemoRepo(db),
        configs: db.appConfigsDao,
        gateway: gateway,
      ),
      contentPuller: ContentPuller(
        configs: db.appConfigsDao,
        contentRepo: ContentRepo(db),
        mediaDownloader: MediaDownloader(
          fetcher: FakeMediaFetcher(),
          storage: TempMediaStorage(root),
        ),
        gateway: contentGateway ?? _NoContentGateway(),
      ),
      heartbeat: Heartbeat(
        eventRepo: eventRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ),
      configs: db.appConfigsDao,
      hasConnection: () async => online,
      isAuthenticated: () async => authed,
      now: now,
    );
  }

  test('playing a session then syncing lands rows with matching ids', () async {
    // Play a real session through the harness, exactly as the app would.
    final game = MarketBasketGame(random: Random(7));
    addTearDown(game.dispose);

    final runner = SessionRunner(
      eventRepo: eventRepo,
      abilityRepo: AbilityRepo(db),
      content: const GameContent(
        version: 'mock-1',
        marketItems: [
          MarketItem(
            id: 'rice',
            labelKey: 'item.rice',
            iconAsset: 'a.png',
            category: 'grain',
          ),
          MarketItem(
            id: 'dal',
            labelKey: 'item.dal',
            iconAsset: 'b.png',
            category: 'pulse',
          ),
          MarketItem(
            id: 'milk',
            labelKey: 'item.milk',
            iconAsset: 'c.png',
            category: 'dairy',
          ),
        ],
      ),
    );

    final sessionId = await runner.start([game]);
    final item = (await runner.nextItem(game))!;
    final written = runner.feedback.first;
    game.submit(
      item: item,
      chosenIds:
          (item.context['targetIds']! as List<Object?>).cast<String>(),
      initiationMs: 900,
      movementMs: 1400,
    );
    await written;
    await runner.end(completed: true);

    final localTrials = await eventRepo.getTrialsForSession(sessionId);
    expect(localTrials, hasLength(1));

    // Now sync.
    final gateway = FakeSyncGateway();
    final result = await newEngine(gateway).run(trigger: SyncTrigger.sessionEnd);
    expect(result.isOk, isTrue, reason: result.toString());

    // The remote rows carry the same client-generated ids as the local ones.
    expect(gateway.rowsFor('sessions').single['id'], sessionId);
    expect(gateway.rowsFor('events').single['id'], localTrials.single.id);
    expect(gateway.rowsFor('events').single['session_id'], sessionId);
    expect(gateway.rowsFor('events').single['patient_id'], 'pat-1');

    // And nothing is left queued.
    expect(await eventRepo.unsyncedCount(), 0);
  });

  test('one failing stage does not stop the others', () async {
    await eventRepo.insertSession(
      SessionsCompanion.insert(
        id: 'ses-1',
        startedAt: 1757199000000,
        gameIds: 'market_basket',
      ),
    );

    // Spec 9: a content-pull failure must never prevent event upload.
    final gateway = FakeSyncGateway();
    final result = await newEngine(
      gateway,
      contentGateway: _ThrowingContentGateway(),
    ).run();

    expect(result.status, 'partial');
    expect(result.errors.single, startsWith('content:'));

    // Events still went up, and the heartbeat still fired.
    expect(gateway.rowsFor('sessions'), hasLength(1));
    expect(gateway.rpcCalls.single['name'], 'device_heartbeat');
    expect(await eventRepo.unsyncedSessions(), isEmpty);

    // Recorded for the diagnostics screen only, never shown to the elder.
    expect(await db.appConfigsDao.getValue('lastSyncError'),
        startsWith('content:'));
  });

  test('offline and unauthenticated runs skip without touching the network',
      () async {
    final offline = FakeSyncGateway();
    expect((await newEngine(offline, online: false).run()).reason, 'offline');
    expect(offline.calls, isEmpty);

    final unauthed = FakeSyncGateway();
    expect((await newEngine(unauthed, authed: false).run()).reason,
        'not authed');
    expect(unauthed.calls, isEmpty);
  });

  test('runs are throttled, but a finished session always syncs', () async {
    var clock = DateTime(2025, 9, 7, 9, 30);
    final gateway = FakeSyncGateway();
    final engine = newEngine(gateway, now: () => clock);

    expect((await engine.run()).isOk, isTrue);

    // Too soon for a periodic run.
    clock = clock.add(const Duration(seconds: 30));
    expect((await engine.run()).reason, 'throttled');

    // A session ending overrides the throttle - that data matters most.
    expect(
      (await engine.run(trigger: SyncTrigger.sessionEnd)).isOk,
      isTrue,
    );

    clock = clock.add(const Duration(minutes: 3));
    expect((await engine.run()).isOk, isTrue);
  });

  test('the stage order puts the elder data first', () async {
    await eventRepo.insertSession(
      SessionsCompanion.insert(
        id: 'ses-1',
        startedAt: 1757199000000,
        gameIds: 'market_basket',
      ),
    );

    final gateway = FakeSyncGateway();
    await newEngine(gateway).run();

    expect(gateway.calls, ['upsert:sessions', 'rpc:device_heartbeat']);
  });
}

/// Content gateway that reports no content, so the pull is a no-op.
class _NoContentGateway implements ContentGateway {
  @override
  Future<String?> fetchRemoteContentVersion(String patientId) async => null;

  @override
  Future<Map<String, dynamic>> fetchContent(String patientId) async => const {};
}

class _ThrowingContentGateway implements ContentGateway {
  @override
  Future<String?> fetchRemoteContentVersion(String patientId) async =>
      throw Exception('content service down');

  @override
  Future<Map<String, dynamic>> fetchContent(String patientId) async => const {};
}
