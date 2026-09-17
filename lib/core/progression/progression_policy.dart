import '../ability/estimator.dart';
import 'level_scale.dart';
import 'performance_report.dart';
import 'progression_config.dart';
import 'progression_state.dart';

/// The 4-day review's decision rules (docs/PROGRESSION_PLAN.md §6.5), the
/// returning-after-a-break ease (§6.5 rule 1 / §6.7), and the starting level
/// for a game's first play (§6.7). Pure: every function here takes plain data
/// in and returns plain data out, with no database or Supabase access.
class ProgressionPolicy {
  const ProgressionPolicy._();

  /// Games where one play is a single long trial (60-90 seconds), so the
  /// "enough data" bar for a review is lower than for short-trial games
  /// (docs/PROGRESSION_PLAN.md §6.5 rule 2).
  static const Set<String> longTaskGames = {'name_harvest', 'sounds_home'};

  static int minTrialsFor(String gameId) => longTaskGames.contains(gameId)
      ? ProgressionConfig.minTrialsLongTask
      : ProgressionConfig.minTrialsPerReview;

  // ── Returning after a break (§6.5 rule 1) ───────────────────────────────

  /// Called once when the elder starts a session, before [progress] is
  /// otherwise touched for that session. If they have been away for
  /// [ProgressionConfig.returningAfterDays] or more, eases the level once.
  ///
  /// This never appends a [ReviewRecord]: it is an immediate, no-data
  /// adjustment at the start of play, not a review of a play window.
  static GameProgress applyReturningEaseIfDue(
    GameProgress progress, {
    required int nowMs,
  }) {
    final lastPlayed = progress.lastPlayedAtMs;
    if (lastPlayed == null) return progress;

    final gapDays = (nowMs - lastPlayed) / Duration.millisecondsPerDay;
    if (gapDays < ProgressionConfig.returningAfterDays) return progress;

    final newLevel = LevelScale.clampAndRound(
      progress.level - ProgressionConfig.returningStep,
      min: ProgressionConfig.minLevel,
    );
    return progress.copyWith(
      level: newLevel,
      lastDecision: ReviewDecision.returning,
    );
  }

  // ── Starting level for a game's first play (§6.7) ───────────────────────

  /// [otherSeededGamesInDomain] must already be filtered to games of the same
  /// [domain] as the new game, excluding it, with `seeded == true`.
  /// [thetaBasedLevel] is `LevelScale.difficultyToLevel(
  /// AbilityEstimator.nextDifficulty(theta))`, computed by the caller from
  /// `AbilityRepo.getOrSeed(domain)` (kept out of this pure function).
  static double startingLevel({
    required CognitiveDomain domain,
    required List<GameProgress> otherSeededGamesInDomain,
    required double thetaBasedLevel,
  }) {
    double level;
    if (otherSeededGamesInDomain.isNotEmpty) {
      final sum = otherSeededGamesInDomain
          .map((g) => g.level)
          .reduce((a, b) => a + b);
      level = sum / otherSeededGamesInDomain.length - 1.0;
    } else {
      level = thetaBasedLevel;
    }
    return LevelScale.clampAndRound(level, min: 1.0, max: 4.0);
  }

  // ── The 4-day review (§6.5 rules 2-6) ───────────────────────────────────

