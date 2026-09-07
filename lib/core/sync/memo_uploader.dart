import 'dart:io';

import '../db/dao/app_configs_dao.dart';
import '../repo/memo_repo.dart';
import 'remote_rows.dart';
import 'sync_gateway.dart';

/// Storage bucket for elder recordings, per APP-BUILD-SPEC.md §7.
const String patientMemosBucket = 'patient-memos';

/// Uploads elder voice memos: the audio file first, then the row.
///
/// §9 is explicit about the order — "a row pointing at a file that never
/// uploaded is worse than a file with no row". So the upload has to succeed
/// before the `memos` row is written, and the local memo is only marked
/// uploaded after both.
class MemoUploader {
  MemoUploader({
    required this.memoRepo,
    required this.configs,
    this.gateway = const SupabaseSyncGateway(),
    this.batchSize = 20,
  });

  final MemoRepo memoRepo;
  final AppConfigsDao configs;
  final SyncGateway gateway;
  final int batchSize;

  static const String patientIdKey = 'patientId';

  /// Returns how many memos were fully uploaded.
  ///
  /// Memos are handled one at a time so a single bad file cannot block the
  /// rest of the queue.
  Future<int> upload() async {
    final patientId = await configs.getValue(patientIdKey);
    if (patientId == null || patientId.isEmpty) return 0;

    final pending = await memoRepo.pendingUploads(limit: batchSize);
    var uploaded = 0;

    for (final memo in pending) {
      final file = File(memo.localPath);

      // The recording is gone — nothing to upload, and retrying forever would
      // wedge the queue. Mark it done and move on.
      if (!await file.exists()) {
        await memoRepo.markUploaded([memo.id]);
        continue;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        await memoRepo.markUploaded([memo.id]);
        continue;
      }

      // 1. File first.
      final objectPath = await gateway.uploadFile(
        patientMemosBucket,
        '$patientId/${memo.id}.m4a',
        bytes,
      );

      // 2. Then the row that points at it.
      await gateway.upsert(
        RemoteRows.memosTable,
        [RemoteRows.memo(memo, patientId, objectPath)],
      );

      // 3. Only now is it done locally.
      await memoRepo.markUploaded([memo.id]);
      uploaded++;
    }

    return uploaded;
  }
}
