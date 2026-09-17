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
      if (s.completed && s.endedAt != null) {
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
  static bool restCardDue(RestState state, int playSecondsToday, int thresholdSeconds) {
    if (thresholdSeconds <= 0) return false;
    final due = state.nextDueAtSeconds;
    return due != null && playSecondsToday >= due;
  }

  /// [RestState] to save once the card has been shown.
  static RestState afterRestCardShown(RestState state) =>
      state.copyWith(shownCount: state.shownCount + 1);

  /// [RestState] to save once the elder has answered the card. Both answers
  /// push the next reminder out by [repeatMinutes] of further play
  /// (docs/PROGRESSION_PLAN.md §9.3); only "Keep playing" counts toward
  /// [RestState.keptPlayingCount] (caregiver-visible only).
  static RestState afterRestCardAnswered(
    RestState state, {
    required bool keptPlaying,
    required int playSecondsToday,
    required int repeatMinutes,
  }) {
    return state.copyWith(
      nextDueAtSeconds: playSecondsToday + repeatMinutes * 60,
      keptPlayingCount:
          keptPlaying ? state.keptPlayingCount + 1 : state.keptPlayingCount,
    );
  }

  /// The play-time figure shown on the card: whole minutes, rounded down to
  /// the nearest 5, so it never reads like a stopwatch.
  static int displayMinutes(int playSecondsToday) => (playSecondsToday ~/ 60 ~/ 5) * 5;

  // ── Variety nudge (§8) ───────────────────────────────────────────────────
  // Extended in a later task once the suggestion feature is built.
}
