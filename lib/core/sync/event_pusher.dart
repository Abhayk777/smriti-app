import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../db/database.dart';
import '../repo/event_repo.dart';

/// Result of an event push operation.
class EventPushResult {
  const EventPushResult({
    required this.eventsPushed,
    required this.sessionsPushed,
    required this.reminderEventsPushed,
    this.error,
  });

  final int eventsPushed;
  final int sessionsPushed;
  final int reminderEventsPushed;
  final String? error;

  bool get success => error == null;
  int get totalPushed => eventsPushed + sessionsPushed + reminderEventsPushed;
}

/// Pushes unsynced trial events, sessions, and reminder events to supabase.Supabase.
///
/// Per AGENTS.md non-negotiable #4: Device writes never use `.select()` or
/// chain a `RETURNING`. Uses bare `.insert()` / `.upsert()` with onConflict.
/// Only this class may import supabase_flutter outside core/auth (AGENTS.md #1).
class EventPusher {
  EventPusher({
    required this.db,
    required this.eventRepo,
    String? patientId,
  });

  final SmritiDatabase db;
  final EventRepo eventRepo;

  /// Patient ID from AppConfigs - will be read when needed
  Future<String> _getPatientId() async {
    final jwtPid = supabase.Supabase.instance.client.auth.currentUser?.appMetadata['patient_id'];
    if (jwtPid is String && jwtPid.isNotEmpty) {
      return jwtPid;
    }
    final configPid = await db.appConfigsDao.getValue('patientId');
    if (configPid != null && configPid.isNotEmpty) {
      return configPid;
    }
    throw Exception('No patientId configured');
  }

  /// Pushes all unsynced trial events to supabase.Supabase.
  Future<EventPushResult> push() async {
    try {
      final pid = await _getPatientId();
      final client = supabase.Supabase.instance.client;
      int eventsPushed = 0;
      int sessionsPushed = 0;
      int reminderEventsPushed = 0;
      final rejections = <String>[];

      // 1. Push unsynced sessions FIRST (events reference session_id)
      final unsyncedSessions = await eventRepo.unsyncedSessions(limit: 200);
      if (unsyncedSessions.isNotEmpty) {
        final rows = unsyncedSessions.map((s) => {
          ..._sessionToMap(s),
          'patient_id': pid,
        }).toList();

        final result = await _insertRows(client, 'sessions', rows);
        await eventRepo.markSessionsSynced(result.synced);
        rejections.addAll(result.rejections);
        sessionsPushed = result.synced.length;
      }

      // 2. Push unsynced trial events
      final unsyncedTrials = await eventRepo.unsyncedTrials(limit: 500);
      if (unsyncedTrials.isNotEmpty) {
        final rows = unsyncedTrials.map((t) => {
          ..._trialEventToMap(t),
          'patient_id': pid,
        }).toList();

        // Mark as synced ONLY if the insert succeeded
        // Per AGENTS.md #4: We don't .select() to verify, we assume success
        final result = await _insertRows(client, 'events', rows);
        await eventRepo.markTrialsSynced(result.synced);
        rejections.addAll(result.rejections);
        eventsPushed = result.synced.length;
      }

      // 3. Push unsynced reminder events
      final unsyncedReminderEvents = await eventRepo.unsyncedReminderEvents(limit: 200);
      if (unsyncedReminderEvents.isNotEmpty) {
        final rows = unsyncedReminderEvents.map((r) => {
          ..._reminderEventToMap(r),
          'patient_id': pid,
        }).toList();

        final result = await _insertRows(client, 'reminder_events', rows);
        await eventRepo.markReminderEventsSynced(result.synced);
        rejections.addAll(result.rejections);
        reminderEventsPushed = result.synced.length;
      }

      return EventPushResult(
        eventsPushed: eventsPushed,
        sessionsPushed: sessionsPushed,
        reminderEventsPushed: reminderEventsPushed,
        error: rejections.isEmpty
            ? null
            : 'server refused ${rejections.length} row(s): '
                '${rejections.take(3).join('; ')}',
      );
      
    } catch (e) {
      return EventPushResult(
        eventsPushed: 0,
        sessionsPushed: 0,
        reminderEventsPushed: 0,
        error: e.toString(),
      );
    }
  }

