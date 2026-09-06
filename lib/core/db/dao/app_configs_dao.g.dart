// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_configs_dao.dart';

// ignore_for_file: type=lint
mixin _$AppConfigsDaoMixin on DatabaseAccessor<SmritiDatabase> {
  $AppConfigsTable get appConfigs => attachedDatabase.appConfigs;
  AppConfigsDaoManager get managers => AppConfigsDaoManager(this);
}

class AppConfigsDaoManager {
  final _$AppConfigsDaoMixin _db;
  AppConfigsDaoManager(this._db);
  $$AppConfigsTableTableManager get appConfigs =>
      $$AppConfigsTableTableManager(_db.attachedDatabase, _db.appConfigs);
}
