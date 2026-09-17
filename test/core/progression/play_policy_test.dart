import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/play_policy.dart';
import 'package:smriti/core/progression/progression_config.dart';
import 'package:smriti/core/progression/progression_state.dart';

Session _session({
  required int startedAt,
  int? endedAt,
  bool completed = false,
  int? abandonedAtMs,
}) {
  return Session(
    id: 's',
    startedAt: startedAt,
    endedAt: endedAt,
    gameIds: 'market_basket',
    completed: completed,
    abandonedAtMs: abandonedAtMs,
    demoReplays: 0,
    synced: false,
  );
}

void main() {
  group('playSecondsToday', () {
    test('sums a completed session as endedAt - startedAt', () {
      final s = _session(startedAt: 0, endedAt: 90000, completed: true);
      expect(PlayPolicy.playSecondsToday([s]), 90);
    });

    test('sums an abandoned session as abandonedAtMs', () {
      final s = _session(startedAt: 0, abandonedAtMs: 45000);
      expect(PlayPolicy.playSecondsToday([s]), 45);
    });

    test('a still-open session (endedAt and abandonedAtMs both null) counts as 0', () {
      final s = _session(startedAt: 0);
      expect(PlayPolicy.playSecondsToday([s]), 0);
    });

    test('each session is capped at 8 minutes, even a very long one', () {
      final s = _session(startedAt: 0, endedAt: 3600000, completed: true); // 1 hour
      expect(PlayPolicy.playSecondsToday([s]), ProgressionConfig.maxCountedSessionSeconds);
    });

    test('an abandoned session past the cap is also capped', () {
      final s = _session(startedAt: 0, abandonedAtMs: 3600000);
      expect(PlayPolicy.playSecondsToday([s]), ProgressionConfig.maxCountedSessionSeconds);
    });

    test('sums multiple sessions', () {
      final sessions = [
        _session(startedAt: 0, endedAt: 60000, completed: true),
        _session(startedAt: 0, abandonedAtMs: 30000),
      ];
      expect(PlayPolicy.playSecondsToday(sessions), 90);
    });

    test('sessions outside today are simply not in the input list (caller filters)', () {
      // playSecondsToday itself doesn't filter by date; EventRepo.sessionsBetween
      // does that. An empty list (nothing from today) sums to 0.
      expect(PlayPolicy.playSecondsToday(const []), 0);
    });
  });

  group('dayKeyOf', () {
    test('formats as yyyy-MM-dd with zero-padding', () {
      expect(PlayPolicy.dayKeyOf(DateTime(2026, 1, 5)), '2026-01-05');
      expect(PlayPolicy.dayKeyOf(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('a session started at 23:58 belongs to its start day', () {
      final lateNight = DateTime(2026, 1, 5, 23, 58);
      expect(PlayPolicy.dayKeyOf(lateNight), '2026-01-05');
    });
  });

  group('forToday', () {
    test('keeps the state unchanged when the day matches', () {
      const state = RestState(dayKey: '2026-01-05', nextDueAtSeconds: 900);
      final result = PlayPolicy.forToday(state, '2026-01-05', 1800);
      expect(result.nextDueAtSeconds, 900);
    });

    test('resets to a fresh state when the day differs', () {
      const state = RestState(
        dayKey: '2026-01-04',
        nextDueAtSeconds: 100,
        shownCount: 3,
        keptPlayingCount: 2,
      );
      final result = PlayPolicy.forToday(state, '2026-01-05', 1800);
      expect(result.dayKey, '2026-01-05');
      expect(result.nextDueAtSeconds, 1800);
      expect(result.shownCount, 0);
      expect(result.keptPlayingCount, 0);
    });
  });

  group('restCardDue', () {
    test('due once play reaches the threshold', () {
      final state = RestState.forNewDay('2026-01-05', 1800);
      expect(PlayPolicy.restCardDue(state, 1799, 1800), isFalse);
      expect(PlayPolicy.restCardDue(state, 1800, 1800), isTrue);
      expect(PlayPolicy.restCardDue(state, 5000, 1800), isTrue);
    });

    test('never due when dailyRestMinutes is 0 (threshold 0)', () {
      final state = RestState.forNewDay('2026-01-05', 0);
      expect(PlayPolicy.restCardDue(state, 100000, 0), isFalse);
    });

    test('never due before nextDueAtSeconds is set', () {
      const state = RestState(dayKey: '2026-01-05');
      expect(PlayPolicy.restCardDue(state, 100000, 1800), isFalse);
    });
  });

  group('afterRestCardAnswered', () {
    test('"Keep playing" moves the next reminder to +15 minutes and counts it', () {
      final state = RestState.forNewDay('2026-01-05', 1800);
      final updated = PlayPolicy.afterRestCardAnswered(
        state,
        keptPlaying: true,
        playSecondsToday: 1800,
        repeatMinutes: ProgressionConfig.restCardRepeatMinutes,
      );
      expect(updated.nextDueAtSeconds, 1800 + 15 * 60);
      expect(updated.keptPlayingCount, 1);
    });

    test('"Rest now" also pushes the next reminder out, but is not counted', () {
      final state = RestState.forNewDay('2026-01-05', 1800);
      final updated = PlayPolicy.afterRestCardAnswered(
        state,
        keptPlaying: false,
        playSecondsToday: 1800,
        repeatMinutes: 15,
      );
      expect(updated.nextDueAtSeconds, 1800 + 15 * 60);
      expect(updated.keptPlayingCount, 0);
    });
  });

  group('afterRestCardShown', () {
    test('increments shownCount', () {
      final state = RestState.forNewDay('2026-01-05', 1800);
      expect(PlayPolicy.afterRestCardShown(state).shownCount, 1);
      expect(PlayPolicy.afterRestCardShown(PlayPolicy.afterRestCardShown(state)).shownCount, 2);
    });
  });

  group('displayMinutes', () {
    test('rounds down to the nearest 5 minutes', () {
      expect(PlayPolicy.displayMinutes(34 * 60), 30);
      expect(PlayPolicy.displayMinutes(29 * 60), 25);
      expect(PlayPolicy.displayMinutes(30 * 60), 30);
      expect(PlayPolicy.displayMinutes(0), 0);
    });
  });
}
