import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/memo_repo.dart';
import 'package:smriti/core/sync/heartbeat.dart';
import 'package:smriti/core/sync/memo_uploader.dart';
import 'package:smriti/core/repo/event_repo.dart';

import '../repo/_test_db.dart';
import '_fake_sync_gateway.dart';

void main() {
  late SmritiDatabase db;
  late MemoRepo memoRepo;
  late Directory root;

  setUp(() async {
    db = newTestDb();
    memoRepo = MemoRepo(db);
    root = await Directory.systemTemp.createTemp('smriti_memo_');
    await db.appConfigsDao.setValue('patientId', 'pat-1');
  });

  tearDown(() async {
    await db.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<String> writeMemoFile(String id, {List<int>? bytes}) async {
    final file = File(p.join(root.path, '$id.m4a'));
    await file.writeAsBytes(bytes ?? List<int>.filled(128, 3));
    return file.path;
  }

  Future<void> seedMemo(String id, String path, {String? tag}) =>
      memoRepo.insertMemo(
        VoiceMemosCompanion.insert(
          id: id,
          localPath: path,
          durationMs: 8400,
          recordedAt: 1757200000000,
          contextTag: Value(tag),
        ),
      );

  test('uploads the file BEFORE writing the row', () async {
    await seedMemo('memo-1', await writeMemoFile('memo-1'), tag: 'morning');

    final gateway = FakeSyncGateway();
    final uploaded = await MemoUploader(
      memoRepo: memoRepo,
      configs: db.appConfigsDao,
      gateway: gateway,
    ).upload();

    expect(uploaded, 1);

    // Spec 9: a row pointing at a file that never uploaded is worse than a
    // file with no row.
    expect(gateway.calls, ['upload:pat-1/memo-1.m4a', 'upsert:memos']);
    expect(gateway.uploads, ['patient-memos/pat-1/memo-1.m4a']);

    final row = gateway.rowsFor('memos').single;
    expect(row['id'], 'memo-1');
    expect(row['patient_id'], 'pat-1');
    expect(row['storage_path'], 'pat-1/memo-1.m4a');
    expect(row['duration_ms'], 8400);
    expect(row['recorded_at'], 1757200000000);
    expect(row['context_tag'], 'morning');

    expect(await memoRepo.pendingUploads(), isEmpty);
  });

  test('a failed upload writes no row and keeps the memo pending', () async {
    await seedMemo('memo-1', await writeMemoFile('memo-1'));

    final gateway = FakeSyncGateway(failUploadOn: 'pat-1/memo-1.m4a');

    await expectLater(
      MemoUploader(
        memoRepo: memoRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ).upload(),
      throwsA(isA<Exception>()),
    );

    expect(gateway.rowsFor('memos'), isEmpty,
        reason: 'no row may point at a file that never uploaded');
    expect(await memoRepo.pendingUploads(), hasLength(1));
  });

  test('a failed row write leaves the memo pending for retry', () async {
    await seedMemo('memo-1', await writeMemoFile('memo-1'));

    final gateway = FakeSyncGateway(failUpsertOn: 'memos');

    await expectLater(
      MemoUploader(
        memoRepo: memoRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ).upload(),
      throwsA(isA<Exception>()),
    );

    // The file is up there; the retry re-uploads and writes the row. Storage
    // upsert makes that harmless.
    expect(await memoRepo.pendingUploads(), hasLength(1));
  });

  test('a memo whose file vanished is retired, not retried forever', () async {
    await seedMemo('memo-1', p.join(root.path, 'gone.m4a'));

    final gateway = FakeSyncGateway();
    final uploaded = await MemoUploader(
      memoRepo: memoRepo,
      configs: db.appConfigsDao,
      gateway: gateway,
    ).upload();

    expect(uploaded, 0);
    expect(gateway.calls, isEmpty);
    expect(await memoRepo.pendingUploads(), isEmpty,
        reason: 'a missing file would otherwise wedge the queue');
  });

  test('an empty recording is retired too', () async {
    await seedMemo('memo-1', await writeMemoFile('memo-1', bytes: const []));

    final gateway = FakeSyncGateway();
    expect(
      await MemoUploader(
        memoRepo: memoRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ).upload(),
      0,
    );
    expect(gateway.calls, isEmpty);
    expect(await memoRepo.pendingUploads(), isEmpty);
  });

  test('memos upload oldest first', () async {
    for (var i = 0; i < 3; i++) {
      await memoRepo.insertMemo(
        VoiceMemosCompanion.insert(
          id: 'memo-$i',
          localPath: await writeMemoFile('memo-$i'),
          durationMs: 1000,
          recordedAt: 1757200000000 + i,
        ),
      );
    }

    final gateway = FakeSyncGateway();
    expect(
      await MemoUploader(
        memoRepo: memoRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ).upload(),
      3,
    );

    expect(gateway.uploads, [
      'patient-memos/pat-1/memo-0.m4a',
      'patient-memos/pat-1/memo-1.m4a',
      'patient-memos/pat-1/memo-2.m4a',
    ]);
  });

  test('nothing uploads before pairing', () async {
    await db.appConfigsDao.deleteValue('patientId');
    await seedMemo('memo-1', await writeMemoFile('memo-1'));

    final gateway = FakeSyncGateway();
    expect(
      await MemoUploader(
        memoRepo: memoRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
      ).upload(),
      0,
    );
    expect(gateway.calls, isEmpty);
    expect(await memoRepo.pendingUploads(), hasLength(1));
  });

  group('Heartbeat', () {
    test('reports pending events and records the clock skew', () async {
      final eventRepo = EventRepo(db);
      await eventRepo.insertSession(
        SessionsCompanion.insert(
          id: 'ses-1',
          startedAt: 1757199000000,
          gameIds: 'market_basket',
        ),
      );

      final gateway = FakeSyncGateway(
        rpcResponse: {'server_time_ms': 1757200005000, 'clock_skew_ms': 5000},
      );

      await Heartbeat(
        eventRepo: eventRepo,
        configs: db.appConfigsDao,
        gateway: gateway,
        appVersion: '1.2.3',
        now: () => DateTime.fromMillisecondsSinceEpoch(1757200000000),
      ).send();

      expect(gateway.rpcCalls.single, {
        'name': 'device_heartbeat',
        'p_patient_id': 'pat-1',
        'p_app_version': '1.2.3',
        'p_pending_events': 1,
        'p_device_time_ms': 1757200000000,
      });

      expect(await db.appConfigsDao.getValue('clockSkewMs'), '5000');
      expect(await db.appConfigsDao.getValue('lastSyncAt'), '1757200000000');
    });

    test('a heartbeat with no skew reported still records the sync time',
        () async {
      final gateway = FakeSyncGateway(rpcResponse: const {});

      await Heartbeat(
        eventRepo: EventRepo(db),
        configs: db.appConfigsDao,
        gateway: gateway,
        now: () => DateTime.fromMillisecondsSinceEpoch(1757200000000),
      ).send();

      expect(await db.appConfigsDao.getValue('lastSyncAt'), '1757200000000');
      expect(await db.appConfigsDao.getValue('clockSkewMs'), isNull);
    });

    test('an unpaired device sends no heartbeat', () async {
      await db.appConfigsDao.deleteValue('patientId');
      final gateway = FakeSyncGateway();

      await Heartbeat(
        eventRepo: EventRepo(db),
        configs: db.appConfigsDao,
        gateway: gateway,
      ).send();

      expect(gateway.rpcCalls, isEmpty);
    });
  });
}
