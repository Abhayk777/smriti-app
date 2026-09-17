import 'dart:convert';

import '../ability/estimator.dart';
import '../db/database.dart';
import 'level_scale.dart';
import 'progression_config.dart';
import 'trial_scoring.dart';

/// A summary of one game's play in a fixed time window, used by the 4-day
/// review (docs/PROGRESSION_PLAN.md §6.3). Pure: [GameReport.build] only
/// reduces the lists it is given, it never queries the database itself.
class GameReport {
  const GameReport({
    required this.gameId,
    required this.windowFromMs,
    required this.windowToMs,
    required this.trials,
    required this.countedPlays,
    required this.distinctDays,
    required this.accuracy,
    required this.partialCredit,
    required this.hintRate,
    required this.speedScore,
    required this.abandonRate,
    required this.meanLevel,
    required this.score,
  });

  final String gameId;
  final int windowFromMs;
  final int windowToMs;

  /// Number of `TrialEvents` rows in the window.
  final int trials;

  /// Sessions of this game in the window that count as a play (§3): at least
  /// [ProgressionConfig.minCountedPlaySeconds] long, or with at least one
  /// trial recorded.
  final int countedPlays;

  /// Distinct local calendar dates the trials fall on.
  final int distinctDays;

  /// Plain correct rate, 0..1; null when [trials] is 0.
  final double? accuracy;

  /// Mean [TrialScoring.score], 0..1; null when [trials] is 0.
  final double? partialCredit;

  /// Share of trials with `hintLevel > 0`. 0 when [trials] is 0.
  final double hintRate;

  /// 0..1; 0.5 when there is no previous window to compare against.
  final double speedScore;

  /// Share of [countedPlays] that ended early and abandoned within 2 minutes.
  /// 0 when [countedPlays] is 0.
  final double abandonRate;

  /// Mean level across the window's trials (docs/PROGRESSION_PLAN.md §3's
  /// level scale); null when [trials] is 0.
  final double? meanLevel;

  /// The performance score (docs/PROGRESSION_PLAN.md §6.3); null when
  /// [trials] is 0, since it is undefined without [partialCredit].
  final double? score;

  static const int _abandonedWithinMs = 120000;

  /// Builds a [GameReport] for [gameId] from raw rows already filtered to the
  /// review window `[windowFromMs, windowToMs)`.
  ///
  /// [gameSessions] must already be filtered to sessions of [gameId].
  /// [trialCountsBySession] is `sessionId -> trial count` for the SAME
  /// window (see `EventRepo.trialCountsBySessionBetween`).
  /// [previousMedianResponseTimeMs] is the elder's median `responseTimeMs`
  /// for this game in the review window immediately before this one, or null
  /// if there wasn't one.
  static GameReport build({
    required String gameId,
    required int windowFromMs,
    required int windowToMs,
    required List<TrialEvent> trials,
    required List<Session> gameSessions,
    required Map<String, int> trialCountsBySession,
    double? previousMedianResponseTimeMs,
  }) {
    final trialCount = trials.length;

    final countedPlays = gameSessions.where((s) {
      final trialsInSession = trialCountsBySession[s.id] ?? 0;
      if (trialsInSession > 0) return true;
      final durationSeconds = _sessionDurationSeconds(s);
      return durationSeconds != null &&
          durationSeconds >= ProgressionConfig.minCountedPlaySeconds;
    }).length;

    final abandonedCounted = gameSessions.where((s) {
      final trialsInSession = trialCountsBySession[s.id] ?? 0;
      final durationSeconds = _sessionDurationSeconds(s);
      final counted = trialsInSession > 0 ||
          (durationSeconds != null &&
              durationSeconds >= ProgressionConfig.minCountedPlaySeconds);
      return counted &&
          !s.completed &&
          s.abandonedAtMs != null &&
          s.abandonedAtMs! < _abandonedWithinMs;
    }).length;
    final abandonRate = countedPlays > 0 ? abandonedCounted / countedPlays : 0.0;

    final distinctDays = <String>{};
    var correctCount = 0;
    var hintedCount = 0;
    double partialCreditSum = 0;
    double levelSum = 0;
    final responseTimes = <int>[];

    for (final t in trials) {
      final local = DateTime.fromMillisecondsSinceEpoch(t.ts).toLocal();
      distinctDays.add('${local.year}-${local.month}-${local.day}');
      if (t.correct) correctCount++;
      if (t.hintLevel > 0) hintedCount++;
      partialCreditSum += TrialScoring.score(gameId, t);
      levelSum += _levelOf(t);
      responseTimes.add(t.responseTimeMs);
    }

    final accuracy = trialCount > 0 ? correctCount / trialCount : null;
    final partialCredit = trialCount > 0 ? partialCreditSum / trialCount : null;
    final hintRate = trialCount > 0 ? hintedCount / trialCount : 0.0;
    final meanLevel = trialCount > 0 ? levelSum / trialCount : null;

    final speedScore = _speedScore(
      previousMedianResponseTimeMs,
      _median(responseTimes),
    );

    final score = partialCredit == null
        ? null
        : (0.65 * partialCredit +
                0.15 * (1 - hintRate) +
                0.10 * speedScore +
                0.10 * (1 - abandonRate))
            .clamp(0.0, 1.0);

    return GameReport(
      gameId: gameId,
      windowFromMs: windowFromMs,
      windowToMs: windowToMs,
      trials: trialCount,
      countedPlays: countedPlays,
      distinctDays: distinctDays.length,
      accuracy: accuracy,
      partialCredit: partialCredit,
      hintRate: hintRate,
      speedScore: speedScore,
      abandonRate: abandonRate,
      meanLevel: meanLevel,
      score: score,
    );
  }

