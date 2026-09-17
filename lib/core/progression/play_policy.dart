import '../ability/estimator.dart';
import '../db/database.dart';
import 'progression_config.dart';
import 'progression_state.dart';

/// Pure rules for the daily rest card (docs/PROGRESSION_PLAN.md §9) and the
/// variety nudge (§8). No I/O: callers gather the raw data
/// ([Session] rows, [RestState]/[NudgeState]) and these functions decide
/// what should happen.
class PlayPolicy {
  const PlayPolicy._();

  // ── Daily rest card (§9) ─────────────────────────────────────────────────

  /// `playSecondsToday` per §9.1: the sum of every session's duration,
  /// each capped at [ProgressionConfig.maxCountedSessionSeconds] so a clock
  /// change or crash can never inflate the total.
  ///
  /// [sessionsToday] must already be filtered to sessions whose `startedAt`
  /// falls on today's local date (see `EventRepo.sessionsBetween`).
  static int playSecondsToday(List<Session> sessionsToday) {
    var total = 0;
    for (final s in sessionsToday) {
      final int seconds;
      if (s.endedAt != null) {
        seconds = ((s.endedAt! - s.startedAt) / 1000).round();
      } else if (s.abandonedAtMs != null) {
        seconds = (s.abandonedAtMs! / 1000).round();
      } else {
        seconds = 0; // still open (a crash mid-session): not counted
      }
      total += seconds.clamp(0, ProgressionConfig.maxCountedSessionSeconds);
    }
    return total;
  }

  /// 'yyyy-MM-dd' in local time, the key [RestState.dayKey] is compared
  /// against.
  static String dayKeyOf(DateTime local) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  /// Rolls [state] over to today if it was left over from an earlier day.
  static RestState forToday(RestState state, String todayKey, int thresholdSeconds) {
    if (state.dayKey == todayKey) return state;
    return RestState.forNewDay(todayKey, thresholdSeconds);
  }

  /// Whether the rest card should show right now. `thresholdSeconds <= 0`
  /// (the caregiver turned the reminder off) always means no.
  /// If games are locked for a break, the standard reminder does not show.
  static bool restCardDue(RestState state, int playSecondsToday, int thresholdSeconds) {
    if (thresholdSeconds <= 0) return false;
    final due = state.nextDueAtSeconds;
    return due != null && playSecondsToday >= due;
  }

  /// Whether the games feature is currently locked for a restful break.
  static bool isGamesLocked(RestState state, int nowMs) {
    return state.lockedUntilMs != null && nowMs < state.lockedUntilMs!;
  }

  /// Whether the upcoming rest prompt should be the 3-hour break lock
  /// (because the elder has chosen "Keep playing" [maxKeepPlayingCount] times already).
  static bool shouldLockOnNextPrompt(
    RestState state, {
    int maxKeepPlayingCount = ProgressionConfig.maxKeepPlayingCount,
  }) {
    return state.keptPlayingCount >= maxKeepPlayingCount;
  }

  /// Locks games for [lockHours] (default 3 hours).
  static RestState lockGames(
    RestState state, {
    required int nowMs,
    int lockHours = ProgressionConfig.gameLockHours,
  }) {
    return state.copyWith(
      lockedUntilMs: nowMs + lockHours * 3600 * 1000,
      clearNextDueAtSeconds: true,
    );
  }

  /// Unlocks games, clearing the resting lock and resetting keptPlayingCount.
  static RestState unlockGames(RestState state) {
    return state.copyWith(
      clearLockedUntilMs: true,
      keptPlayingCount: 0,
    );
  }

  /// [RestState] to save once the card has been shown.
  static RestState afterRestCardShown(RestState state) =>
      state.copyWith(shownCount: state.shownCount + 1);

  /// [RestState] to save once the elder has answered the card.
  /// Both answers push the next reminder out by [repeatMinutes] of further play.
  /// If the elder chose "Keep playing" [maxKeepPlayingCount] times already,
  /// the next prompt or answering "Keep playing" locks games for [lockHours].
  static RestState afterRestCardAnswered(
    RestState state, {
    required bool keptPlaying,
    required int playSecondsToday,
    required int repeatMinutes,
    int? nowMs,
    int maxKeepPlayingCount = ProgressionConfig.maxKeepPlayingCount,
    int lockHours = ProgressionConfig.gameLockHours,
  }) {
    if (keptPlaying) {
      final newCount = state.keptPlayingCount + 1;
      if (newCount > maxKeepPlayingCount) {
        final currentMs = nowMs ?? DateTime.now().millisecondsSinceEpoch;
        return state.copyWith(
          keptPlayingCount: newCount,
          lockedUntilMs: currentMs + lockHours * 3600 * 1000,
          clearNextDueAtSeconds: true,
        );
      }
      return state.copyWith(
        nextDueAtSeconds: playSecondsToday + repeatMinutes * 60,
        keptPlayingCount: newCount,
      );
    } else {
      return state.copyWith(
        nextDueAtSeconds: playSecondsToday + repeatMinutes * 60,
      );
    }
  }

  /// The play-time figure shown on the card: whole minutes, rounded down to
  /// the nearest 5, so it never reads like a stopwatch.
  static int displayMinutes(int playSecondsToday) => (playSecondsToday ~/ 60 ~/ 5) * 5;

  // ── Variety nudge (§8) ───────────────────────────────────────────────────

