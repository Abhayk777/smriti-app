import 'progression_config.dart';

/// What a review concluded for one game, per docs/PROGRESSION_PLAN.md §6.5.
enum ReviewDecision {
  raise,
  nudgeUp,
  hold,
  ease,
  easeMore,
  notEnoughData,
  returning,
}

ReviewDecision? _decisionFromName(Object? name) {
  if (name is! String) return null;
  for (final d in ReviewDecision.values) {
    if (d.name == name) return d;
  }
  return null;
}

/// One completed review of a game's last few days of play
/// (docs/PROGRESSION_PLAN.md §4.5, §6).
class ReviewRecord {
  const ReviewRecord({
    required this.atMs,
    required this.windowFromMs,
    required this.windowToMs,
    required this.trials,
    required this.countedPlays,
    required this.distinctDays,
    required this.accuracy,
    required this.score,
    required this.levelBefore,
    required this.levelAfter,
    required this.decision,
    required this.concern,
    required this.plateau,
  });

  final int atMs;
  final int windowFromMs;
  final int windowToMs;
  final int trials;
  final int countedPlays;
  final int distinctDays;

  /// 0..1 plain correct rate; null if there were no trials.
  final double? accuracy;

  /// 0..1 performance score (docs/PROGRESSION_PLAN.md §6.3); null if there
  /// were no trials.
  final double? score;

  final double levelBefore;
  final double levelAfter;
  final ReviewDecision decision;

  /// A sharp drop versus the previous review. Caregiver-only, never shown to
  /// the elder (docs/PROGRESSION_PLAN.md §6.6).
  final bool concern;

  /// True when [levelAfter] is at or above the game's plateau level
  /// (docs/PROGRESSION_PLAN.md §5.4).
  final bool plateau;

  Map<String, Object?> toJson() => {
        'atMs': atMs,
        'windowFromMs': windowFromMs,
        'windowToMs': windowToMs,
        'trials': trials,
        'countedPlays': countedPlays,
        'distinctDays': distinctDays,
        'accuracy': accuracy,
        'score': score,
        'levelBefore': levelBefore,
        'levelAfter': levelAfter,
        'decision': decision.name,
        'concern': concern,
        'plateau': plateau,
      };

