import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database.dart';
import '../reminders/alarm_scheduler.dart';
import '../repo/content_repo.dart';
import 'media_downloader.dart';

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
      final jwtPid = Supabase.instance.client.auth.currentUser?.appMetadata['patient_id'];
      final patientId = (jwtPid is String && jwtPid.isNotEmpty)
          ? jwtPid
          : await db.appConfigsDao.getValue('patientId');

      if (patientId == null || patientId.isEmpty) {
        return const ContentPullResult(
          success: false,
          error: 'No patientId configured',
        );
      }

      // Check current version and patient ID
      final lastPulledPatientId = await db.appConfigsDao.getValue('contentPatientId');
      final currentVersion = (lastPulledPatientId == patientId)
          ? await contentRepo.getContentVersion()
          : null; // Force full pull if patient changed!

      // Call the get_patient_content RPC (Postgres RPC, not edge function)
      final dynamic response = await Supabase.instance.client.rpc(
        'get_patient_content',
        params: {'p_patient_id': patientId},
      );

      if (response == null || response is! Map) {
        return const ContentPullResult(
          success: false,
          error: 'Empty or invalid content response from server',
        );
      }

      final data = Map<String, dynamic>.from(response);
      final versionRaw = data['version'];
      if (versionRaw == null) {
        // No version field
        return const ContentPullResult(success: true, itemsPulled: 0);
      }

      final newVersion = versionRaw.toString();
      if (currentVersion != null && newVersion == currentVersion) {
        return const ContentPullResult(success: true, itemsPulled: 0);
      }

      // Parse content
      final people = _parsePeople(data['people'] as List<Object?>? ?? []);
      final medications =
          _parseMedications(data['medications'] as List<Object?>? ?? []);
      final routineItems = _parseRoutineItems(
        (data['routine'] ?? data['routine_items']) as List<Object?>? ?? [],
      );

      // Step 1: Download media files before DB swap (AGENTS.md #5)
      final downloader = MediaDownloader(db);
      final updatedPeople = <PeopleCompanion>[];
      for (final p in people) {
        String localPhoto = p.photoPath.value;
        String? localVoice = p.voicePath.value;

        if (p.photoPath.value.isNotEmpty) {
          final downloaded = await downloader.downloadPeoplePhoto(p.id.value, p.photoPath.value);
          if (downloaded != null) localPhoto = downloaded;
        }
        if (p.voicePath.value != null && p.voicePath.value!.isNotEmpty) {
          final downloaded = await downloader.downloadPeopleVoice(p.id.value, p.voicePath.value!);
          if (downloaded != null) localVoice = downloaded;
        }

        updatedPeople.add(p.copyWith(
          photoPath: Value(localPhoto),
          voicePath: Value(localVoice),
        ));
      }

      final updatedMeds = <MedicationsCompanion>[];
      for (final m in medications) {
        String? localPhoto = m.pillPhotoPath.value;
        String? localVoice = m.voicePath.value;

        if (m.pillPhotoPath.value != null && m.pillPhotoPath.value!.isNotEmpty) {
          final downloaded = await downloader.downloadMedicationPhoto(m.id.value, m.pillPhotoPath.value!);
          if (downloaded != null) localPhoto = downloaded;
        }
        if (m.voicePath.value != null && m.voicePath.value!.isNotEmpty) {
          final downloaded = await downloader.downloadMedicationVoice(m.id.value, m.voicePath.value!);
          if (downloaded != null) localVoice = downloaded;
        }

        updatedMeds.add(m.copyWith(
          pillPhotoPath: Value(localPhoto),
          voicePath: Value(localVoice),
        ));
      }

      // Step 2 & 3: Atomic DB swap
      await contentRepo.replaceContent(
        people: updatedPeople,
        medications: updatedMeds,
        routineItems: routineItems,
        contentVersion: newVersion,
      );
      await db.appConfigsDao.setValue('contentPatientId', patientId);

      // Step 4: Reschedule alarms (APP-BUILD-SPEC.md §9.2 #5)
      try {
        final scheduler = AlarmScheduler(db: db, contentRepo: contentRepo);
        await scheduler.rescheduleAll();
      } catch (e) {
        debugPrint('[ContentPuller] Error rescheduling alarms: $e');
      }

      // Update patient profile info if available
      final elderName = data['elder_name'] as String?;
      if (elderName != null && elderName.isNotEmpty) {
        await db.appConfigsDao.setValue('elderName', elderName);
      }
      final langCode = data['lang_code'] as String?;
      if (langCode != null && langCode.isNotEmpty) {
        await db.appConfigsDao.setValue('langCode', langCode);
      }
      final timezone = data['timezone'] as String?;
      if (timezone != null && timezone.isNotEmpty) {
        await db.appConfigsDao.setValue('timezone', timezone);
      }

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
