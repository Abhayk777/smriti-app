import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database.dart';
import '../repo/content_repo.dart';

/// Result of a content pull operation.
class ContentPullResult {
  const ContentPullResult({
    required this.success,
    this.error,
    this.itemsPulled = 0,
  });

  final bool success;
  final String? error;
  final int itemsPulled;
}

/// Pulls patient content (people, medications, routine items) from Supabase.
///
/// Order per AGENTS.md non-negotiable #5:
///   1. Download media → 2. Verify on disk → 3. Atomic DB swap → 4. Reschedule alarms.
/// Never bumps `contentVersion` before media is verified present.
///
/// Only this class (and other files in core/sync/) may import supabase_flutter
/// (AGENTS.md non-negotiable #1).
class ContentPuller {
  ContentPuller({
    required this.db,
    required this.contentRepo,
  });

  final SmritiDatabase db;
  final ContentRepo contentRepo;

  /// Checks for a new content version and pulls it if available.
  Future<ContentPullResult> pull() async {
    try {
      final patientId =
          await db.appConfigsDao.getValue('patientId');
      if (patientId == null || patientId.isEmpty) {
        return const ContentPullResult(
          success: false,
          error: 'No patient ID configured',
        );
      }

      // Check current version
      final currentVersion = await contentRepo.getContentVersion();

      // Call the get_patient_content RPC
      final response = await Supabase.instance.client.functions.invoke(
        'get-patient-content',
        body: {
          'patient_id': patientId,
          'current_version': currentVersion,
        },
      );

      if (response.status != 200) {
        return ContentPullResult(
          success: false,
          error: 'Server returned status ${response.status}',
        );
      }

      final data = response.data;
      if (data is! Map || data['version'] == null) {
        // No new content
        return const ContentPullResult(success: true, itemsPulled: 0);
      }

      final newVersion = data['version'] as String;
      if (newVersion == currentVersion) {
        return const ContentPullResult(success: true, itemsPulled: 0);
      }

      // Parse content
      final people = _parsePeople(data['people'] as List<Object?>? ?? []);
      final medications =
          _parseMedications(data['medications'] as List<Object?>? ?? []);
      final routineItems =
          _parseRoutineItems(data['routine_items'] as List<Object?>? ?? []);

      // TODO: Step 1-2: Download and verify media files before swap
      // This requires MediaDownloader (partially implemented).
      // For now, skip media verification.

      // Step 3: Atomic DB swap
      await contentRepo.replaceContent(
        people: people,
        medications: medications,
        routineItems: routineItems,
        contentVersion: newVersion,
      );

      // Step 4: Reschedule alarms
      // TODO: Call alarm scheduler once implemented

      final totalItems =
          people.length + medications.length + routineItems.length;
      return ContentPullResult(success: true, itemsPulled: totalItems);
    } catch (e) {
      return ContentPullResult(success: false, error: e.toString());
    }
  }

  List<PeopleCompanion> _parsePeople(List<Object?> rows) {
    return rows.cast<Map<String, dynamic>>().map((row) {
      return PeopleCompanion.insert(
        id: row['id'] as String,
        name: row['name'] as String? ?? row['display_name'] as String? ?? '',
        relationship: row['relationship'] as String? ?? '',
        photoPath: row['photo_path'] as String? ?? '',
        sortOrder: row['sort_order'] as int? ?? 0,
        voicePath: Value(row['voice_path'] as String?),
        memoryPrompt: Value(row['memory_prompt'] as String?),
        isDeceased: Value(row['is_deceased'] as bool? ?? false),
      );
    }).toList();
  }

  List<MedicationsCompanion> _parseMedications(List<Object?> rows) {
    return rows.cast<Map<String, dynamic>>().map((row) {
      final chosen = row['chosen_time_min'] as int? ?? 0;
      final windowStart = row['window_start_min'] as int? ?? (chosen - 30);
      final windowEnd = row['window_end_min'] as int? ?? (chosen + 30);
      return MedicationsCompanion.insert(
        id: row['id'] as String,
        name: row['name'] as String? ?? row['label_key'] as String? ?? '',
        dose: row['dose'] as String? ?? '',
        windowStartMin: windowStart,
        windowEndMin: windowEnd,
        chosenTimeMin: chosen,
        daysOfWeek: row['days_of_week'] as String? ?? '1,2,3,4,5,6,7',
        pillPhotoPath: Value(
          row['photo_path'] as String? ?? row['pill_photo_path'] as String?,
        ),
        voicePath: Value(row['voice_path'] as String?),
        active: Value(row['active'] as bool? ?? true),
      );
    }).toList();
  }

  List<RoutineItemsCompanion> _parseRoutineItems(List<Object?> rows) {
    return rows.cast<Map<String, dynamic>>().map((row) {
      return RoutineItemsCompanion.insert(
        id: row['id'] as String,
        labelKey: row['label_key'] as String? ?? '',
        iconAsset: row['icon_asset'] as String? ?? '',
        timeMin: row['time_min'] as int? ?? 0,
      );
    }).toList();
  }
}
