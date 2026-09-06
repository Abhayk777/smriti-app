import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables.dart';
import 'dao/app_configs_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    TrialEvents,
    Sessions,
    ReminderEvents,
    VoiceMemos,
    EscalationRequests,
    AbilityStates,
    People,
    Medications,
    RoutineItems,
    AppConfigs,
  ],
  daos: [
    AppConfigsDao,
  ],
)
class SmritiDatabase extends _$SmritiDatabase {
  SmritiDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// DATABASE CONNECTION

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(p.join(directory.path, 'smriti.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