  /// Reviews [report] against [progress] and returns the updated
  /// [GameProgress], with a new [ReviewRecord] appended to its history.
  ///
  /// [report] must be built from every trial in `[windowFromMs, windowToMs)`
  /// for this game, even when there were none (docs/PROGRESSION_PLAN.md §6.2).
  static GameProgress review({
    required GameProgress progress,
    required GameReport report,
    required double plateauLevel,
    required int nowMs,
  }) {
    final levelBefore = progress.level;
    final enoughTrials = report.trials >= minTrialsFor(report.gameId);
    final enoughDays = report.distinctDays >= ProgressionConfig.minDistinctDaysPerReview;

    if (!enoughTrials || !enoughDays || report.score == null) {
      final record = ReviewRecord(
        atMs: nowMs,
        windowFromMs: report.windowFromMs,
        windowToMs: report.windowToMs,
        trials: report.trials,
        countedPlays: report.countedPlays,
        distinctDays: report.distinctDays,
        accuracy: report.accuracy,
        score: report.score,
        levelBefore: levelBefore,
        levelAfter: levelBefore,
        decision: ReviewDecision.notEnoughData,
        concern: false,
        plateau: _isAtPlateau(levelBefore, plateauLevel),
      );
      // Not due for a full cycle; check again tomorrow rather than waiting
      // out the rest of the 4-day window (docs/PROGRESSION_PLAN.md §6.5 rule 2).
      final nextCheckAtMs = nowMs -
          (ProgressionConfig.reviewEveryDays - 1) * Duration.millisecondsPerDay;
      return progress
          .copyWith(lastReviewAtMs: nextCheckAtMs, lastDecision: record.decision)
          .withReviewAppended(record);
    }

    final score = report.score!;
    final accuracy = report.accuracy ?? 0;

    final recentlyEased = _lastTwoDecisions(progress).any(
      (d) => d == ReviewDecision.ease || d == ReviewDecision.easeMore,
    );

    ReviewDecision decision;
    double step;
    if (score >= ProgressionConfig.raiseScore &&
        accuracy >= ProgressionConfig.raiseAccuracy) {
      decision = ReviewDecision.raise;
      step = recentlyEased
          ? ProgressionConfig.raiseStepAfterRecentEase
          : ProgressionConfig.raiseStep;
    } else if (score >= ProgressionConfig.nudgeUpScore &&
        (progress.lastDecision == ReviewDecision.hold ||
            progress.lastDecision == ReviewDecision.nudgeUp)) {
      decision = ReviewDecision.nudgeUp;
      step = ProgressionConfig.nudgeUpStep;
    } else if (score >= ProgressionConfig.holdLowScore) {
      decision = ReviewDecision.hold;
      step = 0;
    } else if (score >= ProgressionConfig.easeMoreScore) {
      decision = ReviewDecision.ease;
      step = -ProgressionConfig.easeStep;
    } else {
      decision = ReviewDecision.easeMore;
      step = -ProgressionConfig.easeMoreStep;
    }

    // Anti-oscillation (rule 4): a raise right after easing needs two
    // qualifying reviews in a row.
    var nextQualifiers = 0;
    final justEased = progress.lastDecision == ReviewDecision.ease ||
        progress.lastDecision == ReviewDecision.easeMore;
    if (decision == ReviewDecision.raise && justEased) {
      final qualifiers = progress.consecutiveRaiseQualifiers + 1;
      if (qualifiers >= 2) {
        nextQualifiers = 0;
      } else {
        decision = ReviewDecision.hold;
        step = 0;
        nextQualifiers = qualifiers;
      }
    }

    final levelAfter = LevelScale.clampAndRound(
      levelBefore + step,
      min: ProgressionConfig.minLevel,
      max: plateauLevel + ProgressionConfig.plateauHeadroom,
    );

    final concern = _concern(progress, score);

    final record = ReviewRecord(
      atMs: nowMs,
      windowFromMs: report.windowFromMs,
      windowToMs: report.windowToMs,
      trials: report.trials,
      countedPlays: report.countedPlays,
      distinctDays: report.distinctDays,
      accuracy: report.accuracy,
      score: report.score,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      decision: decision,
      concern: concern,
      plateau: _isAtPlateau(levelAfter, plateauLevel),
    );

    return progress
        .copyWith(
          level: levelAfter,
          lastReviewAtMs: nowMs,
          lastDecision: decision,
          consecutiveRaiseQualifiers: nextQualifiers,
        )
        .withReviewAppended(record);
  }

  static bool _isAtPlateau(double level, double plateauLevel) =>
      level >= plateauLevel - 1e-9;

  /// The decisions of, at most, the last two review records in history
  /// (newest last), used only to decide the raise step size — a looser check
  /// than the anti-oscillation gate above, which only looks at the single
  /// most recent decision.
  static List<ReviewDecision> _lastTwoDecisions(GameProgress progress) {
    final history = progress.history;
    if (history.isEmpty) return const [];
    final start = history.length > 2 ? history.length - 2 : 0;
    return history.sublist(start).map((r) => r.decision).toList();
  }

  /// True when the previous review that actually had enough data to score
  /// (i.e. was not itself `notEnoughData`) dropped by
  /// [ProgressionConfig.concernDrop] or more (docs/PROGRESSION_PLAN.md §6.6).
  static bool _concern(GameProgress progress, double currentScore) {
    for (var i = progress.history.length - 1; i >= 0; i--) {
      final previous = progress.history[i];
      if (previous.decision == ReviewDecision.notEnoughData) continue;
      final previousScore = previous.score;
      if (previousScore == null) continue;
      return (previousScore - currentScore) >= ProgressionConfig.concernDrop;
    }
    return false;
  }
}