  /// Evaluates whether [gameId] (or any game, if [gameId] is null) qualifies
  /// as a favourite under docs/PROGRESSION_PLAN.md §8.1.
  ///
  /// Criteria:
  /// 1. playsG >= [repeatPlays] (default 6)
  /// 2. playsG / allPlays >= [shareOfPlays] (default 0.6)
  /// 3. At least one other game in [eligibleGameIds] (other != G) has 0 counted plays.
  static String? findFavouriteGame({
    required Map<String, int> countedPlaysByGame,
    required Set<String> eligibleGameIds,
    String? gameId,
    int repeatPlays = ProgressionConfig.nudgeRepeatPlays,
    double shareOfPlays = ProgressionConfig.nudgeShareOfPlays,
  }) {
    final allPlays = countedPlaysByGame.values.fold<int>(0, (a, b) => a + b);
    if (allPlays <= 0) return null;

    bool qualifies(String candidate) {
      final plays = countedPlaysByGame[candidate] ?? 0;
      if (plays < repeatPlays) return false;
      if (plays / allPlays < shareOfPlays) return false;
      final otherWithZero = eligibleGameIds.any(
        (other) => other != candidate && (countedPlaysByGame[other] ?? 0) == 0,
      );
      return otherWithZero;
    }

    if (gameId != null) {
      return qualifies(gameId) ? gameId : null;
    }

    for (final candidate in eligibleGameIds) {
      if (qualifies(candidate)) return candidate;
    }
    return null;
  }

  /// Whether a nudge for [favouriteId] is allowed to show right now
  /// (docs/PROGRESSION_PLAN.md §8.5).
  static bool isNudgeAvailable({
    required NudgeState state,
    required String favouriteId,
    required DateTime now,
    int cooldownHours = ProgressionConfig.nudgeCooldownHours,
  }) {
    final nowMs = now.millisecondsSinceEpoch;
    if (state.snoozedUntilMs != null && nowMs < state.snoozedUntilMs!) {
      return false;
    }
    if (state.lastFavouriteId == favouriteId && state.lastShownAtMs != null) {
      final elapsedMs = nowMs - state.lastShownAtMs!;
      if (elapsedMs < cooldownHours * 3600 * 1000) {
        return false;
      }
    }
    return true;
  }

  /// Selects the suggested game among [eligibleGameIds] (excluding [favouriteId])
  /// per docs/PROGRESSION_PLAN.md §8.4:
  /// 1. Domain with fewest trials in the last 7 days, preferring domains != favourite's.
  /// 2. Oldest lastPlayedAtMs within that domain (never played / null counts as oldest).
  /// 3. Catalog order tie-breaker.
  static String? chooseSuggestedGame({
    required String favouriteId,
    required CognitiveDomain favouriteDomain,
    required Set<String> eligibleGameIds,
    required Map<String, CognitiveDomain> gameDomains,
    required Map<CognitiveDomain, int> trialsByDomainLast7Days,
    required Map<String, int?> lastPlayedAtMsByGame,
    required List<String> gameCatalogOrder,
  }) {
    final candidates = eligibleGameIds.where((g) => g != favouriteId).toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final domainA = gameDomains[a]!;
      final domainB = gameDomains[b]!;

      final trialsA = trialsByDomainLast7Days[domainA] ?? 0;
      final trialsB = trialsByDomainLast7Days[domainB] ?? 0;
      if (trialsA != trialsB) {
        return trialsA.compareTo(trialsB);
      }

      final isFavDomainA = domainA == favouriteDomain ? 1 : 0;
      final isFavDomainB = domainB == favouriteDomain ? 1 : 0;
      if (isFavDomainA != isFavDomainB) {
        return isFavDomainA.compareTo(isFavDomainB);
      }

      final playedA = lastPlayedAtMsByGame[a] ?? 0;
      final playedB = lastPlayedAtMsByGame[b] ?? 0;
      if (playedA != playedB) {
        return playedA.compareTo(playedB);
      }

      final indexA = gameCatalogOrder.indexOf(a);
      final indexB = gameCatalogOrder.indexOf(b);
      return indexA.compareTo(indexB);
    });

    return candidates.first;
  }

  /// Returns updated [NudgeState] after the nudge has been shown.
  static NudgeState afterNudgeShown(
    NudgeState state, {
    required String favouriteId,
    required String suggestedId,
    required int nowMs,
  }) {
    return state.copyWith(
      lastFavouriteId: favouriteId,
      lastSuggestedId: suggestedId,
      lastShownAtMs: nowMs,
    );
  }

  /// Returns updated [NudgeState] after "Maybe later" is tapped.
  /// At 2 dismissals, snoozes for [snoozeDays] (default 2) and resets streak.
  static NudgeState afterNudgeDismissed(
    NudgeState state, {
    required int nowMs,
    int snoozeDays = ProgressionConfig.nudgeSnoozeDaysAfterTwoDismissals,
  }) {
    final streak = state.dismissStreak + 1;
    if (streak >= 2) {
      return state.copyWith(
        dismissStreak: 0,
        snoozedUntilMs: nowMs + snoozeDays * 24 * 3600 * 1000,
      );
    }
    return state.copyWith(dismissStreak: streak);
  }

  /// Returns updated [NudgeState] after the suggested game is tapped.
  static NudgeState afterSuggestedGameTapped(NudgeState state) {
    return state.copyWith(dismissStreak: 0);
  }
}
