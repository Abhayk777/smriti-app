import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/ability/estimator.dart';
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

    test('4th "Keep playing" locks games for 3 hours', () {
      var state = const RestState(dayKey: '2026-01-05', keptPlayingCount: 3);
      final nowMs = 1000000;
      final updated = PlayPolicy.afterRestCardAnswered(
        state,
        keptPlaying: true,
        playSecondsToday: 2400,
        repeatMinutes: 1,
        nowMs: nowMs,
      );
      expect(updated.keptPlayingCount, 4);
      expect(updated.lockedUntilMs, nowMs + 3 * 3600 * 1000);
      expect(PlayPolicy.isGamesLocked(updated, nowMs), isTrue);
      expect(PlayPolicy.isGamesLocked(updated, nowMs + 4 * 3600 * 1000), isFalse);
    });
  });

  group('game lock policy', () {
    test('shouldLockOnNextPrompt is true when keptPlayingCount >= 3', () {
      expect(PlayPolicy.shouldLockOnNextPrompt(const RestState(dayKey: 'k', keptPlayingCount: 2)), isFalse);
      expect(PlayPolicy.shouldLockOnNextPrompt(const RestState(dayKey: 'k', keptPlayingCount: 3)), isTrue);
      expect(PlayPolicy.shouldLockOnNextPrompt(const RestState(dayKey: 'k', keptPlayingCount: 4)), isTrue);
    });

    test('lockGames and unlockGames', () {
      const state = RestState(dayKey: '2026-01-05', keptPlayingCount: 3);
      final locked = PlayPolicy.lockGames(state, nowMs: 100000, lockHours: 3);
      expect(locked.lockedUntilMs, 100000 + 3 * 3600 * 1000);
      expect(PlayPolicy.isGamesLocked(locked, 100000), isTrue);

      final unlocked = PlayPolicy.unlockGames(locked);
      expect(unlocked.lockedUntilMs, isNull);
      expect(unlocked.keptPlayingCount, 0);
      expect(PlayPolicy.isGamesLocked(unlocked, 100000), isFalse);
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

  group('findFavouriteGame', () {
    const eligible = {'market_basket', 'trace_path', 'sort_harvest'};

    test('qualifies when plays >= 6, share >= 60%, and an eligible game has 0 plays', () {
      final fav = PlayPolicy.findFavouriteGame(
        countedPlaysByGame: {
          'market_basket': 6,
          'trace_path': 2,
        },
        eligibleGameIds: eligible,
      );
      // 6 / 8 = 75% >= 60%, sort_harvest has 0 plays
      expect(fav, 'market_basket');
    });

    test('does not qualify when plays < repeatPlays (default 6)', () {
      final fav = PlayPolicy.findFavouriteGame(
        countedPlaysByGame: {
          'market_basket': 5,
          'trace_path': 1,
        },
        eligibleGameIds: eligible,
      );
      expect(fav, isNull);
    });

    test('does not qualify when share < 60%', () {
      final fav = PlayPolicy.findFavouriteGame(
        countedPlaysByGame: {
          'market_basket': 6,
          'trace_path': 5,
        },
        eligibleGameIds: eligible,
      );
      // 6 / 11 = 54.5% < 60%
      expect(fav, isNull);
    });

    test('does not qualify if every other eligible game has at least 1 play', () {
      final fav = PlayPolicy.findFavouriteGame(
        countedPlaysByGame: {
          'market_basket': 10,
          'trace_path': 1,
          'sort_harvest': 1,
        },
        eligibleGameIds: eligible,
      );
      expect(fav, isNull);
    });

    test('checks specific gameId when provided', () {
      final fav = PlayPolicy.findFavouriteGame(
        countedPlaysByGame: {
          'market_basket': 6,
          'trace_path': 0,
        },
        eligibleGameIds: eligible,
        gameId: 'trace_path',
      );
      expect(fav, isNull);
    });
  });

  group('isNudgeAvailable', () {
    final now = DateTime(2026, 3, 15, 10, 0);

    test('available when state is fresh', () {
      const state = NudgeState();
      expect(PlayPolicy.isNudgeAvailable(state: state, favouriteId: 'market_basket', now: now), isTrue);
    });

    test('cooldown: not available within 24h for same favourite', () {
      final state = NudgeState(
        lastFavouriteId: 'market_basket',
        lastShownAtMs: now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
      );
      expect(PlayPolicy.isNudgeAvailable(state: state, favouriteId: 'market_basket', now: now), isFalse);
    });

    test('available after 24h cooldown', () {
      final state = NudgeState(
        lastFavouriteId: 'market_basket',
        lastShownAtMs: now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
      );
      expect(PlayPolicy.isNudgeAvailable(state: state, favouriteId: 'market_basket', now: now), isTrue);
    });

    test('available for different favourite even within cooldown of previous favourite', () {
      final state = NudgeState(
        lastFavouriteId: 'sort_harvest',
        lastShownAtMs: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      );
      expect(PlayPolicy.isNudgeAvailable(state: state, favouriteId: 'market_basket', now: now), isTrue);
    });

    test('not available when snoozed until future', () {
      final state = NudgeState(
        snoozedUntilMs: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      expect(PlayPolicy.isNudgeAvailable(state: state, favouriteId: 'market_basket', now: now), isFalse);
    });

    test('available once snooze expires', () {
      final state = NudgeState(
        snoozedUntilMs: now.subtract(const Duration(seconds: 1)).millisecondsSinceEpoch,
      );
      expect(PlayPolicy.isNudgeAvailable(state: state, favouriteId: 'market_basket', now: now), isTrue);
    });
  });

  group('chooseSuggestedGame', () {
    const gameDomains = {
      'market_basket': CognitiveDomain.executive,
      'trace_path': CognitiveDomain.visuospatial,
      'sort_harvest': CognitiveDomain.executive,
      'word_pairs': CognitiveDomain.memory,
    };
    const catalog = ['market_basket', 'trace_path', 'sort_harvest', 'word_pairs'];

    test('picks domain with fewest trials in last 7 days', () {
      final sug = PlayPolicy.chooseSuggestedGame(
        favouriteId: 'market_basket',
        favouriteDomain: CognitiveDomain.executive,
        eligibleGameIds: {'market_basket', 'trace_path', 'sort_harvest', 'word_pairs'},
        gameDomains: gameDomains,
        trialsByDomainLast7Days: {
          CognitiveDomain.executive: 50,
          CognitiveDomain.visuospatial: 20,
          CognitiveDomain.memory: 5,
        },
        lastPlayedAtMsByGame: {},
        gameCatalogOrder: catalog,
      );
      expect(sug, 'word_pairs');
    });

    test('prefers domain different from favourite when trials tie', () {
      final sug = PlayPolicy.chooseSuggestedGame(
        favouriteId: 'market_basket',
        favouriteDomain: CognitiveDomain.executive,
        eligibleGameIds: {'market_basket', 'sort_harvest', 'trace_path'},
        gameDomains: gameDomains,
        trialsByDomainLast7Days: {
          CognitiveDomain.executive: 0,
          CognitiveDomain.visuospatial: 0,
        },
        lastPlayedAtMsByGame: {},
        gameCatalogOrder: catalog,
      );
      // executive vs visuospatial tie on 0 trials; visuospatial is != favouriteDomain
      expect(sug, 'trace_path');
    });

    test('picks oldest lastPlayedAtMs within domain (null/never played counts as oldest)', () {
      final sug = PlayPolicy.chooseSuggestedGame(
        favouriteId: 'market_basket',
        favouriteDomain: CognitiveDomain.executive,
        eligibleGameIds: {'market_basket', 'trace_path', 'word_pairs'},
        gameDomains: gameDomains,
        trialsByDomainLast7Days: {
          CognitiveDomain.visuospatial: 0,
          CognitiveDomain.memory: 0,
        },
        lastPlayedAtMsByGame: {
          'trace_path': 100000,
          'word_pairs': null, // never played -> oldest
        },
        gameCatalogOrder: catalog,
      );
      expect(sug, 'word_pairs');
    });

    test('breaks tie with catalog order', () {
      final sug = PlayPolicy.chooseSuggestedGame(
        favouriteId: 'market_basket',
        favouriteDomain: CognitiveDomain.executive,
        eligibleGameIds: {'market_basket', 'trace_path', 'word_pairs'},
        gameDomains: gameDomains,
        trialsByDomainLast7Days: {
          CognitiveDomain.visuospatial: 0,
          CognitiveDomain.memory: 0,
        },
        lastPlayedAtMsByGame: {
          'trace_path': null,
          'word_pairs': null,
        },
        gameCatalogOrder: catalog,
      );
      // trace_path appears before word_pairs in catalog
      expect(sug, 'trace_path');
    });
  });

  group('afterNudgeShown / afterNudgeDismissed / afterSuggestedGameTapped', () {
    test('afterNudgeShown records favourite, suggested and timestamp', () {
      const state = NudgeState();
      final updated = PlayPolicy.afterNudgeShown(
        state,
        favouriteId: 'market_basket',
        suggestedId: 'trace_path',
        nowMs: 12345,
      );
      expect(updated.lastFavouriteId, 'market_basket');
      expect(updated.lastSuggestedId, 'trace_path');
      expect(updated.lastShownAtMs, 12345);
    });

    test('afterNudgeDismissed increments dismissStreak, and snoozes at 2', () {
      const state = NudgeState();
      final once = PlayPolicy.afterNudgeDismissed(state, nowMs: 1000);
      expect(once.dismissStreak, 1);
      expect(once.snoozedUntilMs, isNull);

      final twice = PlayPolicy.afterNudgeDismissed(once, nowMs: 2000, snoozeDays: 2);
      expect(twice.dismissStreak, 0);
      expect(twice.snoozedUntilMs, 2000 + 2 * 24 * 3600 * 1000);
    });

    test('afterSuggestedGameTapped resets dismissStreak', () {
      const state = NudgeState(dismissStreak: 1);
      final updated = PlayPolicy.afterSuggestedGameTapped(state);
      expect(updated.dismissStreak, 0);
    });
  });
}
