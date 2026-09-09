import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../db/app_database.dart';
import '../db/database.dart';
import '../repo/content_repo.dart';
import '../repo/event_repo.dart';
import '../repo/memo_repo.dart';
import 'content_puller.dart';
import 'event_pusher.dart';
import 'memo_uploader.dart';
import 'escalation_writer.dart';
import 'heartbeat.dart';

/// Triggers for sync operations.
enum SyncTrigger {
  /// Periodic sync triggered by Workmanager
  periodic,
  /// Connectivity was regained after being offline
  connectivityRegained,
  /// App came to foreground
  appForeground,
  /// Session just ended
  sessionEnded,
  /// Manual trigger (e.g., from diagnostics screen)
  manual,
}

/// Result of a complete sync operation.
class SyncResult {
  const SyncResult._({
    required this.ok,
    required this.errors,
    required this.trigger,
  });

  const SyncResult.ok() : this._(ok: true, errors: const [], trigger: null);
  SyncResult.skipped(String reason) : this._(ok: true, errors: [reason], trigger: null);
  SyncResult.partial(List<String> errors, {SyncTrigger? trigger})
      : this._(ok: false, errors: errors, trigger: trigger);

  final bool ok;
  final List<String> errors;
  final SyncTrigger? trigger;

  bool get hasErrors => errors.isNotEmpty;
  String get errorSummary => errors.join('; ');
}

