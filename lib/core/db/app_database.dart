import 'database.dart';

/// Process-wide handle to the one open database.
///
/// APP-BUILD-SPEC.md §4 has the UI reaching repositories through Riverpod
/// providers, but `flutter_riverpod` is not wired yet. This is the smallest
/// thing that lets screens reach Drift without each one opening its own
/// connection; replace it with a provider when Riverpod lands.
///
/// Alarm isolates must NOT use this — they cannot see the main isolate's state
/// and must open their own connection via `SmritiDatabase.connect`
/// (AGENTS.md non-negotiable #6).
SmritiDatabase? _instance;

SmritiDatabase get appDatabase => _instance ??= SmritiDatabase();

/// Overrides the shared instance. Tests use this to substitute an in-memory
/// database; production code never calls it.
set appDatabase(SmritiDatabase db) => _instance = db;
