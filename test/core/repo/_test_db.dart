import 'package:drift/native.dart';
import 'package:smriti/core/db/database.dart';

/// A throwaway in-memory database, so repo tests exercise real SQLite without
/// touching the device's `smriti.sqlite`.
SmritiDatabase newTestDb() =>
    SmritiDatabase.connect(NativeDatabase.memory());