  static double _levelOf(TrialEvent t) {
    if (t.trialContext != null && t.trialContext!.isNotEmpty) {
      try {
        final decoded = jsonDecode(t.trialContext!);
        if (decoded is Map) {
          final progression = decoded['progression'];
          if (progression is Map) {
            final level = progression['level'];
            if (level is num) return level.toDouble();
          }
        }
      } catch (_) {
        // Fall through to the difficulty-derived level below.
      }
    }
    return LevelScale.difficultyToLevel(t.itemDifficulty);
  }

  static int? _sessionDurationSeconds(Session s) {
    if (s.completed && s.endedAt != null) {
      return ((s.endedAt! - s.startedAt) / 1000).round();
    }
    if (s.abandonedAtMs != null) {
      return (s.abandonedAtMs! / 1000).round();
    }
    return null;
  }

  static double? _median(List<int> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid].toDouble();
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  static double _speedScore(double? prev, double? cur) {
    if (prev == null || cur == null || prev <= 0) return 0.5;
    return (0.5 + 0.5 * (prev - cur) / prev).clamp(0.0, 1.0);
  }
}

/// A lightweight per-game input to [GenreReport.build]: however many trials a
/// game had and its score, over whatever window the caller is aggregating
/// (the 4-day review window, or the 7-day window §8.4 uses to choose a
/// variety suggestion).
class GenreGameSummary {
  const GenreGameSummary({
    required this.gameId,
    required this.trials,
    required this.score,
    this.concern = false,
  });

  final String gameId;
  final int trials;
  final double? score;
  final bool concern;
}

/// Aggregates one cognitive domain's games over whatever window the caller
/// supplied summaries for (docs/PROGRESSION_PLAN.md §6.8). Never changes any
/// game's level; purely informational, used for seeding a new game's
/// starting level, choosing a variety suggestion, and the caregiver's
/// "by genre" table.
class GenreReport {
  const GenreReport({
    required this.domain,
    required this.totalTrials,
    required this.meanScore,
    required this.gamesPlayed,
    required this.gamesWithConcern,
  });

  final CognitiveDomain domain;
  final int totalTrials;

  /// Trial-weighted mean of the games' scores; null when [totalTrials] is 0.
  final double? meanScore;

  /// Number of games in [games] with at least one trial.
  final int gamesPlayed;

  final int gamesWithConcern;

  static GenreReport build(CognitiveDomain domain, List<GenreGameSummary> games) {
    var totalTrials = 0;
    var weightedScoreSum = 0.0;
    var gamesPlayed = 0;
    var gamesWithConcern = 0;

    for (final g in games) {
      totalTrials += g.trials;
      if (g.trials > 0) {
        gamesPlayed++;
        if (g.score != null) weightedScoreSum += g.score! * g.trials;
      }
      if (g.concern) gamesWithConcern++;
    }

    return GenreReport(
      domain: domain,
      totalTrials: totalTrials,
      meanScore: totalTrials > 0 ? weightedScoreSum / totalTrials : null,
      gamesPlayed: gamesPlayed,
      gamesWithConcern: gamesWithConcern,
    );
  }
}
