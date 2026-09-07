import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database.dart';
import '../db/dao/app_configs_dao.dart';
import '../repo/content_repo.dart';
import 'media_downloader.dart';

/// Storage buckets, per APP-BUILD-SPEC.md §7.
const String patientMediaBucket = 'patient-media';

class ContentPullException implements Exception {
  const ContentPullException(this.message);

  final String message;

  @override
  String toString() => 'ContentPullException: $message';
}

/// Outcome of one pull attempt.
class PullResult {
  const PullResult._(this.status, {this.version, this.reason});

  final String status;
  final String? version;
  final String? reason;

  factory PullResult.skipped(String reason) =>
      PullResult._('skipped', reason: reason);

  factory PullResult.upToDate(String version) =>
      PullResult._('up-to-date', version: version);

  factory PullResult.updated(String version) =>
      PullResult._('updated', version: version);

  bool get didUpdate => status == 'updated';

  @override
  String toString() =>
      'PullResult($status${version != null ? ' v$version' : ''}'
      '${reason != null ? ' - $reason' : ''})';
}

/// The remote calls a pull makes. Abstracted for testability; the Supabase
/// implementation lives below, inside `lib/core/sync/` as AGENTS.md
/// non-negotiable #1 requires.
abstract class ContentGateway {
  /// Cheap version probe — step 1, avoids pulling a full payload for nothing.
  Future<String?> fetchRemoteContentVersion(String patientId);

  /// Full payload via the `get_patient_content` RPC.
  Future<Map<String, dynamic>> fetchContent(String patientId);
}

class SupabaseContentGateway implements ContentGateway {
  const SupabaseContentGateway();

  @override
  Future<String?> fetchRemoteContentVersion(String patientId) async {
    final row = await Supabase.instance.client
        .from('patients')
        .select('content_version')
        .eq('id', patientId)
        .maybeSingle();
    final version = row?['content_version'];
    return version?.toString();
  }

  @override
  Future<Map<String, dynamic>> fetchContent(String patientId) async {
    final data = await Supabase.instance.client.rpc(
      'get_patient_content',
      params: {'p_patient_id': patientId},
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ContentPullException('unexpected get_patient_content response');
  }
}

/// Parsed payload: rows ready for Drift, plus the media they reference.
class ParsedContent {
  const ParsedContent({
    required this.people,
    required this.medications,
    required this.routineItems,
    required this.media,
    this.version,
  });

  final List<PeopleCompanion> people;
  final List<MedicationsCompanion> medications;
  final List<RoutineItemsCompanion> routineItems;
  final List<MediaRef> media;

  /// The payload's own `version`. Authoritative for the rows it carries — the
  /// probe in step 1 could be stale if content changed between the two calls.
  final String? version;
}

/// Pulls patient content and applies it in the strict order §9 mandates:
/// media to tmp -> verify -> move into place -> atomic row swap that bumps
/// `contentVersion` -> reschedule alarms.
///
/// If anything before the swap fails, the previous content set stays intact and
/// `contentVersion` is left alone, so the next run retries cleanly.
class ContentPuller {
  ContentPuller({
    required this.configs,
    required this.contentRepo,
    required this.mediaDownloader,
    this.gateway = const SupabaseContentGateway(),
    this.onContentChanged,
  });

  final AppConfigsDao configs;
  final ContentRepo contentRepo;
  final MediaDownloader mediaDownloader;
  final ContentGateway gateway;

  /// Step 5: reschedule all alarms, because medication times may have changed.
  ///
  /// Called only after a successful swap. The alarm scheduler does not exist
  /// yet (task A11), so this is left injectable and defaults to a no-op stub.
  final Future<void> Function()? onContentChanged;

  static const String patientIdKey = 'patientId';

  Future<PullResult> pull() async {
    final patientId = await configs.getValue(patientIdKey);
    if (patientId == null || patientId.isEmpty) {
      return PullResult.skipped('not paired');
    }

    // 1. Cheap version check.
    final remoteVersion =
        await gateway.fetchRemoteContentVersion(patientId);
    if (remoteVersion == null || remoteVersion.isEmpty) {
      return PullResult.skipped('no remote content version');
    }

    final localVersion = await contentRepo.getContentVersion();
    if (!_isNewer(remoteVersion, localVersion)) {
      return PullResult.upToDate(remoteVersion);
    }

    // 2. Full payload.
    final payload = await gateway.fetchContent(patientId);
    final parsed = ContentPayloadParser.parse(payload);

    // 3. Media first: download to tmp, verify, then move into place. Throws
    //    before anything is moved if a single file fails.
    final staged = await mediaDownloader.stage(parsed.media);
    await mediaDownloader.commit(staged);

    // 4. Atomic swap; contentVersion is bumped inside the same transaction, so
    //    it can never be ahead of the rows it describes. The payload's own
    //    `version` wins over the probe, which could be stale if content changed
    //    between the two calls.
    final appliedVersion = parsed.version ?? remoteVersion;
    await contentRepo.replaceContent(
      people: parsed.people,
      medications: parsed.medications,
      routineItems: parsed.routineItems,
      contentVersion: appliedVersion,
    );

    // 5. Alarms last.
    await onContentChanged?.call();

    return PullResult.updated(appliedVersion);
  }

