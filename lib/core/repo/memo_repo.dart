import 'package:drift/drift.dart';

import '../db/database.dart';

/// Store for elder voice memos recorded on the tablet.
///
/// AGENTS.md non-negotiable #3: `VoiceMemos` is INSERT-only; the sole permitted
/// update is flipping `uploaded` once the memo uploader has shipped the file.
/// The audio itself lives on disk at `<docs>/memos/{memoId}.m4a`; this repo
/// stores only the row that points at it.
class MemoRepo {
  MemoRepo(this.db);

  final SmritiDatabase db;

  Future<void> insertMemo(VoiceMemosCompanion memo) async {
    await db.into(db.voiceMemos).insert(memo);
  }

  Future<VoiceMemo?> getMemo(String id) {
    return (db.select(db.voiceMemos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Newest first — the elder's most recent memo is the one worth replaying.
  Future<List<VoiceMemo>> getMemos({int? limit}) {
    final query = db.select(db.voiceMemos)
      ..orderBy([
        (t) => OrderingTerm(expression: t.recordedAt, mode: OrderingMode.desc),
      ]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  Future<List<VoiceMemo>> getMemosByContext(String contextTag) {
    return (db.select(db.voiceMemos)
          ..where((t) => t.contextTag.equals(contextTag))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.recordedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<VoiceMemo>> pendingUploads({int limit = 50}) {
    return (db.select(db.voiceMemos)
          ..where((t) => t.uploaded.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.recordedAt)])
          ..limit(limit))
        .get();
  }

  /// The only permitted update on this table.
  Future<void> markUploaded(List<String> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.customUpdate(
      'UPDATE voice_memos SET uploaded = 1 WHERE id IN ($placeholders)',
      variables: [for (final id in ids) Variable<String>(id)],
      updates: {db.voiceMemos},
    );
  }
}
