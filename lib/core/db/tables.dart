import 'package:drift/drift.dart';

// TRIAL EVENTS

class TrialEvents extends Table {
  TextColumn get id => text()();

  TextColumn get sessionId => text()();

  TextColumn get gameId => text()();

  TextColumn get domain => text()();

  // Specific item used in the trial
  TextColumn get itemId => text()();

  RealColumn get itemDifficulty => real()();

  RealColumn get thetaBefore => real()();

  BoolColumn get correct => boolean()();

  // Timing
  IntColumn get initiationMs => integer()();

  IntColumn get movementMs => integer()();

  IntColumn get responseTimeMs => integer()();

  // Wrong-answer information
  TextColumn get chosenId => text().nullable()();

  TextColumn get errorClass => text().nullable()();

  // Trial position/context
  IntColumn get trialIndex => integer()();

  TextColumn get trialContext => text().nullable()();

  IntColumn get hintLevel => integer().withDefault(const Constant(0))();

  // Game-specific metrics stored as JSON
  TextColumn get metrics => text().nullable()();

  // Time information
  IntColumn get ts => integer()();

  IntColumn get hourOfDay => integer()();

  IntColumn get tzOffsetMin => integer()();

  // Sync status
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// SESSIONS

class Sessions extends Table {
  TextColumn get id => text()();

  IntColumn get startedAt => integer()();

  IntColumn get endedAt => integer().nullable()();

  TextColumn get gameIds => text()();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  IntColumn get abandonedAtMs => integer().nullable()();

  // Number of times demo/ghost hand was replayed
  IntColumn get demoReplays => integer().withDefault(const Constant(0))();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// REMINDER EVENTS

class ReminderEvents extends Table {
  TextColumn get id => text()();

  TextColumn get medicationId => text()();

  IntColumn get scheduledAt => integer()();

  IntColumn get firedAt => integer().nullable()();

  IntColumn get respondedAt => integer().nullable()();

  TextColumn get outcome => text().nullable()();

  TextColumn get channel => text()();

  IntColumn get ladderStep => integer()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// VOICE MEMOS

class VoiceMemos extends Table {
  TextColumn get id => text()();

  TextColumn get localPath => text()();

  IntColumn get durationMs => integer()();

  IntColumn get recordedAt => integer()();

  TextColumn get contextTag => text().nullable()();

  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ESCALATION REQUESTS

class EscalationRequests extends Table {
  TextColumn get id => text()();

  TextColumn get reminderEventId => text()();

  TextColumn get medicationId => text()();

  IntColumn get step => integer()();

  IntColumn get requestedAt => integer()();

  BoolColumn get cancelled => boolean().withDefault(const Constant(false))();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ABILITY STATES

class AbilityStates extends Table {
  TextColumn get domain => text()();

  RealColumn get theta => real()();

  IntColumn get nTrials => integer()();

  RealColumn get rtMeanLog => real()();

  RealColumn get rtVar => real()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {domain};
}

// PEOPLE

class People extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get relationship => text()();

  // Local absolute path
  TextColumn get photoPath => text()();

  TextColumn get voicePath => text().nullable()();

  TextColumn get memoryPrompt => text().nullable()();

  BoolColumn get isDeceased => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// MEDICATIONS

class Medications extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get dose => text()();

  TextColumn get pillPhotoPath => text().nullable()();

  TextColumn get voicePath => text().nullable()();

  // Minutes from midnight
  IntColumn get windowStartMin => integer()();

  IntColumn get windowEndMin => integer()();

  IntColumn get chosenTimeMin => integer()();

  // Example: "1,2,3,4,5,6,7"
  TextColumn get daysOfWeek => text()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// ROUTINE ITEMS

class RoutineItems extends Table {
  TextColumn get id => text()();

  IntColumn get timeMin => integer()();

  TextColumn get labelKey => text()();

  TextColumn get iconAsset => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// APP CONFIG

class AppConfigs extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
