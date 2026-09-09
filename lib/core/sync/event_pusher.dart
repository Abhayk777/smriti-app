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
  }) : _patientId = patientId;

  final SmritiDatabase db;
  final EventRepo eventRepo;
  String? _patientId;

  /// Patient ID from AppConfigs - will be read when needed
  Future<String> _getPatientId() async {
    return _patientId ??= 
        await db.appConfigsDao.getValue('patientId') ?? 
        (throw Exception('No patientId configured'));
  }

  /// Pushes all unsynced trial events to supabase.Supabase.
  Future<EventPushResult> push() async {
    try {
      final pid = await _getPatientId();
      final client = supabase.Supabase.instance.client;
      int eventsPushed = 0;
      int sessionsPushed = 0;
      int reminderEventsPushed = 0;
      
      // 1. Push unsynced sessions FIRST (events reference session_id)
      final unsyncedSessions = await eventRepo.unsyncedSessions(limit: 200);
      if (unsyncedSessions.isNotEmpty) {
        final rows = unsyncedSessions.map((s) => {
          ..._sessionToMap(s),
          'patient_id': pid,
        }).toList();
        
        await client.from('sessions').insert(rows);
        
        await eventRepo.markSessionsSynced(
          unsyncedSessions.map((s) => s.id).toList(),
        );
        
        sessionsPushed = unsyncedSessions.length;
      }

      // 2. Push unsynced trial events
      final unsyncedTrials = await eventRepo.unsyncedTrials(limit: 500);
      if (unsyncedTrials.isNotEmpty) {
        final rows = unsyncedTrials.map((t) => {
          ..._trialEventToMap(t),
          'patient_id': pid,
        }).toList();
        
        await client.from('events').insert(rows);
        
        // Mark as synced ONLY if the insert succeeded
        // Per AGENTS.md #4: We don't .select() to verify, we assume success
        await eventRepo.markTrialsSynced(
          unsyncedTrials.map((t) => t.id).toList(),
        );
        
        eventsPushed = unsyncedTrials.length;
      }
      
      // 3. Push unsynced reminder events
      final unsyncedReminderEvents = await eventRepo.unsyncedReminderEvents(limit: 200);
      if (unsyncedReminderEvents.isNotEmpty) {
        final rows = unsyncedReminderEvents.map((r) => {
          ..._reminderEventToMap(r),
          'patient_id': pid,
        }).toList();
        
        await client.from('reminder_events').insert(rows);
        
        await eventRepo.markReminderEventsSynced(
          unsyncedReminderEvents.map((r) => r.id).toList(),
        );
        
        reminderEventsPushed = unsyncedReminderEvents.length;
      }
      
      return EventPushResult(
        eventsPushed: eventsPushed,
        sessionsPushed: sessionsPushed,
        reminderEventsPushed: reminderEventsPushed,
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
      'channel': event.channel,
      'ladder_step': event.ladderStep,
    };
  }
}