/// Orchestrates all sync operations: push and pull.
///
/// Runs on:
/// - Connectivity regained
/// - Every 15 minutes via Workmanager
/// - App foreground
/// - Immediately after a session ends
///
/// Each sync stage is independently wrapped per APP-BUILD-SPEC.md §9.4:
/// "A content-pull failure must never prevent event upload."
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.eventRepo,
    required this.memoRepo,
    required this.contentRepo,
    Duration syncInterval = const Duration(minutes: 15),
  })  : _syncInterval = syncInterval;

  final SmritiDatabase db;
  final EventRepo eventRepo;
  final MemoRepo memoRepo;
  final ContentRepo contentRepo;
  final Duration _syncInterval;

  // State
  bool _running = false;
  SyncTrigger? _currentTrigger;
  DateTime? _lastSyncAt;

  // Lazy-initialized sync components
  ContentPuller? _contentPuller;
  EventPusher? _eventPusher;
  MemoUploader? _memoUploader;
  EscalationWriter? _escalationWriter;
  Heartbeat? _heartbeat;

  /// Minimum interval between syncs to avoid thrashing.
  static const Duration _minInterval = Duration(minutes: 2);

  /// Whether a sync is currently running.
  bool get isRunning => _running;

  /// Current sync trigger being processed, if any.
  SyncTrigger? get currentTrigger => _currentTrigger;

  /// Configured sync interval.
  Duration get syncInterval => _syncInterval;

  /// Last sync timestamp.
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Initializes the sync engine.
  ///
  /// Sets up connectivity listener and periodic sync via Workmanager.
  Future<void> init() async {
    // Setup connectivity listener
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        run(trigger: SyncTrigger.connectivityRegained);
      }
    });

    // Setup periodic sync via Workmanager
    // Note: This requires the callback to be set up in main.dart
    // and the package to be initialized
  }

  static SyncEngine? _defaultInstance;
  static SyncEngine get defaultInstance {
    return _defaultInstance ??= SyncEngine(
      db: appDatabase,
      eventRepo: EventRepo(appDatabase),
      memoRepo: MemoRepo(appDatabase),
      contentRepo: ContentRepo(appDatabase),
    );
  }

  /// Resets the default instance and internal state.
  static void resetDefaultInstance() {
    _defaultInstance?.reset();
    _defaultInstance = null;
  }

  /// Starts a sync operation if not already running.
  ///
  /// Returns immediately with [SyncResult.skipped] if:
  /// - Already running
  /// - Offline
  /// - Not authenticated
  ///
  /// Otherwise, runs all sync stages and returns the result.
  Future<SyncResult> run({SyncTrigger trigger = SyncTrigger.periodic}) async {
    // Guard against concurrent syncs
    if (_running) {
      return SyncResult.skipped('already running');
    }

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      await _recordSyncError('offline');
      return SyncResult.skipped('offline');
    }

    // Check authentication - if null, try to restore device session using deviceRefreshToken
    if (Supabase.instance.client.auth.currentSession == null) {
      final token = await db.appConfigsDao.getValue('deviceRefreshToken');
      if (token != null && token.isNotEmpty) {
        try {
          await Supabase.instance.client.auth.setSession(token);
        } catch (e) {
          await _recordSyncError('setSession failed: $e');
        }
      } else {
        await _recordSyncError('no deviceRefreshToken in local DB');
      }
    }

    if (Supabase.instance.client.auth.currentSession == null) {
      final error = await getLastSyncError() ?? 'not authed';
      return SyncResult.skipped(error);
    }

    // Check rate limiting (exempt manual and sessionEnded triggers)
    if (_lastSyncAt != null &&
        trigger != SyncTrigger.manual &&
        trigger != SyncTrigger.sessionEnded) {
      final sinceLast = DateTime.now().difference(_lastSyncAt!);
      if (sinceLast < _minInterval) {
        return SyncResult.skipped('rate limited');
      }
    }

    _running = true;
    _currentTrigger = trigger;

    try {
      final errors = <String>[];

      // Initialize lazy components
      _eventPusher ??= EventPusher(db: db, eventRepo: eventRepo);
      _memoUploader ??= MemoUploader(db: db, memoRepo: memoRepo);
      _escalationWriter ??= EscalationWriter(db: db, eventRepo: eventRepo);
      _heartbeat ??= Heartbeat(db: db, eventRepo: eventRepo);
      _contentPuller ??= ContentPuller(db: db, contentRepo: contentRepo);

      // Run each sync stage independently
      try {
        final result = await _eventPusher!.push();
        if (!result.success) {
          errors.add('events: ${result.error}');
        }
      } catch (e) {
        errors.add('events: $e');
      }

      try {
        final result = await _escalationWriter!.flush();
        if (!result.success) {
          errors.add('escalations: ${result.error}');
        }
      } catch (e) {
        errors.add('escalations: $e');
      }

      try {
        final result = await _memoUploader!.upload();
        if (!result.success) {
          errors.add('memos: ${result.error}');
        }
      } catch (e) {
        errors.add('memos: $e');
      }

      try {
        final result = await _contentPuller!.pull();
        if (!result.success) {
          errors.add('content: ${result.error}');
        }
      } catch (e) {
        errors.add('content: $e');
      }

      try {
        await _heartbeat!.send();
      } catch (e) {
        errors.add('heartbeat: $e');
      }

      // Update last sync timestamp
      _lastSyncAt = DateTime.now();
      await db.appConfigsDao.setValue(
        'lastSyncAt',
        _lastSyncAt!.millisecondsSinceEpoch.toString(),
      );

      // Clear last sync error on success
      if (errors.isEmpty) {
        await db.appConfigsDao.setValue('lastSyncError', '');
      }

      _running = false;
      _currentTrigger = null;

      if (errors.isEmpty) {
        return SyncResult.ok();
      } else {
        return SyncResult.partial(errors, trigger: trigger);
      }

    } catch (e) {
      _running = false;
      _currentTrigger = null;
      await _recordSyncError(e.toString());
      return SyncResult.partial([e.toString()], trigger: trigger);
    }
  }

  /// Records a sync error in AppConfigs.
  Future<void> _recordSyncError(String error) async {
    await db.appConfigsDao.setValue('lastSyncError', error);
  }

  /// Registers the periodic sync callback with Workmanager.
  ///
  /// Call this from main.dart after Workmanager is initialized.
  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      'sync',
      'smriti_sync',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      initialDelay: const Duration(minutes: 15),
    );
  }

  /// The callback for Workmanager periodic sync.
  ///
  /// This must be a top-level function.
  @pragma('vm:entry-point')
  static Future<void> _syncCallback() async {
    // Note: This callback cannot access the main app state.
    // In a full implementation, we would need to:
    // 1. Initialize Supabase
    // 2. Open a database connection
    // 3. Run the sync
    // For now, the sync will be triggered by the connectivity listener
    // and app foreground events, which can access the main state.
  }

  /// Requests an immediate sync (e.g., from diagnostics screen).
  Future<SyncResult> requestImmediateSync() {
    return run(trigger: SyncTrigger.manual);
  }

  /// Gets the last sync error from AppConfigs.
  Future<String?> getLastSyncError() async {
    return await db.appConfigsDao.getValue('lastSyncError');
  }

  /// Resets sync state.
  Future<void> reset() async {
    _running = false;
    _currentTrigger = null;
    _lastSyncAt = null;
    _eventPusher = null;
    _memoUploader = null;
    _escalationWriter = null;
    _heartbeat = null;
    _contentPuller = null;
  }
}