  /// Returns null when [json] cannot be parsed as a valid [ReviewRecord]; the
  /// caller drops it rather than throwing (docs/PROGRESSION_PLAN.md §4.5).
  static ReviewRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    try {
      final decision = _decisionFromName(json['decision']);
      if (decision == null) return null;
      return ReviewRecord(
        atMs: (json['atMs'] as num).toInt(),
        windowFromMs: (json['windowFromMs'] as num).toInt(),
        windowToMs: (json['windowToMs'] as num).toInt(),
        trials: (json['trials'] as num).toInt(),
        countedPlays: (json['countedPlays'] as num).toInt(),
        distinctDays: (json['distinctDays'] as num).toInt(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        score: (json['score'] as num?)?.toDouble(),
        levelBefore: (json['levelBefore'] as num).toDouble(),
        levelAfter: (json['levelAfter'] as num).toDouble(),
        decision: decision,
        concern: json['concern'] as bool? ?? false,
        plateau: json['plateau'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persisted level and review history for one game
/// (docs/PROGRESSION_PLAN.md §4.5).
class GameProgress {
  const GameProgress({
    required this.gameId,
    required this.level,
    this.lastReviewAtMs,
    this.lastPlayedAtMs,
    this.consecutiveRaiseQualifiers = 0,
    this.lastDecision,
    this.history = const [],
    this.seeded = false,
  });

  /// A brand-new, unplayed game at the gentlest level.
  factory GameProgress.fresh(String gameId) =>
      GameProgress(gameId: gameId, level: ProgressionConfig.minLevel);

  final String gameId;

  /// >= [ProgressionConfig.minLevel], stored in steps of 0.5.
  final double level;

  /// Null until the first review has run.
  final int? lastReviewAtMs;

  final int? lastPlayedAtMs;

  /// For anti-oscillation (docs/PROGRESSION_PLAN.md §6.5 rule 4).
  final int consecutiveRaiseQualifiers;

  final ReviewDecision? lastDecision;

  /// Newest last, capped at [ProgressionConfig.historyLength].
  final List<ReviewRecord> history;

  /// True once the starting level has been set (docs/PROGRESSION_PLAN.md §6.7).
  final bool seeded;

  GameProgress copyWith({
    double? level,
    int? lastReviewAtMs,
    bool clearLastReviewAtMs = false,
    int? lastPlayedAtMs,
    bool clearLastPlayedAtMs = false,
    int? consecutiveRaiseQualifiers,
    ReviewDecision? lastDecision,
    bool clearLastDecision = false,
    List<ReviewRecord>? history,
    bool? seeded,
  }) {
    return GameProgress(
      gameId: gameId,
      level: level ?? this.level,
      lastReviewAtMs: clearLastReviewAtMs
          ? null
          : (lastReviewAtMs ?? this.lastReviewAtMs),
      lastPlayedAtMs: clearLastPlayedAtMs
          ? null
          : (lastPlayedAtMs ?? this.lastPlayedAtMs),
      consecutiveRaiseQualifiers:
          consecutiveRaiseQualifiers ?? this.consecutiveRaiseQualifiers,
      lastDecision:
          clearLastDecision ? null : (lastDecision ?? this.lastDecision),
      history: history ?? this.history,
      seeded: seeded ?? this.seeded,
    );
  }

  /// Appends [record] to [history], trimmed to
  /// [ProgressionConfig.historyLength] (oldest dropped first).
  GameProgress withReviewAppended(ReviewRecord record) {
    final updated = [...history, record];
    final trimmed = updated.length > ProgressionConfig.historyLength
        ? updated.sublist(updated.length - ProgressionConfig.historyLength)
        : updated;
    return copyWith(history: trimmed);
  }

  Map<String, Object?> toJson() => {
        'gameId': gameId,
        'level': level,
        'lastReviewAtMs': lastReviewAtMs,
        'lastPlayedAtMs': lastPlayedAtMs,
        'consecutiveRaiseQualifiers': consecutiveRaiseQualifiers,
        'lastDecision': lastDecision?.name,
        'history': history.map((r) => r.toJson()).toList(),
        'seeded': seeded,
      };

  /// Falls back to [GameProgress.fresh] for [gameId] whenever [json] is
  /// missing, malformed, or of the wrong shape, so a corrupt value can never
  /// throw into the UI (docs/PROGRESSION_PLAN.md §4.5).
  static GameProgress fromJson(String gameId, Object? json) {
    if (json is! Map) return GameProgress.fresh(gameId);
    try {
      final rawHistory = json['history'];
      final history = <ReviewRecord>[
        if (rawHistory is List)
          for (final entry in rawHistory)
            if (ReviewRecord.fromJson(entry) case final r?) r,
      ];
      return GameProgress(
        gameId: gameId,
        level: (json['level'] as num?)?.toDouble() ?? ProgressionConfig.minLevel,
        lastReviewAtMs: (json['lastReviewAtMs'] as num?)?.toInt(),
        lastPlayedAtMs: (json['lastPlayedAtMs'] as num?)?.toInt(),
        consecutiveRaiseQualifiers:
            (json['consecutiveRaiseQualifiers'] as num?)?.toInt() ?? 0,
        lastDecision: _decisionFromName(json['lastDecision']),
        history: history,
        seeded: json['seeded'] as bool? ?? false,
      );
    } catch (_) {
      return GameProgress.fresh(gameId);
    }
  }
}

/// State for the "try a different game" suggestion
/// (docs/PROGRESSION_PLAN.md §8.5).
class NudgeState {
  const NudgeState({
    this.lastFavouriteId,
    this.lastSuggestedId,
    this.lastShownAtMs,
    this.dismissStreak = 0,
    this.snoozedUntilMs,
  });

  factory NudgeState.initial() => const NudgeState();

  final String? lastFavouriteId;
  final String? lastSuggestedId;
  final int? lastShownAtMs;

  /// "Maybe later" taps in a row.
  final int dismissStreak;

  final int? snoozedUntilMs;

  NudgeState copyWith({
    String? lastFavouriteId,
    bool clearLastFavouriteId = false,
    String? lastSuggestedId,
    bool clearLastSuggestedId = false,
    int? lastShownAtMs,
    bool clearLastShownAtMs = false,
    int? dismissStreak,
    int? snoozedUntilMs,
    bool clearSnoozedUntilMs = false,
  }) {
    return NudgeState(
      lastFavouriteId: clearLastFavouriteId
          ? null
          : (lastFavouriteId ?? this.lastFavouriteId),
      lastSuggestedId: clearLastSuggestedId
          ? null
          : (lastSuggestedId ?? this.lastSuggestedId),
      lastShownAtMs:
          clearLastShownAtMs ? null : (lastShownAtMs ?? this.lastShownAtMs),
      dismissStreak: dismissStreak ?? this.dismissStreak,
      snoozedUntilMs: clearSnoozedUntilMs
          ? null
          : (snoozedUntilMs ?? this.snoozedUntilMs),
    );
  }

  Map<String, Object?> toJson() => {
        'lastFavouriteId': lastFavouriteId,
        'lastSuggestedId': lastSuggestedId,
        'lastShownAtMs': lastShownAtMs,
        'dismissStreak': dismissStreak,
        'snoozedUntilMs': snoozedUntilMs,
      };

  static NudgeState fromJson(Object? json) {
    if (json is! Map) return NudgeState.initial();
    try {
      return NudgeState(
        lastFavouriteId: json['lastFavouriteId'] as String?,
        lastSuggestedId: json['lastSuggestedId'] as String?,
        lastShownAtMs: (json['lastShownAtMs'] as num?)?.toInt(),
        dismissStreak: (json['dismissStreak'] as num?)?.toInt() ?? 0,
        snoozedUntilMs: (json['snoozedUntilMs'] as num?)?.toInt(),
      );
    } catch (_) {
      return NudgeState.initial();
    }
  }
}

/// State for the daily rest card (docs/PROGRESSION_PLAN.md §9.3).
class RestState {
  const RestState({
    required this.dayKey,
    this.nextDueAtSeconds,
    this.shownCount = 0,
    this.keptPlayingCount = 0,
    this.lockedUntilMs,
  });

  /// A fresh day with the reminder due at [thresholdSeconds] of play.
  factory RestState.forNewDay(String dayKey, int thresholdSeconds) => RestState(
        dayKey: dayKey,
        nextDueAtSeconds: thresholdSeconds > 0 ? thresholdSeconds : null,
      );

  /// 'yyyy-MM-dd', local. A different value means a new day and everything
  /// resets.
  final String dayKey;

  /// Play seconds today at which the card is next due; null means it will
  /// not show again today (the caregiver turned it off, or it was disabled).
  final int? nextDueAtSeconds;

  final int shownCount;

  /// "Keep playing" taps today; caregiver-visible only.
  final int keptPlayingCount;

  /// When games are taking a restful break until (epoch ms); null when games are active.
  final int? lockedUntilMs;

  RestState copyWith({
    int? nextDueAtSeconds,
    bool clearNextDueAtSeconds = false,
    int? shownCount,
    int? keptPlayingCount,
    int? lockedUntilMs,
    bool clearLockedUntilMs = false,
  }) {
    return RestState(
      dayKey: dayKey,
      nextDueAtSeconds: clearNextDueAtSeconds
          ? null
          : (nextDueAtSeconds ?? this.nextDueAtSeconds),
      shownCount: shownCount ?? this.shownCount,
      keptPlayingCount: keptPlayingCount ?? this.keptPlayingCount,
      lockedUntilMs: clearLockedUntilMs
          ? null
          : (lockedUntilMs ?? this.lockedUntilMs),
    );
  }

  Map<String, Object?> toJson() => {
        'dayKey': dayKey,
        'nextDueAtSeconds': nextDueAtSeconds,
        'shownCount': shownCount,
        'keptPlayingCount': keptPlayingCount,
        'lockedUntilMs': lockedUntilMs,
      };

  /// Falls back to a fresh state for [todayKey] whenever [json] is missing or
  /// malformed.
  static RestState fromJson(Object? json, String todayKey) {
    if (json is! Map) {
      return RestState.forNewDay(
        todayKey,
        ProgressionConfig.dailyRestMinutes * 60,
      );
    }
    try {
      final dayKey = json['dayKey'] as String?;
      if (dayKey == null) {
        return RestState.forNewDay(
          todayKey,
          ProgressionConfig.dailyRestMinutes * 60,
        );
      }
      return RestState(
        dayKey: dayKey,
        nextDueAtSeconds: (json['nextDueAtSeconds'] as num?)?.toInt(),
        shownCount: (json['shownCount'] as num?)?.toInt() ?? 0,
        keptPlayingCount: (json['keptPlayingCount'] as num?)?.toInt() ?? 0,
        lockedUntilMs: (json['lockedUntilMs'] as num?)?.toInt(),
      );
    } catch (_) {
      return RestState.forNewDay(
        todayKey,
        ProgressionConfig.dailyRestMinutes * 60,
      );
    }
  }
}
