/// All tunable numbers for the progression system in one place.
///
/// Nothing outside `lib/core/progression/` should hard-code any of these
/// values. Caregiver-adjustable ones (`dailyRestMinutes`, `nudgeRepeatPlays`,
/// `nudgeWindowDays`, `reviewEveryDays`) can be overridden per-device by
/// `progression.v1.settings` (see `ProgressionRepo`); everything else is
/// fixed here. See docs/PROGRESSION_PLAN.md §4.6.
class ProgressionConfig {
  const ProgressionConfig._();

  // Review (docs/PROGRESSION_PLAN.md §6)
  static const int reviewWindowDays = 4;
  static const int reviewEveryDays = 4;
  static const int minTrialsPerReview = 8; // short-trial games
  static const int minTrialsLongTask = 3; // name_harvest, sounds_home
  static const int minDistinctDaysPerReview = 2;
  static const double raiseScore = 0.85;
  static const double raiseAccuracy = 0.80;
  static const double nudgeUpScore = 0.78;
  static const double holdLowScore = 0.60;
  static const double easeMoreScore = 0.45;
  static const double raiseStep = 1.0;
  static const double raiseStepAfterRecentEase = 0.5;
  static const double nudgeUpStep = 0.5;
  static const double easeStep = 0.5;
  static const double easeMoreStep = 1.0;
  static const double concernDrop = 0.30;
  static const int historyLength = 12;
  static const double minLevel = 1.0;
  static const double plateauHeadroom = 1.0;
  static const int returningAfterDays = 14;
  static const double returningStep = 1.0;

  // In-session staircase (docs/PROGRESSION_PLAN.md §7)
  static const int staircaseDownAfterMisses = 2;
  static const int staircaseUpAfterHits = 3;
  static const double staircaseStep = 0.5;
  static const double staircaseMaxOffset = 1.0;

  // Counted play (docs/PROGRESSION_PLAN.md §3)
  static const int minCountedPlaySeconds = 30;

  // Variety nudge (docs/PROGRESSION_PLAN.md §8)
  static const int nudgeRepeatPlays = 6; // X
  static const int nudgeWindowDays = 1; // Y: daily window (resets each day)
  static const double nudgeShareOfPlays = 0.6;
  static const int nudgeCooldownHours = 24;
  static const int nudgeSnoozeDaysAfterTwoDismissals = 2;

  // Daily rest card (docs/PROGRESSION_PLAN.md §9)
  static const int dailyRestMinutes = 30; // 0 = never show
  static const int restCardRepeatMinutes = 15;
  static const int maxKeepPlayingCount = 3;
  static const int gameLockHours = 3;

  // Session length cap used when summing play time for the rest card
  // (docs/PROGRESSION_PLAN.md §9.1): each session contributes at most this
  // many seconds, so a clock jump or crash can never inflate the total.
  static const int maxCountedSessionSeconds = 8 * 60;
}
