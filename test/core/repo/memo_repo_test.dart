import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/memo_repo.dart';

import '_test_db.dart';

void main() {
  late SmritiDatabase db;
  late MemoRepo repo;

  setUp(() {
    db = newTestDb();
    repo = MemoRepo(db);
  });

  tearDown(() async => db.close());

  test('round-trips a voice memo', () async {
    await repo.insertMemo(
      VoiceMemosCompanion.insert(
        id: 'memo1',
        localPath: '/docs/memos/memo1.m4a',
        durationMs: 8400,
        recordedAt: 1757200000000,
        contextTag: const Value('morning'),
      ),
    );

    final memo = await repo.getMemo('memo1');
    expect(memo, isNotNull);
    expect(memo!.localPath, '/docs/memos/memo1.m4a');
    expect(memo.durationMs, 8400);
    expect(memo.recordedAt, 1757200000000);
    expect(memo.contextTag, 'morning');
    expect(memo.uploaded, isFalse);

    expect(await repo.getMemo('nope'), isNull);
  });

  test('lists memos newest first, and filters by context tag', () async {
    await repo.insertMemo(
      VoiceMemosCompanion.insert(
        id: 'older',
        localPath: '/docs/memos/older.m4a',
        durationMs: 3000,
        recordedAt: 1757100000000,
        contextTag: const Value('evening'),
      ),
    );
    await repo.insertMemo(
      VoiceMemosCompanion.insert(
        id: 'newer',
        localPath: '/docs/memos/newer.m4a',
        durationMs: 5000,
        recordedAt: 1757200000000,
        contextTag: const Value('morning'),
      ),
    );

    expect((await repo.getMemos()).map((m) => m.id), ['newer', 'older']);
    expect((await repo.getMemos(limit: 1)).map((m) => m.id), ['newer']);
    expect((await repo.getMemosByContext('evening')).map((m) => m.id),
        ['older']);
  });

  test('pendingUploads drains as memos are marked uploaded', () async {
    for (var i = 0; i < 3; i++) {
      await repo.insertMemo(
        VoiceMemosCompanion.insert(
          id: 'memo$i',
          localPath: '/docs/memos/memo$i.m4a',
          durationMs: 1000 + i,
          recordedAt: 1757200000000 + i,
        ),
      );
    }

    // Oldest first, so the upload queue is FIFO.
    expect((await repo.pendingUploads()).map((m) => m.id),
        ['memo0', 'memo1', 'memo2']);

    await repo.markUploaded(['memo0', 'memo1']);
    expect((await repo.pendingUploads()).map((m) => m.id), ['memo2']);

    // Flipping `uploaded` leaves the rest of the row untouched.
    final memo0 = await repo.getMemo('memo0');
    expect(memo0!.uploaded, isTrue);
    expect(memo0.localPath, '/docs/memos/memo0.m4a');
    expect(memo0.durationMs, 1000);

    await repo.markUploaded([]);
    expect((await repo.pendingUploads()).map((m) => m.id), ['memo2']);
  });
}