  /// Versions are opaque strings; compare numerically when both parse as ints,
  /// otherwise treat any difference as newer.
  static bool _isNewer(String remote, String? local) {
    if (local == null || local.isEmpty) return true;
    final remoteInt = int.tryParse(remote);
    final localInt = int.tryParse(local);
    if (remoteInt != null && localInt != null) return remoteInt > localInt;
    return remote != local;
  }
}

/// Maps the `get_patient_content` payload onto Drift rows.
///
/// Field names below are taken from a real payload captured from the live
/// backend, not inferred. The payload also carries `age`, `education_years`,
/// `lang_code`, `elder_name`, `script`, `timezone` and `lang_pack_version`,
/// which pairing already writes into `AppConfigs`; refreshing them from a pull
/// is not in this task's scope.
///
/// TODO(A10+): the payload's `escalation` object has nowhere to live yet — no
/// Drift table covers it, and APP-BUILD-SPEC.md §9 did not scope storage for
/// it. §7's `AppConfigs` key list already reserves `ladderConfigJson`,
/// `primaryContactPhone` and `secondaryContactPhone`, so it can be persisted
/// there once the reminder ladder needs it. Ignored for now (it is `null` in
/// the captured payload).
class ContentPayloadParser {
  static ParsedContent parse(Map<String, dynamic> payload) {
    final people = <PeopleCompanion>[];
    final medications = <MedicationsCompanion>[];
    final routineItems = <RoutineItemsCompanion>[];
    final media = <MediaRef>[];

    var sortOrder = 0;
    for (final row in _list(payload, 'people')) {
      final id = _string(row, 'id');
      if (id == null) continue;

      final photoObject = _string(row, 'photo_path');
      final voiceObject = _string(row, 'voice_path');

      // Local paths are derived, never taken from the payload: §6 fixes the
      // layout as people/photos/{id}.jpg and people/voice/{id}.m4a.
      people.add(
        PeopleCompanion.insert(
          id: id,
          name: _string(row, 'name') ?? '',
          relationship: _string(row, 'relationship') ?? '',
          photoPath: _localPath(MediaKind.personPhoto, id),
          voicePath: Value(
            voiceObject == null ? null : _localPath(MediaKind.personVoice, id),
          ),
          memoryPrompt: Value(_string(row, 'memory_prompt')),
          isDeceased: Value(_bool(row, 'is_deceased') ?? false),
          sortOrder: _int(row, 'sort_order') ?? sortOrder,
        ),
      );
      sortOrder++;

      if (photoObject != null) {
        media.add(
          MediaRef(
            bucket: patientMediaBucket,
            objectPath: photoObject,
            kind: MediaKind.personPhoto,
            ownerId: id,
          ),
        );
      }
      if (voiceObject != null) {
        media.add(
          MediaRef(
            bucket: patientMediaBucket,
            objectPath: voiceObject,
            kind: MediaKind.personVoice,
            ownerId: id,
          ),
        );
      }
    }

    for (final row in _list(payload, 'medications')) {
      final id = _string(row, 'id');
      if (id == null) continue;

      final pillObject = _string(row, 'pill_photo_path');
      final voiceObject = _string(row, 'voice_path');

      medications.add(
        MedicationsCompanion.insert(
          id: id,
          name: _string(row, 'name') ?? '',
          dose: _string(row, 'dose') ?? '',
          pillPhotoPath: Value(
            pillObject == null
                ? null
                : _localPath(MediaKind.medicationPhoto, id),
          ),
          voicePath: Value(
            voiceObject == null
                ? null
                : _localPath(MediaKind.medicationVoice, id),
          ),
          windowStartMin: _int(row, 'window_start_min') ?? 0,
          windowEndMin: _int(row, 'window_end_min') ?? 0,
          chosenTimeMin: _int(row, 'chosen_time_min') ?? 0,
          daysOfWeek: _daysOfWeek(row) ?? '1,2,3,4,5,6,7',
          active: Value(_bool(row, 'active') ?? true),
        ),
      );

      if (pillObject != null) {
        media.add(
          MediaRef(
            bucket: patientMediaBucket,
            objectPath: pillObject,
            kind: MediaKind.medicationPhoto,
            ownerId: id,
          ),
        );
      }
      if (voiceObject != null) {
        media.add(
          MediaRef(
            bucket: patientMediaBucket,
            objectPath: voiceObject,
            kind: MediaKind.medicationVoice,
            ownerId: id,
          ),
        );
      }
    }

    for (final row in _list(payload, 'routine')) {
      final id = _string(row, 'id');
      if (id == null) continue;

      routineItems.add(
        RoutineItemsCompanion.insert(
          id: id,
          timeMin: _int(row, 'time_min') ?? 0,
          labelKey: _string(row, 'label_key') ?? '',
          iconAsset: _string(row, 'icon_asset') ?? '',
        ),
      );
    }

    return ParsedContent(
      people: people,
      medications: medications,
      routineItems: routineItems,
      media: media,
      // Arrives as an int in the live payload.
      version: payload['version']?.toString(),
    );
  }

  /// Local media paths are relative to the directories §6 fixes; the absolute
  /// prefix is resolved at read time by `FilePaths`.
  static String _localPath(MediaKind kind, String id) => switch (kind) {
        MediaKind.personPhoto => 'people/photos/$id.jpg',
        MediaKind.personVoice => 'people/voice/$id.m4a',
        MediaKind.medicationPhoto => 'medications/photos/$id.jpg',
        MediaKind.medicationVoice => 'medications/voice/$id.m4a',
      };

  /// The live payload sends `"1,2,3,4,5,6,7"`; a JSON array is also accepted
  /// because `Medications.daysOfWeek` stores the comma form either way.
  static String? _daysOfWeek(Map<String, dynamic> row) {
    final value = row['days_of_week'];
    if (value is List) return value.join(',');
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static List<Map<String, dynamic>> _list(
    Map<String, dynamic> payload,
    String key,
  ) {
    final value = payload[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  /// Nullable fields (`voice_path`, `pill_photo_path`, `memory_prompt`) arrive
  /// as JSON null in the live payload, so null and empty are both "absent".
  static String? _string(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static int? _int(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}');
  }

  static bool? _bool(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }
}
