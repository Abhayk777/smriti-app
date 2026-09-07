import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'app_configs_dao.g.dart';

@DriftAccessor(tables: [AppConfigs])
class AppConfigsDao extends DatabaseAccessor<SmritiDatabase>
    with _$AppConfigsDaoMixin {
  AppConfigsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(appConfigs)
          ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();

    return row?.value;
  }

  Future<void> setValue(String key, String value) async {
    await into(appConfigs).insertOnConflictUpdate(
      AppConfigsCompanion.insert(
        key: key,
        value: value,
      ),
    );
  }

  /// Writes several keys in one transaction, so a crash mid-pairing cannot
  /// leave `AppConfigs` half-populated (APP-BUILD-SPEC.md §8).
  Future<void> setAll(Map<String, String> entries) async {
    if (entries.isEmpty) return;
    await transaction(() async {
      await batch((batch) {
        batch.insertAllOnConflictUpdate(
          appConfigs,
          [
            for (final entry in entries.entries)
              AppConfigsCompanion.insert(key: entry.key, value: entry.value),
          ],
        );
      });
    });
  }

  Future<void> deleteValue(String key) async {
    await (delete(appConfigs)
          ..where((tbl) => tbl.key.equals(key)))
        .go();
  }
}