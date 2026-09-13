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

  /// Connects to a caller-supplied [QueryExecutor] instead of opening the
  /// default on-device connection.
  ///
  /// DO NOT DELETE AS UNUSED. Two callers depend on this, one of which does not
  /// exist yet:
  ///
  ///  1. Repository tests, which pass `NativeDatabase.memory()` so they exercise
  ///     real SQLite without touching the device's `smriti.sqlite`.
  ///  2. `fireReminderCallback` (task A11, APP-BUILD-SPEC.md §10). Per AGENTS.md
  ///     non-negotiable #6, `AndroidAlarmManager` callbacks run in a separate
  ///     isolate with no access to anything in the main isolate, so they must
  ///     open their own connection. §10 writes that as
  ///     `SmritiDatabase(await openConnectionForIsolate())` — an executor passed
  ///     in by the isolate. This is that constructor; the default one takes no
  ///     arguments and cannot express it.
  ///
  /// Until A11 lands, only the tests reference this, so it will look removable.
  /// It is not.
  SmritiDatabase.connect(super.executor);

  @override
  int get schemaVersion => 1;
}

// DATABASE CONNECTION

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(p.join(directory.path, 'smriti.sqlite'));

    return NativeDatabase.createInBackground(file, setup: _configureConnection);
  });
}

/// Several isolates open this file at once (main app, alarm callbacks, the
/// reminder screen's engine). Without a busy timeout, a write that collides
/// with another connection's write fails immediately with "database is
/// locked"; WAL also lets readers and a writer work concurrently.
// A variable, not a declaration: the parameter type lives in package:sqlite3,
// which is not a direct dependency.
// ignore: prefer_function_declarations_over_variables
final DatabaseSetup _configureConnection = (database) {
  database.execute('PRAGMA busy_timeout = 5000;');
  database.execute('PRAGMA journal_mode = WAL;');
};

/// Opens a database connection for use in isolates.
///
/// Isolates cannot access the main isolate's database connection, so they
/// must open their own. This function creates a LazyDatabase that will
/// open a connection to the on-device SQLite file.
///
/// Used by: `fireReminderCallback` (A11) per AGENTS.md non-negotiable #6.
Future<QueryExecutor> openConnectionForIsolate() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, 'smriti.sqlite'));
  return NativeDatabase.createInBackground(file, setup: _configureConnection);
}
