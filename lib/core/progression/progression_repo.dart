import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'progression_config.dart';
import 'progression_state.dart';

/// Optional per-device overrides of a handful of [ProgressionConfig]
/// constants, set from the caregiver-only Diagnostics screen
/// (docs/PROGRESSION_PLAN.md §4.6, §11). Any field left null falls back to
/// the fixed constant.
class ProgressionSettings {
  const ProgressionSettings({
    this.dailyRestMinutes,
    this.nudgeRepeatPlays,
    this.nudgeWindowDays,
    this.reviewEveryDays,
  });

  final int? dailyRestMinutes;
  final int? nudgeRepeatPlays;
  final int? nudgeWindowDays;
  final int? reviewEveryDays;

  int get effectiveDailyRestMinutes =>
      dailyRestMinutes ?? ProgressionConfig.dailyRestMinutes;
  int get effectiveNudgeRepeatPlays =>
      nudgeRepeatPlays ?? ProgressionConfig.nudgeRepeatPlays;
  int get effectiveNudgeWindowDays =>
      nudgeWindowDays ?? ProgressionConfig.nudgeWindowDays;
  int get effectiveReviewEveryDays =>
      reviewEveryDays ?? ProgressionConfig.reviewEveryDays;

  ProgressionSettings copyWith({
    int? dailyRestMinutes,
    int? nudgeRepeatPlays,
    int? nudgeWindowDays,
    int? reviewEveryDays,
  }) {
    return ProgressionSettings(
      dailyRestMinutes: dailyRestMinutes ?? this.dailyRestMinutes,
      nudgeRepeatPlays: nudgeRepeatPlays ?? this.nudgeRepeatPlays,
      nudgeWindowDays: nudgeWindowDays ?? this.nudgeWindowDays,
      reviewEveryDays: reviewEveryDays ?? this.reviewEveryDays,
    );
  }

  Map<String, Object?> toJson() => {
        'dailyRestMinutes': dailyRestMinutes,
        'nudgeRepeatPlays': nudgeRepeatPlays,
        'nudgeWindowDays': nudgeWindowDays,
        'reviewEveryDays': reviewEveryDays,
      };

  static ProgressionSettings fromJson(Object? json) {
    if (json is! Map) return const ProgressionSettings();
    try {
      return ProgressionSettings(
        dailyRestMinutes: (json['dailyRestMinutes'] as num?)?.toInt(),
        nudgeRepeatPlays: (json['nudgeRepeatPlays'] as num?)?.toInt(),
        nudgeWindowDays: (json['nudgeWindowDays'] as num?)?.toInt(),
        reviewEveryDays: (json['reviewEveryDays'] as num?)?.toInt(),
      );
    } catch (_) {
      return const ProgressionSettings();
    }
  }
}

/// Reads and writes all progression state, stored as JSON text values in the
/// existing `AppConfigs` table (docs/PROGRESSION_PLAN.md §4.3). No schema
/// change; this is the only place that touches these keys.
///
/// Every read falls back to a sensible default rather than throwing, so a
/// corrupt or missing value can never crash a screen.
class ProgressionRepo {
  ProgressionRepo(this.db);

  final SmritiDatabase db;

  static const String _keyPrefix = 'progression.v1';
  static const String _nudgeKey = '$_keyPrefix.nudge';
  static const String _restKey = '$_keyPrefix.rest';
  static const String _settingsKey = '$_keyPrefix.settings';

  static String _gameKey(String gameId) => '$_keyPrefix.game.$gameId';

  Future<GameProgress> getGameProgress(String gameId) async {
    final raw = await db.appConfigsDao.getValue(_gameKey(gameId));
    if (raw == null) return GameProgress.fresh(gameId);
    return GameProgress.fromJson(gameId, _tryDecode(raw));
  }

  Future<void> saveGameProgress(GameProgress progress) async {
    await db.appConfigsDao.setValue(
      _gameKey(progress.gameId),
      jsonEncode(progress.toJson()),
    );
  }

  Future<NudgeState> getNudgeState() async {
    final raw = await db.appConfigsDao.getValue(_nudgeKey);
    if (raw == null) return NudgeState.initial();
    return NudgeState.fromJson(_tryDecode(raw));
  }

  Future<void> saveNudgeState(NudgeState state) async {
    await db.appConfigsDao.setValue(_nudgeKey, jsonEncode(state.toJson()));
  }

  /// [todayKey] is the caller's local 'yyyy-MM-dd' for "now"; a stored state
  /// from an earlier day is not returned as-is by this method (callers are
  /// expected to compare `dayKey` themselves, since only they know whether a
  /// fresh day should reset the threshold using the current settings).
  Future<RestState> getRestState(String todayKey) async {
    final raw = await db.appConfigsDao.getValue(_restKey);
    if (raw == null) {
      return RestState.forNewDay(
        todayKey,
        ProgressionConfig.dailyRestMinutes * 60,
      );
    }
    return RestState.fromJson(_tryDecode(raw), todayKey);
  }

  Future<void> saveRestState(RestState state) async {
    await db.appConfigsDao.setValue(_restKey, jsonEncode(state.toJson()));
  }

  Future<ProgressionSettings> getSettings() async {
    final raw = await db.appConfigsDao.getValue(_settingsKey);
    if (raw == null) return const ProgressionSettings();
    return ProgressionSettings.fromJson(_tryDecode(raw));
  }

  Future<void> saveSettings(ProgressionSettings settings) async {
    await db.appConfigsDao.setValue(
      _settingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  /// Deletes every `progression.v1.*` key. Used when re-pairing this device
  /// to a **different** patient (docs/PROGRESSION_PLAN.md §12); re-pairing the
  /// same patient must never call this.
  Future<void> clearAll() async {
    await (db.delete(db.appConfigs)
          ..where((t) => t.key.like('$_keyPrefix.%')))
        .go();
  }

  Object? _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
