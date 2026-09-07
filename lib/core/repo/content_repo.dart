import 'package:drift/drift.dart';

import '../db/database.dart';

/// Read/write access to pulled content: people, medications and routine items.
///
/// SQLite only — the sync layer hands this repo already-downloaded rows, it
/// never reaches the network itself. Per spec §5 the content version lives in
/// `AppConfigs` under the `contentVersion` key.
class ContentRepo {
  ContentRepo(this.db);

  final SmritiDatabase db;

  static const String contentVersionKey = 'contentVersion';

  // PEOPLE

  Future<List<PeopleData>> getPeople() {
    return (db.select(db.people)
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  Future<PeopleData?> getPerson(String id) {
    return (db.select(db.people)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// People who are alive, for games that would be distressing otherwise.
  Future<List<PeopleData>> getLivingPeople() {
    return (db.select(db.people)
          ..where((t) => t.isDeceased.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  // MEDICATIONS

  Future<List<Medication>> getMedications({bool activeOnly = true}) {
    final query = db.select(db.medications);
    if (activeOnly) {
      query.where((t) => t.active.equals(true));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.chosenTimeMin)]);
    return query.get();
  }

  Future<Medication?> getMedication(String id) {
    return (db.select(db.medications)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ROUTINE ITEMS

  Future<List<RoutineItem>> getRoutineItems() {
    return (db.select(db.routineItems)
          ..orderBy([(t) => OrderingTerm(expression: t.timeMin)]))
        .get();
  }

  // CONTENT VERSION

  Future<String?> getContentVersion() =>
      db.appConfigsDao.getValue(contentVersionKey);

  /// Atomic content swap — step 3 of the pull order in AGENTS.md #5
  /// (download media → verify on disk → swap → reschedule alarms).
  ///
  /// Everything happens in one transaction, so a crash mid-swap leaves the
  /// previous content intact rather than a half-populated set. Callers must
  /// have verified every referenced media file on disk before calling this,
  /// and must only pass [contentVersion] once that verification passed.
  Future<void> replaceContent({
    required List<PeopleCompanion> people,
    required List<MedicationsCompanion> medications,
    required List<RoutineItemsCompanion> routineItems,
    String? contentVersion,
  }) {
    return db.transaction(() async {
      await db.delete(db.people).go();
      await db.delete(db.medications).go();
      await db.delete(db.routineItems).go();

      await db.batch((batch) {
        batch.insertAll(db.people, people);
        batch.insertAll(db.medications, medications);
        batch.insertAll(db.routineItems, routineItems);
      });

      if (contentVersion != null) {
        await db.appConfigsDao.setValue(contentVersionKey, contentVersion);
      }
    });
  }
}
