import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/ability/estimator.dart';
import 'package:smriti/core/progression/performance_report.dart';
import 'package:smriti/core/progression/progression_config.dart';
import 'package:smriti/core/progression/progression_policy.dart';
import 'package:smriti/core/progression/progression_state.dart';

const _day = Duration.millisecondsPerDay;

GameReport _report({
  String gameId = 'market_basket',
  int trials = 20,
  int countedPlays = 4,
  int distinctDays = 3,
  double? accuracy = 0.9,
  double? score = 0.9,
  double? meanLevel = 5.0,
  double hintRate = 0.0,
  double speedScore = 0.5,
  double abandonRate = 0.0,
}) {
  return GameReport(
    gameId: gameId,
    windowFromMs: 0,
    windowToMs: 4 * _day,
    trials: trials,
    countedPlays: countedPlays,
    distinctDays: distinctDays,
    accuracy: accuracy,
    partialCredit: score, // not used directly by the policy, kept consistent
    hintRate: hintRate,
    speedScore: speedScore,
    abandonRate: abandonRate,
    meanLevel: meanLevel,
    score: score,
  );
}

void main() {
  group('score bands', () {
    // Table-driven: (score, accuracy, expectedDecision, expectedStepFromLevel5)
    final cases = <(double, double, ReviewDecision, double)>[
      (0.90, 0.90, ReviewDecision.raise, 6.0), // >= 0.85 score, >= 0.80 accuracy
      (0.80, 0.90, ReviewDecision.hold, 5.0), // score below raise threshold
      (0.60, 0.90, ReviewDecision.hold, 5.0), // exactly the hold floor
      (0.50, 0.90, ReviewDecision.ease, 4.5), // below hold, at/above ease floor
      (0.45, 0.90, ReviewDecision.ease, 4.5), // exactly the ease floor
      (0.30, 0.90, ReviewDecision.easeMore, 4.0), // below ease floor
    ];

    for (final (score, accuracy, expectedDecision, expectedLevel) in cases) {
      test('score=$score accuracy=$accuracy -> $expectedDecision', () {
        final progress = GameProgress.fresh('market_basket').copyWith(level: 5.0);
        final result = ProgressionPolicy.review(
          progress: progress,
          report: _report(score: score, accuracy: accuracy),
          plateauLevel: 100,
          nowMs: 10 * _day,
        );
        expect(result.history.last.decision, expectedDecision);
        expect(result.level, closeTo(expectedLevel, 1e-9));
      });
    }

    test('a raise needs BOTH score and accuracy above their thresholds', () {
      // High score but low accuracy must not raise.
      final progress = GameProgress.fresh('market_basket').copyWith(level: 5.0);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.9, accuracy: 0.5),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.decision, isNot(ReviewDecision.raise));
    });

    test('nudgeUp requires the previous decision to be hold or nudgeUp', () {
      final withHold = GameProgress.fresh('market_basket')
          .copyWith(level: 5.0, lastDecision: ReviewDecision.hold);
      final result = ProgressionPolicy.review(
        progress: withHold,
        report: _report(score: 0.80, accuracy: 0.5),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.decision, ReviewDecision.nudgeUp);
      expect(result.level, closeTo(5.5, 1e-9));

      final withoutHold = GameProgress.fresh('market_basket')
          .copyWith(level: 5.0, lastDecision: ReviewDecision.easeMore);
      final resultNoHold = ProgressionPolicy.review(
        progress: withoutHold,
        report: _report(score: 0.80, accuracy: 0.5),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(resultNoHold.history.last.decision, isNot(ReviewDecision.nudgeUp));
    });
  });

  group('not enough data', () {
    test('too few trials gives notEnoughData and leaves the level unchanged', () {
      final progress = GameProgress.fresh('market_basket').copyWith(level: 5.0);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(trials: 2, distinctDays: 3, score: 0.9, accuracy: 0.9),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.decision, ReviewDecision.notEnoughData);
      expect(result.level, 5.0);
    });

    test('too few distinct days gives notEnoughData even with plenty of trials', () {
      final progress = GameProgress.fresh('market_basket').copyWith(level: 5.0);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(trials: 50, distinctDays: 1, score: 0.9, accuracy: 0.9),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.decision, ReviewDecision.notEnoughData);
      expect(result.level, 5.0);
    });

    test('long-task games (name_harvest, sounds_home) need only 3 trials', () {
      final progress = GameProgress.fresh('sounds_home').copyWith(level: 5.0);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(
          gameId: 'sounds_home',
          trials: 3,
          distinctDays: 2,
          score: 0.9,
          accuracy: 0.9,
        ),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.decision, ReviewDecision.raise);
    });

    test('sets lastReviewAtMs to tomorrow rather than a full 4-day cycle away', () {
      final progress = GameProgress.fresh('market_basket').copyWith(level: 5.0);
      final now = 10 * _day;
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(trials: 1, distinctDays: 1),
        plateauLevel: 100,
        nowMs: now,
      );
      final expectedNext =
          now - (ProgressionConfig.reviewEveryDays - 1) * _day;
      expect(result.lastReviewAtMs, expectedNext);
      // Due again (lastReviewAtMs + reviewEveryDays) exactly one day from now.
      expect(
        result.lastReviewAtMs! + ProgressionConfig.reviewEveryDays * _day,
        now + _day,
      );
    });

    test('still records a ReviewRecord with the raw report figures', () {
      final progress = GameProgress.fresh('market_basket').copyWith(level: 5.0);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(trials: 2, distinctDays: 1, accuracy: 0.5, score: 0.5),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      final record = result.history.last;
      expect(record.trials, 2);
      expect(record.distinctDays, 1);
      expect(record.accuracy, 0.5);
      expect(record.levelBefore, 5.0);
      expect(record.levelAfter, 5.0);
    });
  });

  group('anti-oscillation', () {
    test('a raise right after easeMore is held once, then granted on the next '
        'qualifying review', () {
      var progress = GameProgress.fresh('market_basket').copyWith(
        level: 5.0,
        lastDecision: ReviewDecision.easeMore,
      );

      // First qualifying review: held back, not raised yet.
      final first = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.9, accuracy: 0.9),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(first.history.last.decision, ReviewDecision.hold);
      expect(first.level, 5.0);
      expect(first.consecutiveRaiseQualifiers, 1);

      // Second qualifying review in a row: now it raises.
      progress = first;
      final second = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.9, accuracy: 0.9),
        plateauLevel: 100,
        nowMs: 14 * _day,
      );
      expect(second.history.last.decision, ReviewDecision.raise);
      expect(second.level, closeTo(6.0, 1e-9));
      expect(second.consecutiveRaiseQualifiers, 0);
    });

    test('a raise directly after a hold (not ease) does not need two reviews', () {
      final progress = GameProgress.fresh('market_basket')
          .copyWith(level: 5.0, lastDecision: ReviewDecision.hold);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.9, accuracy: 0.9),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.decision, ReviewDecision.raise);
    });

    test('the qualifier counter resets on any non-raise decision', () {
      var progress = GameProgress.fresh('market_basket').copyWith(
        level: 5.0,
        lastDecision: ReviewDecision.ease,
        consecutiveRaiseQualifiers: 1,
      );
      // A hold-band score is not a raise qualifier; counter resets to 0.
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.65, accuracy: 0.65),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.decision, ReviewDecision.hold);
      expect(result.consecutiveRaiseQualifiers, 0);
    });

    test('raising after a recent ease uses the smaller step', () {
      final progress = GameProgress.fresh('market_basket').copyWith(
        level: 5.0,
        lastDecision: ReviewDecision.hold,
        history: [
          const ReviewRecord(
            atMs: 1,
            windowFromMs: 0,
            windowToMs: 1,
            trials: 10,
            countedPlays: 2,
            distinctDays: 2,
            accuracy: 0.5,
            score: 0.5,
            levelBefore: 5.5,
            levelAfter: 5.0,
            decision: ReviewDecision.ease,
            concern: false,
            plateau: false,
          ),
        ],
      );
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.9, accuracy: 0.9),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.decision, ReviewDecision.raise);
      // Smaller step (0.5) because one of the last two decisions was ease.
      expect(result.level, closeTo(5.5, 1e-9));
    });
  });

  group('bounds and plateau', () {
    test('never drops below the minimum level', () {
      final progress = GameProgress.fresh('market_basket').copyWith(level: 1.0);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.1, accuracy: 0.1),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.level, 1.0);
    });

    test('a raise is capped at the plateau plus headroom, and flagged', () {
      final progress = GameProgress.fresh('market_basket').copyWith(level: 6.7);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.95, accuracy: 0.95),
        plateauLevel: 7.0, // headroom 1.0 -> max 8.0
        nowMs: 10 * _day,
      );
      expect(result.level, lessThanOrEqualTo(8.0));
      expect(result.history.last.plateau, isTrue);
    });

    test('levels are always rounded to the nearest 0.5', () {
      final progress = GameProgress.fresh('market_basket').copyWith(level: 5.3);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.9, accuracy: 0.9),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.level * 2, closeTo((result.level * 2).roundToDouble(), 1e-9));
    });

    test('plateau is false well below the plateau level', () {
      final progress = GameProgress.fresh('market_basket').copyWith(level: 2.0);
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.65, accuracy: 0.65),
        plateauLevel: 20,
        nowMs: 10 * _day,
      );
      expect(result.history.last.plateau, isFalse);
    });
  });

  group('concern flag', () {
    test('flags a drop of 0.30 or more from the last scored review', () {
      final progress = GameProgress.fresh('market_basket').copyWith(
        level: 5.0,
        history: [
          const ReviewRecord(
            atMs: 1,
            windowFromMs: 0,
            windowToMs: 1,
            trials: 20,
            countedPlays: 4,
            distinctDays: 3,
            accuracy: 0.9,
            score: 0.85,
            levelBefore: 5.0,
            levelAfter: 5.0,
            decision: ReviewDecision.hold,
            concern: false,
            plateau: false,
          ),
        ],
      );
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.50, accuracy: 0.50),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.concern, isTrue);
    });

    test('does not flag a smaller drop', () {
      final progress = GameProgress.fresh('market_basket').copyWith(
        level: 5.0,
        history: [
          const ReviewRecord(
            atMs: 1,
            windowFromMs: 0,
            windowToMs: 1,
            trials: 20,
            countedPlays: 4,
            distinctDays: 3,
            accuracy: 0.9,
            score: 0.80,
            levelBefore: 5.0,
            levelAfter: 5.0,
            decision: ReviewDecision.hold,
            concern: false,
            plateau: false,
          ),
        ],
      );
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.65, accuracy: 0.65),
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.concern, isFalse);
    });

    test('skips a previous notEnoughData record when looking for the last scored one',
        () {
      final progress = GameProgress.fresh('market_basket').copyWith(
        level: 5.0,
        history: [
          const ReviewRecord(
            atMs: 1,
            windowFromMs: 0,
            windowToMs: 1,
            trials: 20,
            countedPlays: 4,
            distinctDays: 3,
            accuracy: 0.9,
            score: 0.90,
            levelBefore: 5.0,
            levelAfter: 6.0,
            decision: ReviewDecision.raise,
            concern: false,
            plateau: false,
          ),
          const ReviewRecord(
            atMs: 2,
            windowFromMs: 1,
            windowToMs: 2,
            trials: 1,
            countedPlays: 1,
            distinctDays: 1,
            accuracy: null,
            score: null,
            levelBefore: 6.0,
            levelAfter: 6.0,
            decision: ReviewDecision.notEnoughData,
            concern: false,
            plateau: false,
          ),
        ],
      );
      final result = ProgressionPolicy.review(
        progress: progress,
        report: _report(score: 0.55, accuracy: 0.55), // 0.90 - 0.55 = 0.35 >= 0.30
        plateauLevel: 100,
        nowMs: 10 * _day,
      );
      expect(result.history.last.concern, isTrue);
    });
  });

  group('applyReturningEaseIfDue', () {
    test('does nothing for a game never played', () {
      final progress = GameProgress.fresh('market_basket');
      final result = ProgressionPolicy.applyReturningEaseIfDue(
        progress,
        nowMs: 100 * _day,
      );
      expect(result.level, progress.level);
      expect(result.lastDecision, isNull);
    });

    test('does nothing when the gap is under the returning threshold', () {
      final progress = GameProgress.fresh('market_basket').copyWith(
        level: 5.0,
        lastPlayedAtMs: 0,
      );
      final result = ProgressionPolicy.applyReturningEaseIfDue(
        progress,
        nowMs: (ProgressionConfig.returningAfterDays - 1) * _day,
      );
      expect(result.level, 5.0);
      expect(result.lastDecision, isNull);
    });

    test('eases by one step after a break of 14 days or more', () {
      final progress = GameProgress.fresh('market_basket').copyWith(
        level: 5.0,
        lastPlayedAtMs: 0,
      );
      final result = ProgressionPolicy.applyReturningEaseIfDue(
        progress,
        nowMs: ProgressionConfig.returningAfterDays * _day,
      );
      expect(result.level, closeTo(4.0, 1e-9));
      expect(result.lastDecision, ReviewDecision.returning);
    });

    test('never drops below the minimum level', () {
      final progress = GameProgress.fresh('market_basket').copyWith(
        level: 1.0,
        lastPlayedAtMs: 0,
      );
      final result = ProgressionPolicy.applyReturningEaseIfDue(
        progress,
        nowMs: 30 * _day,
      );
      expect(result.level, 1.0);
    });
  });

  group('startingLevel', () {
    test('uses the genre average minus one when other games are seeded', () {
      final others = [
        GameProgress.fresh('a').copyWith(level: 3.0, seeded: true),
        GameProgress.fresh('b').copyWith(level: 5.0, seeded: true),
      ];
      final level = ProgressionPolicy.startingLevel(
        domain: CognitiveDomain.memory,
        otherSeededGamesInDomain: others,
        thetaBasedLevel: 100, // should be ignored since others exist
      );
      // mean(3,5) - 1 = 3.0, well within the [1,4] clamp so it is untouched.
      expect(level, closeTo(3.0, 1e-9));
    });

    test('falls back to the theta-based level when no other game is seeded', () {
      final level = ProgressionPolicy.startingLevel(
        domain: CognitiveDomain.memory,
        otherSeededGamesInDomain: const [],
        thetaBasedLevel: 2.7,
      );
      expect(level, closeTo(2.5, 1e-9)); // rounded to nearest 0.5
    });

    test('clamps to [1, 4] on both ends', () {
      final low = ProgressionPolicy.startingLevel(
        domain: CognitiveDomain.memory,
        otherSeededGamesInDomain: const [],
        thetaBasedLevel: -10,
      );
      expect(low, 1.0);

      final high = ProgressionPolicy.startingLevel(
        domain: CognitiveDomain.memory,
        otherSeededGamesInDomain: const [],
        thetaBasedLevel: 10,
      );
      expect(high, 4.0);
    });
  });
}
