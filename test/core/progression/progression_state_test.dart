import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/progression/progression_state.dart';

void main() {
  group('ReviewRecord', () {
    ReviewRecord sample() => const ReviewRecord(
          atMs: 1000,
          windowFromMs: 0,
          windowToMs: 1000,
          trials: 12,
          countedPlays: 3,
          distinctDays: 2,
          accuracy: 0.8,
          score: 0.75,
          levelBefore: 5.0,
          levelAfter: 6.0,
          decision: ReviewDecision.raise,
          concern: false,
          plateau: false,
        );

    test('round-trips through JSON', () {
      final original = sample();
      final decoded = jsonDecode(jsonEncode(original.toJson()));
      final restored = ReviewRecord.fromJson(decoded)!;

      expect(restored.atMs, original.atMs);
      expect(restored.windowFromMs, original.windowFromMs);
      expect(restored.windowToMs, original.windowToMs);
      expect(restored.trials, original.trials);
      expect(restored.countedPlays, original.countedPlays);
      expect(restored.distinctDays, original.distinctDays);
      expect(restored.accuracy, original.accuracy);
      expect(restored.score, original.score);
      expect(restored.levelBefore, original.levelBefore);
      expect(restored.levelAfter, original.levelAfter);
      expect(restored.decision, original.decision);
      expect(restored.concern, original.concern);
      expect(restored.plateau, original.plateau);
    });

    test('round-trips null accuracy and score', () {
      final r = ReviewRecord(
        atMs: 1,
        windowFromMs: 0,
        windowToMs: 1,
        trials: 0,
        countedPlays: 0,
        distinctDays: 0,
        accuracy: null,
        score: null,
        levelBefore: 1,
        levelAfter: 1,
        decision: ReviewDecision.notEnoughData,
        concern: false,
        plateau: false,
      );
      final restored = ReviewRecord.fromJson(jsonDecode(jsonEncode(r.toJson())))!;
      expect(restored.accuracy, isNull);
      expect(restored.score, isNull);
    });

    test('returns null for corrupt or non-map JSON', () {
      expect(ReviewRecord.fromJson('not a map'), isNull);
      expect(ReviewRecord.fromJson(null), isNull);
      expect(ReviewRecord.fromJson({'atMs': 1}), isNull); // missing fields
      expect(
        ReviewRecord.fromJson({...sample().toJson(), 'decision': 'not_real'}),
        isNull,
      );
    });
  });

  group('GameProgress', () {
    test('fresh() starts at the minimum level, unseeded, empty history', () {
      final p = GameProgress.fresh('market_basket');
      expect(p.gameId, 'market_basket');
      expect(p.level, 1.0);
      expect(p.seeded, isFalse);
      expect(p.lastReviewAtMs, isNull);
      expect(p.lastPlayedAtMs, isNull);
      expect(p.history, isEmpty);
      expect(p.consecutiveRaiseQualifiers, 0);
      expect(p.lastDecision, isNull);
    });

    test('round-trips through JSON including history', () {
      final review = ReviewRecord(
        atMs: 10,
        windowFromMs: 0,
        windowToMs: 10,
        trials: 5,
        countedPlays: 1,
        distinctDays: 1,
        accuracy: 0.5,
        score: 0.5,
        levelBefore: 1,
        levelAfter: 1,
        decision: ReviewDecision.hold,
        concern: false,
        plateau: false,
      );
      final original = GameProgress(
        gameId: 'sort_harvest',
        level: 4.5,
        lastReviewAtMs: 500,
        lastPlayedAtMs: 600,
        consecutiveRaiseQualifiers: 1,
        lastDecision: ReviewDecision.ease,
        history: [review],
        seeded: true,
      );

      final decoded = jsonDecode(jsonEncode(original.toJson()));
      final restored = GameProgress.fromJson('sort_harvest', decoded);

      expect(restored.gameId, 'sort_harvest');
      expect(restored.level, 4.5);
      expect(restored.lastReviewAtMs, 500);
      expect(restored.lastPlayedAtMs, 600);
      expect(restored.consecutiveRaiseQualifiers, 1);
      expect(restored.lastDecision, ReviewDecision.ease);
      expect(restored.seeded, isTrue);
      expect(restored.history, hasLength(1));
      expect(restored.history.single.trials, 5);
    });

    test('falls back to fresh() on null, malformed, or wrong-shaped JSON', () {
      expect(GameProgress.fromJson('g', null).level, 1.0);
      expect(GameProgress.fromJson('g', 'not a map').level, 1.0);
      expect(GameProgress.fromJson('g', {'level': 'not a number'}).level, 1.0);
      expect(GameProgress.fromJson('g', {}).seeded, isFalse);
    });

    test('a corrupt entry inside history is dropped, not fatal', () {
      final json = {
        'gameId': 'g',
        'level': 3.0,
        'history': [
          'not a valid record',
          {'atMs': 1}, // missing required fields
        ],
      };
      final restored = GameProgress.fromJson('g', json);
      expect(restored.level, 3.0);
      expect(restored.history, isEmpty);
    });

    test('withReviewAppended caps history at the configured length', () {
      var progress = GameProgress.fresh('g');
      for (var i = 0; i < 20; i++) {
        progress = progress.withReviewAppended(
          ReviewRecord(
            atMs: i,
            windowFromMs: 0,
            windowToMs: 1,
            trials: 1,
            countedPlays: 1,
            distinctDays: 1,
            accuracy: 1,
            score: 1,
            levelBefore: 1,
            levelAfter: 1,
            decision: ReviewDecision.hold,
            concern: false,
            plateau: false,
          ),
        );
      }
      expect(progress.history, hasLength(12));
      // Newest last: the final appended atMs is 19.
      expect(progress.history.last.atMs, 19);
      expect(progress.history.first.atMs, 8);
    });
  });

  group('NudgeState', () {
    test('round-trips through JSON', () {
      const original = NudgeState(
        lastFavouriteId: 'market_basket',
        lastSuggestedId: 'trace_path',
        lastShownAtMs: 1000,
        dismissStreak: 1,
        snoozedUntilMs: 2000,
      );
      final restored = NudgeState.fromJson(jsonDecode(jsonEncode(original.toJson())));
      expect(restored.lastFavouriteId, 'market_basket');
      expect(restored.lastSuggestedId, 'trace_path');
      expect(restored.lastShownAtMs, 1000);
      expect(restored.dismissStreak, 1);
      expect(restored.snoozedUntilMs, 2000);
    });

    test('initial() has no favourite and no dismissals', () {
      final s = NudgeState.initial();
      expect(s.lastFavouriteId, isNull);
      expect(s.dismissStreak, 0);
      expect(s.snoozedUntilMs, isNull);
    });

    test('falls back to initial() on corrupt JSON', () {
      expect(NudgeState.fromJson('nope').dismissStreak, 0);
      expect(NudgeState.fromJson(null).lastFavouriteId, isNull);
    });
  });

  group('RestState', () {
    test('forNewDay sets the threshold in seconds', () {
      final s = RestState.forNewDay('2026-01-01', 1800);
      expect(s.dayKey, '2026-01-01');
      expect(s.nextDueAtSeconds, 1800);
      expect(s.shownCount, 0);
      expect(s.keptPlayingCount, 0);
    });

    test('forNewDay with a zero threshold means never due', () {
      final s = RestState.forNewDay('2026-01-01', 0);
      expect(s.nextDueAtSeconds, isNull);
    });

    test('round-trips through JSON', () {
      const original = RestState(
        dayKey: '2026-01-02',
        nextDueAtSeconds: 2700,
        shownCount: 2,
        keptPlayingCount: 1,
      );
      final restored = RestState.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
        '2026-01-02',
      );
      expect(restored.dayKey, '2026-01-02');
      expect(restored.nextDueAtSeconds, 2700);
      expect(restored.shownCount, 2);
      expect(restored.keptPlayingCount, 1);
    });

    test('falls back to a fresh state for today on corrupt JSON', () {
      final restored = RestState.fromJson('nope', '2026-03-03');
      expect(restored.dayKey, '2026-03-03');
      expect(restored.shownCount, 0);
    });
  });
}
