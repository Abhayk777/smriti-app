import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
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

/// Pushes unsynced trial events, sessions, and reminder events to Supabase.
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

  /// Pushes all unsynced trial events to Supabase.
  Future<EventPushResult> push() async {
    try {
      final pid = await _getPatientId();
      int eventsPushed = 0;
      int sessionsPushed = 0;
      int reminderEventsPushed = 0;
      
      // Push unsynced trial events
      final unsyncedTrials = await eventRepo.unsyncedTrials(limit: 500);
      if (unsyncedTrials.isNotEmpty) {
        final rows = unsyncedTrials.map((t) => {
          ..._trialEventToMap(t),
          'patient_id': pid,
        }).toList();
        
        await Supabase.instance.client.from('events').upsert(
          rows,
          onConflict: 'id',
          ignoreDuplicates: true,
        );
        
        // Mark as synced ONLY if the upsert succeeded
        // Per AGENTS.md #4: We don't .select() to verify, we assume success
        await eventRepo.markTrialsSynced(
          unsyncedTrials.map((t) => t.id).toList(),
        );
        
        eventsPushed = unsyncedTrials.length;
      }
      
      // Push unsynced sessions
      final unsyncedSessions = await eventRepo.unsyncedSessions(limit: 200);
      if (unsyncedSessions.isNotEmpty) {
        final rows = unsyncedSessions.map((s) => {
          ..._sessionToMap(s),
          'patient_id': pid,
        }).toList();
        
        await Supabase.instance.client.from('sessions').upsert(
          rows,
          onConflict: 'id',
          ignoreDuplicates: true,
        );
        
        await eventRepo.markSessionsSynced(
          unsyncedSessions.map((s) => s.id).toList(),
        );
        
        sessionsPushed = unsyncedSessions.length;
      }
      
      // Push unsynced reminder events
      final unsyncedReminderEvents = await eventRepo.unsyncedReminderEvents(limit: 200);
      if (unsyncedReminderEvents.isNotEmpty) {
        final rows = unsyncedReminderEvents.map((r) => {
          ..._reminderEventToMap(r),
          'patient_id': pid,
        }).toList();
        
        await Supabase.instance.client.from('reminder_events').upsert(
          rows,
          onConflict: 'id',
          ignoreDuplicates: true,
        );
        
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
    return {
      'id': event.id,
      'session_id': event.sessionId,
      'game_id': event.gameId,
      'domain': event.domain,
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
      'metrics': event.metrics,
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