  /// Postgres unique_violation.
  static const String _uniqueViolation = '23505';

  /// Postgres error classes 22 (data exception: bad value, invalid enum
  /// text) and 23 (integrity constraint: check, not-null, foreign key,
  /// unique). These are about a specific row, not the connection or auth.
  static bool _isRowDataError(supabase.PostgrestException e) {
    final code = e.code;
    return code != null && (code.startsWith('22') || code.startsWith('23'));
  }

  /// Inserts [rows]. Returns the ids now on the server, plus the server's
  /// reason for each row it refused.
  ///
  /// A single bad row used to fail the whole batch and block every later
  /// upload forever. When the batch is refused for a row-data reason, retry
  /// row by row: a duplicate id (e.g. a ReminderEvent older builds edited
  /// after uploading) counts as synced; any other refused row stays unsynced
  /// and is reported, without holding back the rest. Network, auth and RLS
  /// errors still abort as before. Still a plain insert: the device's RLS
  /// identity is insert-only (AGENTS.md #4).
  Future<({List<String> synced, List<String> rejections})> _insertRows(
    supabase.SupabaseClient client,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      await client.from(table).insert(rows);
      return (
        synced: rows.map((r) => r['id'] as String).toList(),
        rejections: const <String>[],
      );
    } on supabase.PostgrestException catch (e) {
      if (!_isRowDataError(e)) rethrow;
    }

    final synced = <String>[];
    final rejections = <String>[];
    for (final row in rows) {
      final id = row['id'] as String;
      try {
        await client.from(table).insert(row);
        synced.add(id);
      } on supabase.PostgrestException catch (e) {
        if (e.code == _uniqueViolation) {
          synced.add(id);
        } else if (_isRowDataError(e)) {
          rejections.add('$table $id: ${e.code} ${e.message}');
        } else {
          rethrow;
        }
      }
    }
    return (synced: synced, rejections: rejections);
  }

  /// Converts a TrialEvent to a Map for Supabase upsert.
  Map<String, dynamic> _trialEventToMap(TrialEvent event) {
    dynamic metricsJson;
    if (event.metrics != null && event.metrics!.isNotEmpty) {
      try {
        metricsJson = jsonDecode(event.metrics!);
      } catch (_) {
        metricsJson = null;
      }
    }

    return {
      'id': event.id,
      'session_id': event.sessionId,
      'game_id': event.gameId,
      'domain': event.domain.toLowerCase(),
      'item_id': event.itemId,
      'item_difficulty': event.itemDifficulty,
      'theta_before': event.thetaBefore,
      'correct': event.correct,
      'initiation_ms': event.initiationMs,
      'movement_ms': event.movementMs,
      'response_time_ms': event.responseTimeMs,
      'chosen_id': event.chosenId,
      'error_class': event.errorClass,
      'trial_index': event.trialIndex,
      'trial_context': event.trialContext,
      'hint_level': event.hintLevel,
      'metrics': metricsJson,
      'ts': event.ts,
      'hour_of_day': event.hourOfDay,
      'tz_offset_min': event.tzOffsetMin,
    };
  }

  /// Converts a Session to a Map for Supabase upsert.
  Map<String, dynamic> _sessionToMap(Session session) {
    return {
      'id': session.id,
      'started_at': session.startedAt,
      'ended_at': session.endedAt,
      'game_ids': session.gameIds,
      'completed': session.completed,
      'abandoned_at_ms': session.abandonedAtMs,
      'demo_replays': session.demoReplays,
    };
  }

  /// Converts a ReminderEvent to a Map for Supabase upsert.
  Map<String, dynamic> _reminderEventToMap(ReminderEvent event) {
    return {
      'id': event.id,
      'medication_id': event.medicationId,
      'scheduled_at': event.scheduledAt,
      'fired_at': event.firedAt,
      'responded_at': event.respondedAt,
      'outcome': event.outcome,
      // Older builds wrote 'fullscreen' for device-shown reminders; the
      // backend contract (APP-BUILD-SPEC.md §10) uses 'in_app'.
      'channel': event.channel == 'fullscreen' ? 'in_app' : event.channel,
      'ladder_step': event.ladderStep,
    };
  }
}
