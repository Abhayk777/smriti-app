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

  Future<void> deleteValue(String key) async {
    await (delete(appConfigs)
          ..where((tbl) => tbl.key.equals(key)))
        .go();
  }
}