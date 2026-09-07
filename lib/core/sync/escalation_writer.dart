import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database.dart';
import '../repo/event_repo.dart';

/// Result of an escalation write operation.
class EscalationWriteResult {
  const EscalationWriteResult({
    required this.escalationsWritten,
    this.error,
  });

  final int escalationsWritten;
  final String? error;

  bool get success => error == null;
}

/// Writes unsynced escalation requests to Supabase.
///
/// Escalation IDs are deterministic: `{reminderEventId}_{step}` as per AGENTS.md #3.
/// Only this class may import supabase_flutter outside core/auth (AGENTS.md #1).
class EscalationWriter {
  EscalationWriter({
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

  /// Pushes all unsynced escalation requests to Supabase.
  ///
  /// The server-side escalation-worker Edge Function will handle placing
  /// the real phone call. This is already proven working end-to-end.
  Future<EscalationWriteResult> flush() async {
    try {
      final pid = await _getPatientId();
      final unsyncedEscalations = await eventRepo.unsyncedEscalations(limit: 200);
      
      if (unsyncedEscalations.isEmpty) {
        return const EscalationWriteResult(escalationsWritten: 0);
      }
      
      final rows = unsyncedEscalations.map((e) => {
        ..._escalationToMap(e),
        'patient_id': pid,
      }).toList();
      
      await Supabase.instance.client.from('escalations').upsert(
        rows,
        onConflict: 'id',
        ignoreDuplicates: true,
      );
      
      // Mark as synced
      await eventRepo.markEscalationsSynced(
        unsyncedEscalations.map((e) => e.id).toList(),
      );
      
      return EscalationWriteResult(
        escalationsWritten: unsyncedEscalations.length,
      );
      
    } catch (e) {
      return EscalationWriteResult(
        escalationsWritten: 0,
        error: e.toString(),
      );
    }
  }

  /// Creates an escalation request and syncs it.
  ///
  /// Called by the reminder isolate when ladder Step 2 is reached.
  Future<String?> createAndSync({
    required String reminderEventId,
    required String medicationId,
    required int step,
  }) async {
    try {
      // The escalation ID is deterministic per AGENTS.md #3
      final escalationId = '${reminderEventId}_$step';
      
      final pid = await _getPatientId();
      
      // Insert locally first
      await eventRepo.insertEscalation(
        EscalationRequestsCompanion.insert(
          id: escalationId,
          reminderEventId: reminderEventId,
          medicationId: medicationId,
          step: step,
          requestedAt: DateTime.now().millisecondsSinceEpoch,
          cancelled: Value(false),
          synced: Value(false),
        ),
      );
      
      // Now push to Supabase
      await Supabase.instance.client.from('escalations').upsert({
        'id': escalationId,
        'reminder_event_id': reminderEventId,
        'medication_id': medicationId,
        'step': step,
        'status': 'requested',
        'requested_at': DateTime.now().millisecondsSinceEpoch,
        'patient_id': pid,
      }, onConflict: 'id', ignoreDuplicates: true);
      
      // Mark as synced locally
      await eventRepo.markEscalationsSynced([escalationId]);
      
      return escalationId;
      
    } catch (_) {
      // If sync fails, the local row will be synced on the next flush
      // The escalation will still be in the local DB
      return null;
    }
  }

  /// Converts an EscalationRequest to a Map for Supabase upsert.
  Map<String, dynamic> _escalationToMap(EscalationRequest escalation) {
    return {
      'id': escalation.id,
      'reminder_event_id': escalation.reminderEventId,
      'medication_id': escalation.medicationId,
      'step': escalation.step,
      'requested_at': escalation.requestedAt,
      'cancelled': escalation.cancelled,
    };
  }
}
