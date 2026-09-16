# Smriti: Progressive Game Levels, 4-Day Review, Variety Nudge and Daily Rest Card

Implementation plan for SIH problem statement 26003 ("progressive games that change level
according to the user's performance").

Status: **plan only, nothing in this document is built yet.**
Audience: any engineer or coding agent building this feature in the Smriti Flutter app.
Read `AGENTS.md` and `docs/APP-BUILD-SPEC.md` §1, §3, §5, §7 and §11 before starting.

---

## 0. How to use this document

1. Build in the task order of §13. Each task lists the files it may touch, what to write,
   and its acceptance tests. Do not touch any file not listed for that task.
2. After each task run `flutter analyze` (must print `No issues found!`) and `flutter test`.
   The test `caregiver_login_test.dart: confirming pairs the chosen patient and signs the
   caregiver out` already fails before this work. Every other test must keep passing.
3. Every number in this plan (thresholds, steps, limits) lives in one constants file
   (§4.1) so it can be tuned without code changes elsewhere.
4. User-visible text must not contain the em dash character, must never say "wrong",
   "failed", "error" or "limit reached", and must never use red, warning or error icons
   (AGENTS.md non-negotiable #11, plus the product owner's rule for dementia patients).

---

## 1. Goals

| # | Goal | Where in this plan |
|---|---|---|
| G1 | Each game has a **level** that rises or falls with the elder's performance. | §3, §5, §6 |
| G2 | Every **4 days**, analyse the last 4 days of play **per game and per genre (cognitive domain)** and move the level up or down a little. | §6 |
| G3 | Levels are **generated from formulas**, not hand-written tables, so the system keeps working for months or years without anyone adding levels. | §5 |
| G4 | If the elder plays **one game X times in Y days** and neglects others, show a **soft, friendly suggestion** to try a different game. | §8 |
| G5 | After about **30 minutes of play in a day** (all games together), a warm, closable "time for a rest" card appears. **Nothing is ever blocked.** | §9 |
| G6 | Nothing else in the app changes behaviour. The backend contract, database schema and existing features stay as they are. | §2 |

### Non-goals
- No change to Supabase tables, RPCs or Edge Functions.
- No change to `lib/core/db/tables.dart` or the Drift schema version.
- No change to `AbilityEstimator` (spec §3 marks it as done and tested).
- No level numbers, scores or "you got worse" messages shown to the elder.

---

## 2. Hard constraints (read before writing code)

| Constraint | Source | What it means here |
|---|---|---|
| SQLite is the source of truth; nothing waits on the network. | AGENTS.md "The one principle" | All analysis reads local `TrialEvents` and `Sessions`. No Supabase calls. |
| Only `lib/core/sync/` and `lib/core/auth/` may import `supabase_flutter`. | AGENTS.md #1 | `lib/core/progression/` must not import it. |
| `TrialEvents` and `Sessions` are insert-only. | AGENTS.md #3 | Reviews only **read** these tables. Level state is stored elsewhere (§4.3). |
| Games never touch the database. | AGENTS.md #10 | Games still receive only `double difficulty` in `generateItem`. The session runner and the new service own everything else. |
| No negative feedback. | AGENTS.md #11 | Nudge and daily-rest messages are warm and optional in tone; see §10 copy. |
| Do not modify `tables.dart`. | Spec §5 | Progression state goes into `AppConfigs` as JSON values under new keys. No migration. |
| Do not invent backend names. | AGENTS.md workflow | Level info reaches the caregiver only through the existing, already-synced `TrialEvents.trialContext` JSON text column (`trial_context` remotely). |
| `CognitiveGame` interface is fixed. | Spec §11 | Signature `GameItem generateItem(double difficulty, GameContent content)` stays. |
| Must work on every Android brand and version. | Project rule | Pure Dart, no platform channels. |

---

## 3. Concepts and terms

- **Game**: one of the 9 entries in `lib/games/game_catalog.dart` (`faces_of_family`,
  `market_basket`, `sort_harvest`, `trace_path`, `my_day`, `lamps_festival`,
  `name_harvest`, `weaving_patterns`, `sounds_home`).
- **Genre**: the game's `primaryDomain` (`CognitiveDomain` in
  `lib/core/ability/estimator.dart`). Current mapping, verified in code:

  | Genre (domain) | Games |
  |---|---|
  | memory | faces_of_family, market_basket, my_day |
  | visuospatial | trace_path, lamps_festival, weaving_patterns |
  | executive | sort_harvest |
  | language | name_harvest |
  | attention | sounds_home |

- **Level `L`**: a per-game real number, `L >= 1.0`, stored in steps of `0.5`.
  Level 1 is the gentlest. There is no hard-coded top level (§5.4 explains the soft top).
- **Difficulty `d`**: the existing double passed to `generateItem` and stored in
  `TrialEvents.itemDifficulty`. It is on the same logit scale as `theta`.
- **Level scale** (fixed bijection, used everywhere):

  ```
  d = (L - 5) / 2          L = 5 + 2 * d
  L = 1  -> d = -2.0
  L = 5  -> d =  0.0
  L = 9  -> d = +2.0
  L = 13 -> d = +4.0       (no upper limit)
  ```

  Why this scale: today's games already treat roughly `d` in `[-2, +3]` as their useful
  range, so existing behaviour at a given `d` stays recognisable, and `theta` updates keep
  meaning (the estimator compares `theta` with `d`).
- **Session**: one `Sessions` row. Today every session plays exactly one game
  (`GameScreen` calls `runner.start([game])`), so `Sessions.gameIds` is a single id.
- **Counted play**: a session that lasted at least `minCountedPlaySeconds` (30 s) **or**
  has at least one `TrialEvents` row. Accidental opens are not counted anywhere.
- **Review**: the 4-day analysis of one game that may change its level (§6).
- **Plateau**: the level at which every difficulty axis of a game is at its humane maximum
  (§5.4).

---

## 4. Architecture

### 4.1 New files (all new, nothing existing is replaced)

```
lib/core/progression/
  progression_config.dart      All tunable constants (one place).
  level_scale.dart             levelToDifficulty / difficultyToLevel, rounding helpers.
  difficulty_axis.dart         DifficultyAxis + LevelCurve maths (pure).
  game_level_profiles.dart     One LevelProfile per game id (pure data + formulas).
  trial_scoring.dart           Per-game partial-credit score for a TrialEvent (pure).
  performance_report.dart      GameReport / GenreReport models + builder (pure).
  progression_policy.dart      Review decision rules (pure, no I/O).
  progression_state.dart       GameProgress, ReviewRecord, NudgeState, RestState + JSON.
  progression_repo.dart        Reads/writes progression JSON in AppConfigs.
  play_policy.dart             Variety nudge + daily rest card rules (pure).
  progression_service.dart     Orchestrator used by screens and the session runner.
  difficulty_source.dart       Interface + ThetaDifficultySource + LevelDifficultySource.

test/core/progression/
  level_scale_test.dart
  difficulty_axis_test.dart
  game_level_profiles_test.dart
  trial_scoring_test.dart
  performance_report_test.dart
  progression_policy_test.dart
  progression_repo_test.dart
  play_policy_test.dart
  progression_service_test.dart
test/games/level_generation_test.dart
```

### 4.2 Existing files that change (and only these)

| File | Change | Task |
|---|---|---|
| `lib/core/repo/event_repo.dart` | Add 3 read-only query methods (§4.4). | T3 |
| `lib/games/session_runner.dart` | Optional `DifficultySource`; in-session staircase; add `progression` block to `trialContext`. Default behaviour unchanged. | T6 |
| `lib/games/*/*_game.dart` (9 files) | Replace clamped `xxxFor(difficulty)` helpers with profile-driven parameters. `generateItem` signature unchanged. | T7 |
| `lib/games/market_basket/market_basket_widget.dart` | Read optional `studySeconds` and `delaySeconds` from payload, falling back to today's formulas. | T7 |
| `lib/games/lamps_festival/lamps_widget.dart` | Read optional `litMs` from payload, falling back to 600 ms. | T7 |
| `lib/games/faces_of_family/faces_widget.dart` | Support optional `revealSeconds` (photo hides before choosing). | T7 |
| `lib/games/trace_path/trace_path_widget.dart` | Render optional unnumbered decoy stones (tapping one is ignored, not counted as an error). | T7 |
| `lib/screens/game_screen.dart` | Use `LevelDifficultySource`; call service after session ends; show the rest card or the suggestion line in the end dialog. | T8, T9, T10 |
| `lib/screens/game_select_screen.dart` | Suggestion card, "Try today" ribbon, daily rest card. | T9, T10 |
| `lib/screens/home_screen.dart` | One `unawaited(ProgressionService.instance.runDueReviews())` in `initState`. | T8 |
| `lib/screens/diagnostics_screen.dart` | New caregiver section "Game levels". | T11 |
| `lib/core/auth/pairing_service.dart` | In the existing "different patient" wipe block, also delete `progression.*` keys. | T4 |

### 4.3 Storage (no schema change)

All state is JSON in `AppConfigs` (`key`/`value` text). Keys:

| Key | Value |
|---|---|
| `progression.v1.game.<gameId>` | `GameProgress` JSON (§4.5) |
| `progression.v1.nudge` | `NudgeState` JSON (§8.5) |
| `progression.v1.rest` | `RestState` JSON (§9.3) |
| `progression.v1.settings` | Optional caregiver overrides JSON (§4.6). Missing = defaults. |

`AppConfigsDao` already provides `getValue`, `setValue`, `setAll`, `deleteValue`. Add no
DAO; `ProgressionRepo` uses these. The `v1` segment allows a future format change without
reading old JSON as new.

### 4.4 New read-only queries in `EventRepo`

```dart
/// Trials of one game with ts in [fromMs, toMs), oldest first.
Future<List<TrialEvent>> trialsForGameBetween(String gameId, int fromMs, int toMs);

/// Sessions whose startedAt is in [fromMs, toMs), oldest first.
Future<List<Session>> sessionsBetween(int fromMs, int toMs);

/// gameId -> number of TrialEvents rows per sessionId, for sessions in [fromMs, toMs).
/// Used to decide whether a short session still counts as a play.
Future<Map<String, int>> trialCountsBySessionBetween(int fromMs, int toMs);
```

Implement with Drift `select` / `where` / `orderBy` only. No updates, no deletes. Add a
test in `test/core/repo/event_repo_test.dart` style (in-memory DB via `newTestDb()`).

### 4.5 Data models (`progression_state.dart`)

```dart
enum ReviewDecision { raise, nudgeUp, hold, ease, easeMore, notEnoughData, returning }

class ReviewRecord {
  final int atMs;               // when the review ran
  final int windowFromMs;       // inclusive
  final int windowToMs;         // exclusive
  final int trials;
  final int countedPlays;
  final int distinctDays;
  final double? accuracy;       // 0..1 plain correct rate, null if no trials
  final double? score;          // 0..1 performance score (§6.3), null if no trials
  final double levelBefore;
  final double levelAfter;
  final ReviewDecision decision;
  final bool concern;           // sharp drop, caregiver-only flag (§6.6)
  final bool plateau;           // level at or above the game's plateau
}

class GameProgress {
  final String gameId;
  final double level;              // >= 1.0, multiple of 0.5
  final int? lastReviewAtMs;       // null until the first review
  final int? lastPlayedAtMs;
  final int consecutiveRaiseQualifiers; // for anti-oscillation (§6.5)
  final ReviewDecision? lastDecision;
  final List<ReviewRecord> history;     // newest last, capped at historyLength (12)
  final bool seeded;               // true once the starting level was set (§6.7)
}
```

Both have `toJson()` / `fromJson()`; unknown or corrupt JSON must fall back to a fresh
`GameProgress` (never throw into the UI). Round-trip tests are required.

### 4.6 Settings (`progression_config.dart` + optional override)

```dart
class ProgressionConfig {
  // Review
  static const reviewWindowDays = 4;
  static const reviewEveryDays = 4;
  static const minTrialsPerReview = 8;          // short-trial games
  static const minTrialsLongTask = 3;           // name_harvest, sounds_home (1 trial per play)
  static const minDistinctDaysPerReview = 2;
  static const raiseScore = 0.85;
  static const raiseAccuracy = 0.80;
  static const nudgeUpScore = 0.78;
  static const holdLowScore = 0.60;
  static const easeMoreScore = 0.45;
  static const raiseStep = 1.0;
  static const raiseStepAfterRecentEase = 0.5;
  static const nudgeUpStep = 0.5;
  static const easeStep = 0.5;
  static const easeMoreStep = 1.0;
  static const concernDrop = 0.30;
  static const historyLength = 12;
  static const minLevel = 1.0;
  static const plateauHeadroom = 1.0;           // stored level may exceed plateau by this much
  static const returningAfterDays = 14;
  static const returningStep = 1.0;

  // In-session staircase (§7)
  static const staircaseDownAfterMisses = 2;
  static const staircaseUpAfterHits = 3;
  static const staircaseStep = 0.5;             // in level units
  static const staircaseMaxOffset = 1.0;        // in level units, each direction

  // Counted play
  static const minCountedPlaySeconds = 30;

  // Variety nudge (§8)
  static const nudgeRepeatPlays = 6;            // X
  static const nudgeWindowDays = 3;             // Y
  static const nudgeShareOfPlays = 0.6;
  static const nudgeCooldownHours = 24;
  static const nudgeSnoozeDaysAfterTwoDismissals = 2;

  // Daily rest card (§9)
  static const dailyRestMinutes = 30;           // 0 = never show the rest card
  static const restCardRepeatMinutes = 15;      // after "Keep playing", next reminder
                                                // after this much more play today
}
```

`progression.v1.settings` may override `dailyRestMinutes`, `nudgeRepeatPlays`,
`nudgeWindowDays` and `reviewEveryDays` only. `ProgressionService` reads it once per call
and falls back to the constants for missing or invalid values. Nothing in the elder UI
edits settings; the Diagnostics screen (§11) may.

---

## 5. Levels that generate themselves (G3)

### 5.1 Idea

Each game describes difficulty as several **axes** (for example "items to remember",
"similar distractors", "time to study"). Each axis has a start value at level 1, a rate of
change per level, the level at which it starts moving, and a **humane limit** (what is
still fair and fits on a phone screen for a 70+ year old). Levels are computed from these
formulas at runtime, so there is no table of levels to maintain.

Axes unlock in sequence: when the first axis reaches its limit, the next one starts
moving. This gives many distinct steps of difficulty from a few formulas, and new axes can
be appended later without renumbering anything.

### 5.2 `DifficultyAxis` (`difficulty_axis.dart`)

```dart
enum AxisRounding { none, floor, round }

class DifficultyAxis {
  const DifficultyAxis({
    required this.name,
    required this.start,        // value at startLevel and below
    required this.perLevel,     // change per +1 level after startLevel (may be negative)
    required this.limit,        // humane limit; value never passes it
    this.startLevel = 1.0,
    this.rounding = AxisRounding.none,
  });

  double valueAt(double level) {
    final raw = start + perLevel * math.max(0, level - startLevel);
    final bounded = perLevel >= 0 ? math.min(raw, limit) : math.max(raw, limit);
    switch (rounding) { ... }   // floor/round applied after bounding
  }

  /// First level at which this axis reaches its limit.
  double get saturationLevel => startLevel + (limit - start).abs() / perLevel.abs();
}

class LevelProfile {
  const LevelProfile({required this.gameId, required this.axes});
  final String gameId;
  final List<DifficultyAxis> axes;

  Map<String, double> paramsAt(double level) =>
      {for (final a in axes) a.name: a.valueAt(level)};

  /// Level where every axis is at its limit.
  double get plateauLevel => axes.map((a) => a.saturationLevel).fold(1.0, math.max);
}
```

Probabilistic axes (for example "chance of backward order") are ordinary axes whose value
is a probability; the game rolls against it with its own `Random`, so tests can inject a
seeded `Random` as the games already allow.

### 5.3 Per-game profiles (`game_level_profiles.dart`)

`L` is the level. "Today" shows the current behaviour so the builder can check continuity.
Values marked *(content cap)* are additionally limited by available content at generation
time (for example family size), which the game already knows.

#### market_basket (memory)
| Axis | start | perLevel | startLevel | limit | rounding | Today |
|---|---|---|---|---|---|---|
| listLength | 2 | 0.5 | 1 | 7 | floor | `(3+round(d)).clamp(2,6)` |
| nearDistractors | 0 | 0.5 | 4 | 4 | floor | `round(d).clamp(0,3)` |
| studySecondsPerItem | 1.6 | -0.08 | 8 | 0.9 | none | widget shows `2 + n` seconds |
| delaySeconds | 2 | 0.75 | 10 | 8 | round | widget waits 2 s |

Game changes: `listLength` also capped by `content.marketItems.length`; payload gains
`studySeconds = max(3, round(2 + listLength * studySecondsPerItem))` and `delaySeconds`.
Widget: `Duration(seconds: payload['studySeconds'] as int? ?? 2 + _targets.length)` and
`Duration(seconds: payload['delaySeconds'] as int? ?? 2)`. Plateau about L 14.

#### faces_of_family (memory)
| Axis | start | perLevel | startLevel | limit | rounding |
|---|---|---|---|---|---|
| optionCount | 2 | 0.5 | 1 | 4 | floor *(content cap: living people)* |
| relationshipModeChance | 0 | 0.1 | 6 | 0.5 | none |
| sameRelationshipDistractorChance | 0 | 0.1 | 8 | 0.7 | none |
| revealSeconds | 0 | 0 | 11 | 0 | see note |

Notes:
- `revealSeconds`: 0 below level 11 (photo stays). From level 11, `revealSeconds = max(3, round(8 - (L - 11)))`, floor 3. Implement as a dedicated axis with `start: 8, perLevel: -1, startLevel: 11, limit: 3` and treat "level < 11" as 0 in the game.
- `mode` becomes `recognition` or `relationship` only. The widget already handles
  `relationship`; keep accepting the old strings `recognition_2`, `recognition_3`,
  `free_naming`, `last_contact` in the widget for trials generated before this change.
- The game already requires at least two living people (see `GameScreen`). With a small
  family the content cap limits real difficulty; the review marks such levels as plateau.

#### sort_harvest (executive)
| Axis | start | perLevel | startLevel | limit | rounding |
|---|---|---|---|---|---|
| matCount | 2 | 0.34 | 1 | 4 | floor *(content cap: distinct values)* |
| dimensionCount | 1 | 0.34 | 3 | 3 | floor (1 = type, 2 = +colour, 3 = +size) |
| switchEvery | 8 | -0.5 | 5 | 3 | round |

Game: pick `currentDimension` only among the first `dimensionCount` of
`['type', 'colour', 'size']`; write `switchFrequency` from `switchEvery`. Plateau about L 15.

#### trace_path (visuospatial)
| Axis | start | perLevel | startLevel | limit | rounding |
|---|---|---|---|---|---|
| nodeCount | 4 | 1 | 1 | 15 | round |
| variantBChance | 0 | 0.125 | 8 | 0.75 | none |
| decoyStones | 0 | 0.5 | 13 | 4 | floor |

Decoys: payload list `decoys` of `{x, y}`; widget draws plain stones without a label,
tapping them does nothing and is not counted in `errorsCount`. Keep node positions at
least 64 logical pixels apart (reject-and-retry sampling, max 50 tries, then accept) so
phones stay usable. Plateau about L 20.

#### my_day (memory)
| Axis | start | perLevel | startLevel | limit | rounding |
|---|---|---|---|---|---|
| eventCount | 3 | 0.5 | 1 | 7 | floor *(content cap: routine length)* |
| orientationChance | 0.2 | 0.05 | 1 | 0.6 | none |
| questionTier | 1 | 0.5 | 1 | 5 | floor |
| dateOptionSpread | 2 | -0.25 | 6 | 1 | round |

Question tiers replace `difficulty_min`: tier 1 season, 2 day_of_week, 3 after_lunch and
before_dinner (only when the routine can answer, as today), 4 month, 5 date. A question is
eligible when its tier is `<= questionTier`. `dateOptionSpread` is the +/- range of nearby
dates offered (today `now.day - 2 .. now.day + 2`). The real-routine rule stays: fewer than
3 routine items means orientation only. Plateau about L 10.

#### lamps_festival (visuospatial)
| Axis | start | perLevel | startLevel | limit | rounding |
|---|---|---|---|---|---|
| span | 2 | 0.5 | 1 | 7 | floor |
| lampCount | 5 | 0.5 | 1 | 12 | floor |
| backwardChance | 0 | 0.125 | 9 | 0.75 | none |
| litMs | 600 | -25 | 11 | 400 | round |

Payload gains `litMs`; widget uses it for the "lit" timer (today fixed 600 ms). Plateau
about L 15.

#### name_harvest (language)
| Axis | start | perLevel | startLevel | limit | rounding |
|---|---|---|---|---|---|
| expectedCount | 3 | 0.5 | 1 | 15 | floor |
| categoryTier | 1 | 0.25 | 1 | 3 | floor |

Categories by tier (content, extendable without code changes elsewhere):
tier 1 `fruits, vegetables, animals`; tier 2 adds `things_in_kitchen, things_in_market`;
tier 3 adds `things_that_are_red, festival_foods, birds`. The widget's `_categoryLabel`
map must get labels for new ids ("things that are red", "festival foods", "birds").
`submit` uses `expectedCount` from `item.context['expectedCount']` instead of
`max(3, (5 + d*2).round())`. Duration stays 60 s (it is a standard fluency task).
Plateau about L 25.

#### weaving_patterns (visuospatial)
| Axis | start | perLevel | startLevel | limit | rounding |
|---|---|---|---|---|---|
| elementCount | 3 | 0.5 | 1 | 8 | floor |
| distractorSimilarity | 0 | 0.1 | 1 | 1.0 | none |
| patternTypeTier | 1 | 0.34 | 1 | 3 | floor |

Tiers: 1 `stripes, dots`; 2 adds `diamonds, crosses`; 3 adds `zigzag, chevron`.
Plateau about L 11.

#### sounds_home (attention)
| Axis | start | perLevel | startLevel | limit | rounding |
|---|---|---|---|---|---|
| targetFrequency | 0.30 | -0.02 | 1 | 0.12 | none |
| isiMinMs | 3000 | -150 | 1 | 1500 | round |
| isiMaxMs | 5000 | -150 | 1 | 2500 | round |
| lureChance | 0 | 0.05 | 6 | 0.3 | none |

Lures: when a stimulus is not a target, with `lureChance` pick from the similar set
`['rooster', 'cricket']` (bird-like) and for the bell family `['bell', 'temple_bell']`;
otherwise from the full distractor list. Duration stays 90 s. Plateau about L 12.

### 5.4 Soft top, not a hard cap

- Stored level may rise above `plateauLevel` by at most `plateauHeadroom` (1.0). This
  prevents a level of 40 after months of mastery, which would take many reviews to come
  back down if the elder declines.
- At or above plateau the game keeps generating fresh random combinations (new lists,
  positions, patterns, questions), so play does not become repetitive.
- A review at plateau with a raise decision records `plateau: true` and keeps the level.
  The Diagnostics screen shows "At the top of this game" so the caregiver can suggest the
  elder moves on or the team can add an axis later (append only, see §5.5).

### 5.5 Adding difficulty later without maintenance breaks

- New axis: append to the profile with a `startLevel` above the current plateau. Existing
  elders keep their level; the new axis simply becomes available.
- New game: add it to `game_catalog.dart`, add one `LevelProfile`, add a scorer in
  `trial_scoring.dart`. Nothing else changes.
- Never renumber or reorder existing axes, and never change the level scale in §3.

### 5.6 How games read levels

Each game file adds:

```dart
static final LevelProfile profile = GameLevelProfiles.marketBasket; // per game

@override
GameItem generateItem(double difficulty, GameContent content) {
  final level = LevelScale.difficultyToLevel(difficulty);
  final p = profile.paramsAt(level);
  // use p['listLength']!.toInt() etc.
  // put 'level': level into context (in addition to existing keys)
}
```

Keep the existing public static helpers (`listLengthFor`, `spanFor`, and so on) but
reimplement them through the profile, so any caller or test using them keeps compiling.
`itemDifficulty` in `TrialResult` stays `item.difficulty`.

---

## 6. The 4-day review (G2)

### 6.1 When reviews run

`ProgressionService.runDueReviews({DateTime? now})`:
- Called (unawaited) from `HomeScreen.initState` and after every session ends
  (`GameScreen._endSession`, after `runner.end`).
- Guarded by an in-memory `Future` so concurrent calls share one run.
- For each game in `gameCatalog`:
  - If `lastReviewAtMs == null`: set it to `now` when the game is first played (do not
    review before any play).
  - Due when `now - lastReviewAtMs >= reviewEveryDays` (4 days).
  - If the device clock moved backwards (`lastReviewAtMs > now`), set
    `lastReviewAtMs = now` and skip.
  - Runs at most **one** review per game per call, even if the device was off for weeks.
- Must complete in under 200 ms for 5,000 trials on a low-end phone (queries are indexed
  by the time range; if needed, add a `ts` filter first, then filter by `gameId` in Dart).
- Wrap everything in `try/catch`; a review failure is logged with `debugPrint` and never
  surfaces in the UI.

### 6.2 Window

`windowToMs = now`, `windowFromMs = now - 4 days`. Load:
- `trialsForGameBetween(gameId, from, to)`
- `sessionsBetween(from, to)` filtered to `gameIds == gameId`, plus
  `trialCountsBySessionBetween` to decide counted plays.

### 6.3 Per-game report (`performance_report.dart`)

For the game's trials:

| Field | Definition |
|---|---|
| `trials` | number of rows |
| `countedPlays` | sessions of this game that count (§3) |
| `distinctDays` | distinct local calendar dates of trial `ts` |
| `accuracy` | `correct == true` count / trials |
| `partialCredit` | mean of `TrialScoring.score(trial)` (§6.4), 0..1 |
| `hintRate` | share of trials with `hintLevel > 0` |
| `speedScore` | see below, 0..1 |
| `abandonRate` | share of this game's counted plays with `completed == false` and `abandonedAtMs < 120000` |
| `meanLevel` | mean of `trialContext.progression.level` where present, else from `itemDifficulty` via level scale |

`speedScore`: take the elder's median `responseTimeMs` for this game in the **previous**
review window (from `history`), `prev`, and this window's median, `cur`.
`speedScore = clamp(0.5 + 0.5 * (prev - cur) / prev, 0, 1)`; if there is no previous
window use `0.5`. Speed can only tilt a decision, never drive it alone.

**Performance score**
```
score = 0.65 * partialCredit
      + 0.15 * (1 - hintRate)
      + 0.10 * speedScore
      + 0.10 * (1 - abandonRate)
```

### 6.4 Per-game partial credit (`trial_scoring.dart`)

`metrics` and `trialContext` are JSON strings on the row; decode defensively (bad JSON
means fall back to `correct ? 1 : 0`).

| Game | score(trial) |
|---|---|
| market_basket | `metrics.targets > 0 ? clamp(1 - (missed + intrusions) / targets, 0, 1) : correct` |
| faces_of_family | `correct ? 1 : 0` |
| sort_harvest | `correct ? 1 : 0` |
| trace_path | `completed errors == 0 -> 1`, else `clamp(1 - errors / context.nodeCount, 0, 1)` |
| my_day | ordering: `clamp(1 - metrics.misplaced / metrics.event_count, 0, 1)`; orientation: `correct` |
| lamps_festival | `context.span > 0 ? metrics.span_achieved / context.span : correct` |
| name_harvest | `clamp(metrics.items_named / context.expectedCount, 0, 1)` (use `max(3, (5 + itemDifficulty*2).round())` when `expectedCount` is absent, matching old trials) |
| weaving_patterns | `correct ? 1 : 0` |
| sounds_home | `targets = hits + misses`; `hitRate = targets > 0 ? hits / targets : 1`; `faRate = false_alarms / max(1, context.stimuliCount - context.targetCount)`; `clamp(hitRate - 0.5 * faRate, 0, 1)` |

### 6.5 Decision rules (`progression_policy.dart`, pure)

Inputs: `GameProgress` before, `GameReport`, `LevelProfile`, config, `now`.

1. **Returning after a break.** If `lastPlayedAtMs` is older than `returningAfterDays`
   (14) at the time of the first counted play after the break, apply
   `level = max(minLevel, level - returningStep)` once, decision `returning`. (Done in
   `onSessionStarted`, see §6.8, not in the scheduled review.)
2. **Not enough data.** Required trials: `minTrialsLongTask` (3) for `name_harvest` and
   `sounds_home`, otherwise `minTrialsPerReview` (8). Also require
   `distinctDays >= minDistinctDaysPerReview` (2). If not met: decision `notEnoughData`,
   level unchanged, **do not** move `lastReviewAtMs` forward by 4 days; instead set it to
   `now - (reviewEveryDays - 1) days` so the next check is tomorrow. Record the review.
3. **Score bands** (first match wins):

   | Condition | Decision | New level |
   |---|---|---|
   | `score >= raiseScore (0.85)` and `accuracy >= raiseAccuracy (0.80)` | `raise` (subject to rule 4) | `+raiseStep (1.0)`, or `+0.5` if any of the last 2 decisions was `ease`/`easeMore` |
   | `score >= nudgeUpScore (0.78)` and last decision was `hold` or `nudgeUp` | `nudgeUp` | `+0.5` |
   | `score >= holdLowScore (0.60)` | `hold` | unchanged |
   | `score >= easeMoreScore (0.45)` | `ease` | `-0.5` |
   | otherwise | `easeMore` | `-1.0` |

   Easing is deliberately faster than raising: frustration costs a dementia patient more
   than an easy session does.
4. **Anti-oscillation.** If the previous decision was `ease` or `easeMore`, a `raise`
   needs two qualifying reviews in a row: increment `consecutiveRaiseQualifiers`; raise
   only when it reaches 2, otherwise record `hold`. Reset the counter on any non-raise
   decision.
5. **Bounds.** `level = clamp(level, minLevel, plateauLevel + plateauHeadroom)`, then round
   to the nearest 0.5. If a raise was blocked by the upper bound, set `plateau: true`.
6. **Save.** Append `ReviewRecord`, trim history to 12, set `lastReviewAtMs = now`,
   `lastDecision`, write JSON.

### 6.6 Concern flag (caregiver only)

`concern = true` when there is a previous scored review and
`previous.score - score >= concernDrop (0.30)` with enough data in both windows. It does
not change the level beyond the band rules. It is shown only on Diagnostics (§11) and
added to the next trials' `trialContext.progression.concern` so the caregiver web app can
see it through the existing sync. Never shown to the elder.

### 6.7 Starting level (first play of a game)

On the first session of a game (`seeded == false`), in this order:
1. **Genre average:** if other games of the same domain have `seeded == true`, start at
   the mean of their levels minus 1.0 (a new game should feel easy), rounded to 0.5.
2. **Theta:** otherwise
   `L0 = LevelScale.difficultyToLevel(AbilityEstimator.nextDifficulty(theta))` using
   `AbilityRepo.getOrSeed(domain)` (theta is already demographically seeded at pairing).
3. Clamp `L0` to `[1.0, 4.0]`, set `seeded = true`, save.

### 6.8 Genre (domain) report

`GenreReport` aggregates the latest window of all games in a domain: total trials, mean
score weighted by trials, number of games played, games with `concern`. Used for:
- seeding new games (§6.7);
- nudge target choice (§8.4);
- the Diagnostics "by genre" table (§11).

It never changes a game's level directly.

---

## 7. Within-session staircase

The review is slow by design. Inside one session the elder still needs quick relief if a
level is too hard today.

`LevelDifficultySource` (in `difficulty_source.dart`) keeps an in-memory `offset` (level
units), starting at 0 each session:
- After `staircaseDownAfterMisses` (2) incorrect trials in a row: `offset -= 0.5`.
- After `staircaseUpAfterHits` (3) correct trials in a row: `offset += 0.5`.
- `offset` stays in `[-1.0, +1.0]`; effective level never below `minLevel`.
- The offset is **not saved**. Only the 4-day review changes the stored level.

```dart
abstract class DifficultySource {
  Future<double> difficultyFor(CognitiveGame game);
  void onTrial(CognitiveGame game, TrialResult result);
  Map<String, Object?> contextFor(CognitiveGame game); // merged into trialContext
}

/// Today's behaviour, unchanged: nextDifficulty(theta) from AbilityRepo.
class ThetaDifficultySource implements DifficultySource { ... }

class LevelDifficultySource implements DifficultySource {
  LevelDifficultySource(this.service);
  // difficultyFor: service.levelFor(game.id) + offset -> LevelScale.levelToDifficulty
  // contextFor: {'progression': {'level': stored, 'offset': offset,
  //              'effectiveLevel': ..., 'concern': latestConcern, 'v': 1}}
}
```

`SessionRunner` changes:
- New optional constructor parameter `DifficultySource? difficultySource`; when null use
  `ThetaDifficultySource(abilityRepo)`. **Existing tests construct the runner without it
  and must pass unchanged**, including "difficulty tracks the estimate".
- `nextItem` asks the source for the difficulty instead of calling
  `AbilityEstimator.nextDifficulty` directly. `_thetaBefore` is still read from
  `abilityRepo.getOrSeed` exactly as today.
- `_recordTrial` still calls `abilityRepo.applyTrial` (theta stays updated for reports and
  seeding), then calls `difficultySource.onTrial`.
- `trialContext` becomes `jsonEncode({...item.context, ...difficultySource.contextFor(game)})`.
  With `ThetaDifficultySource`, `contextFor` returns `{}` so rows are byte-identical to today.

---

## 8. Variety nudge (G4)

### 8.1 Rule

For game `G`, over the last `nudgeWindowDays` (Y = 3) days of **counted plays**:
- `playsG >= nudgeRepeatPlays` (X = 6), and
- `playsG / allPlays >= nudgeShareOfPlays` (0.6), and
- at least one other eligible game (§8.3) has **0** counted plays in the window.

Then `G` is "a favourite" and a suggestion is available.

### 8.2 Where it appears

1. **Game select screen**: a soft suggestion card above the game list (only when a
   suggestion is available and not in cooldown).
2. **End-of-session card** in `GameScreen` for the favourite game: one extra line and a
   secondary button under "Back to Games".
3. **Suggested game highlight**: the suggested game's tile gets a small "Try today"
   ribbon (marigold background, dark text, star icon).

It never blocks play. The elder can always play the favourite game.

### 8.3 Eligible games

Exclude a game when it cannot be played meaningfully right now:
- `faces_of_family` when fewer than 2 living people;
- the game is the favourite itself.
`my_day` stays eligible (it falls back to calendar questions without a routine).

### 8.4 Choosing the suggestion

1. Among eligible games, pick the domain with the fewest trials in the last 7 days
   (`GenreReport`), preferring domains different from the favourite's.
2. Within that domain, pick the game with the oldest `lastPlayedAtMs` (never played counts
   as oldest).
3. Tie: `gameCatalog` order.

### 8.5 Cooldown and dismissals (`NudgeState`)

```dart
class NudgeState {
  final String? lastFavouriteId;
  final String? lastSuggestedId;
  final int? lastShownAtMs;
  final int dismissStreak;      // "Maybe later" taps in a row
  final int? snoozedUntilMs;
}
```
- Show at most once per `nudgeCooldownHours` (24 h) per favourite.
- "Maybe later" increments `dismissStreak`; at 2, set `snoozedUntilMs = now + 2 days` and
  reset the streak.
- Tapping the suggested game resets `dismissStreak` to 0.

### 8.6 Look and feel (elderly-safe)

- Card background: soft marigold tint (`Color.lerp(AppColors.marigold, Colors.white, 0.8)`),
  no border in red, no warning or error icon. Leading icon: `Icons.lightbulb_rounded` in a
  medallion, or the suggested game's own icon.
- Text at least 20 sp, one short sentence plus one line.
- Two large buttons, each at least 60 dp tall:
  primary in the suggested game's colour ("Try Lamps of the Festival"),
  secondary text button ("Maybe later").
- `FadeSlideIn` entrance only; no shaking, flashing or sound.
- Copy in §10.

---

## 9. Daily rest card (G5)

A gentle reminder to take a break. It is advice, never a lock: every game stays playable
all day, and the elder can close the card with one tap.

### 9.1 Measuring play time today

`playSecondsToday(now)` = sum over `Sessions` whose `startedAt` is on today's local date
(midnight to now, `DateTime(now.year, now.month, now.day)`):

| Session state | Seconds counted |
|---|---|
| Ended normally (`endedAt != null`, `completed == true`) | `(endedAt - startedAt) / 1000` |
| Ended early (`abandonedAtMs != null`) | `abandonedAtMs / 1000` |
| Still open (`endedAt == null`), not the current session | 0 (app was killed mid-session; ignore) |

Each session's contribution is capped at 8 minutes (the 6-minute session cap plus the end
card), so a clock change or a crash can never inflate the total. A session that started
before midnight counts entirely toward the day it started.

Implement with `EventRepo.sessionsBetween(startOfToday, now)` (§4.4). This counts all
games together.

### 9.2 When the card appears

Threshold `T = dailyRestMinutes` (30, caregiver-adjustable, `0` turns the card off).

1. **At the end of a session** (`GameScreen._endSession`, after `runner.end`): if
   `playSecondsToday >= T * 60` and the card is due (§9.3), the end-of-session dialog
   shows the rest card content in place of the usual "Back to Games" layout (§9.4).
2. **When the game select screen opens or becomes visible again**: if the card is due,
   show it as a dismissible card at the top of the list.
3. **Never during a round.** The card never interrupts a game in progress. The 6-minute
   session cap already bounds a single session.

If both the rest card and the variety suggestion (§8) are due at the same moment, show
**only the rest card**. The suggestion waits for the next opportunity (one message at a
time keeps things calm).

### 9.3 Not repeating too often (`RestState`)

Stored in `AppConfigs` key `progression.v1.rest`:

```dart
class RestState {
  final String dayKey;              // 'yyyy-MM-dd' local; a new day resets everything
  final int? nextDueAtSeconds;      // play seconds today at which the card is next due
  final int shownCount;             // times shown today
  final int keptPlayingCount;       // "Keep playing" taps today (caregiver info only)
}
```

- New day (`dayKey` differs): reset to `nextDueAtSeconds = T * 60`, counts 0.
- Due when `playSecondsToday >= nextDueAtSeconds`.
- On **"Keep playing"**: `nextDueAtSeconds = playSecondsToday + restCardRepeatMinutes * 60`
  (so the next gentle reminder is after about 15 more minutes of play, for example at 45,
  then 60 minutes), `keptPlayingCount++`.
- On **"Rest now"**: same update as above (if the elder comes back later, the reminder
  still waits for 15 more minutes of play), then navigate to Home
  (`Navigator.of(context).popUntil((r) => r.isFirst)`).
- Closing the card any other way (back gesture, tapping outside) counts as "Keep playing".
- `shownCount++` each time it is shown.

### 9.4 Look and feel

- Soft leaf-green tint background (`Color.lerp(AppColors.leafGreen, Colors.white, 0.85)`),
  rounded 28, no border colour in red, no warning, error, timer or hourglass icon.
- Leading medallion with `Icons.local_cafe_rounded` (a cup of tea) in leaf green.
- Title at least 26 sp, body at least 20 sp, one or two short sentences.
- Two large buttons, each at least 64 dp tall, full width on phones:
  primary "Rest now" (leaf green), secondary "Keep playing" (outlined, calm colour).
- `FadeSlideIn` entrance only; no sound, vibration, flashing or countdown.
- The play-time figure is shown in whole minutes rounded **down to the nearest 5** (for
  example 34 minutes shows as "30 minutes") so the number stays simple and never looks
  like a stopwatch.

### 9.5 API

```dart
class RestAdvice {
  final bool show;
  final int minutesToday;         // rounded down to nearest 5 for display
}

Future<RestAdvice> ProgressionService.restAdvice({DateTime? now});
Future<void> ProgressionService.onRestCardAnswered({required bool keepPlaying, DateTime? now});
```

---

## 10. Elder-facing copy (exact strings)

No em dashes. No "wrong", "limit", "blocked", "too long", "stop", "failed", "error". Use the elder's own
game names from `gameCatalog`.

| Place | Text |
|---|---|
| Suggestion card title | `You really enjoy {favourite}!` |
| Suggestion card line | `How about trying {suggested} today? It is good for the mind to play different games.` |
| Suggestion primary button | `Try {suggested}` |
| Suggestion secondary button | `Maybe later` |
| End dialog extra line | `Would you like to try {suggested} next?` |
| End dialog extra button | `Try {suggested}` |
| Ribbon on suggested tile | `Try today` |
| Rest card title | `Time for a little rest` |
| Rest card line | `You have played for {minutes} minutes today. Well done! How about a cup of tea or a short walk?` |
| Rest card primary button | `Rest now` |
| Rest card secondary button | `Keep playing` |

Level changes are **not** announced to the elder. Optional, default off
(`showLevelUpMessage = false`): after a raise, the next session's end card may add
`This game is growing with you.` Never announce an ease.

---

## 11. Caregiver view (Diagnostics screen)

Add a section **"Game levels"** below "Game Play Activity" in
`lib/screens/diagnostics_screen.dart` (caregiver-only, already hidden behind the 5-tap):

- One row per game: name, level (for example `6.5`), plateau level, last review date,
  last decision in plain words (`Raised`, `Kept the same`, `Made easier`, `Not enough play
  yet`, `Welcome back, eased`), last score as a percentage, trials in the last window, and
  a small "Needs attention" text if `concern` (neutral colour, this is a caregiver screen).
- "By genre" mini table: domain, games played, weighted score.
- Buttons: `Run review now` (calls `runDueReviews(force: true)`, which ignores the 4-day
  timer but still needs enough data), `Reset level` per game (sets level to the §6.7 start
  value after a confirm dialog), and a number field "Rest reminder after (minutes)" for
  `dailyRestMinutes`, where 0 turns it off (writes `progression.v1.settings`).
- Today's play: total minutes played today, times the rest card was shown today, and
  times "Keep playing" was chosen (from `progression.v1.rest`). Informational only.

---

## 12. Sync and backend

- No new remote tables or columns.
- The caregiver web app receives level information through the existing `trial_context`
  JSON on every synced trial: `{"progression": {"v": 1, "level": 6.5, "offset": -0.5,
  "effectiveLevel": 6.0, "concern": false}}`.
- Review history stays on the device. If the web app later needs it, that is a separate
  backend task (new table or RPC) and is **out of scope** here.
- Re-pairing to a **different** patient must delete all `progression.v1.*` keys inside the
  existing wipe block in `PairingService._completePairing` (add a
  `ProgressionRepo.clearAll()` call or delete the keys directly via `configs`). Re-pairing
  the same patient keeps them.

---

## 13. Build order (tasks)

Each task: files allowed, work, acceptance. Commit after each.

### T1. Config, level scale, axes
Files: `progression_config.dart`, `level_scale.dart`, `difficulty_axis.dart`, tests.
Acceptance:
- `levelToDifficulty(difficultyToLevel(x)) == x` for x in [-3, 10].
- `valueAt` respects start, startLevel, limit and rounding, for rising and falling axes.
- `saturationLevel` and `plateauLevel` correct on hand-computed examples.

### T2. Profiles and scorers
Files: `game_level_profiles.dart`, `trial_scoring.dart`, tests.
Acceptance:
- Every id in `gameCatalog` has a profile and a scorer (test iterates the catalogue).
- For every profile, parameters are monotone in the intended direction from L 1 to L 40
  and never pass limits.
- Scorer examples from §6.4 including malformed JSON fallbacks.

### T3. Event repo queries
Files: `lib/core/repo/event_repo.dart`, `test/core/repo/event_repo_test.dart` (add tests only).
Acceptance: time-range boundaries (inclusive from, exclusive to), ordering, game filter,
trial counts per session. No existing test changes.

### T4. State models and repo
Files: `progression_state.dart`, `progression_repo.dart`,
`lib/core/auth/pairing_service.dart` (wipe keys only), tests.
Acceptance: JSON round trip; corrupt JSON gives defaults; history capped at 12;
`clearAll` removes only `progression.v1.*` keys; different-patient re-pair clears them
(extend the existing pairing test pattern with an in-memory DB).

### T5. Report and policy (pure)
Files: `performance_report.dart`, `progression_policy.dart`, tests.
Acceptance (table-driven tests):
- Each score band gives the right decision and step.
- Not-enough-data by trials and by distinct days; `lastReviewAtMs` handling per §6.5.2.
- Anti-oscillation: ease then two high reviews gives hold then raise.
- Upper bound and plateau flag; lower bound at 1.0; 0.5 rounding.
- Concern flag on a 0.30 drop.
- Starting level from genre average, then from theta, clamped to [1, 4].

### T6. Difficulty source and session runner
Files: `difficulty_source.dart`, `lib/games/session_runner.dart`, tests.
Acceptance:
- **All existing `test/games/session_runner_test.dart` tests pass without edits.**
- New tests: with `LevelDifficultySource`, difficulty equals `levelToDifficulty(level)`;
  two misses lower the next item by 0.5 level; three hits raise it; offset bounded;
  `trialContext` contains the `progression` block; with the default source,
  `trialContext` equals `jsonEncode(item.context)` exactly.

### T7. Games use profiles
Files: the 9 `*_game.dart` files and the 4 widgets listed in §4.2,
`test/games/level_generation_test.dart`.
Acceptance:
- `generateItem` at levels 1, 5, 10, 20, 40 for every game returns valid items using
  the mock content plus a synthetic family of 5 people and a routine of 6 items.
- Parameters in `item.context` match `profile.paramsAt(level)` (after content caps).
- Old payload keys still present; widgets fall back when new keys are absent.
- No layout overflow at 412x915 and 1280x800 for levels 1 and 40
  (render each widget in a widget test and assert `tester.takeException()` is null).

### T8. Service and wiring
Files: `progression_service.dart`, `lib/screens/game_screen.dart`,
`lib/screens/home_screen.dart`, tests.
Work:
- `ProgressionService` singleton (`ProgressionService.instance`, overridable constructor
  taking `SmritiDatabase`, `DateTime Function() now` for tests).
- Methods: `levelFor(gameId)`, `onSessionStarted(gameId)` (seed + returning rule),
  `onSessionEnded(gameId)` (update `lastPlayedAtMs`, then `runDueReviews`),
  `runDueReviews({bool force = false})`, `reportsFor(...)`.
- `GameScreen` builds `SessionRunner(..., difficultySource: LevelDifficultySource(service))`.
Acceptance: service test with a fake clock covering: first play seeds; 4 days of good play
raises; 4 days of poor play eases; device off 20 days then play applies returning ease
once; concurrent `runDueReviews` calls run once.

### T9. Daily rest card
Files: `play_policy.dart`, `progression_state.dart` (add `RestState`), service methods
`restAdvice` and `onRestCardAnswered`, `lib/screens/game_select_screen.dart`,
`lib/screens/game_screen.dart`, tests.
Acceptance:
- Play-time sum per §9.1: completed, abandoned and still-open sessions; 8-minute cap per
  session; sessions from yesterday excluded; a session started at 23:58 counts for its
  start day.
- Card due at 30 minutes; "Keep playing" moves the next reminder to +15 minutes of play;
  new day resets; `dailyRestMinutes = 0` never shows.
- Rest card wins over the suggestion when both are due; suggestion shows next time.
- Widget tests: the end-of-session dialog shows `Time for a little rest` when due; the
  select screen shows the card; "Keep playing" closes it and the game list stays fully
  usable; "Rest now" returns to the first route.
- **No game is ever blocked**: with 120 minutes played, tapping any game tile still
  pushes `GameScreen` and `runner.start` is still called.
- No `Icons.error*`, `Icons.warning*`, `Icons.timer*`, `Icons.hourglass*` or red colours in
  these widgets (assert by searching the widget tree).

### T10. Variety nudge
Files: `play_policy.dart`, service method `suggestionFor`, `game_select_screen.dart`,
`game_screen.dart`, tests.
Acceptance: X in Y days rule and share rule; eligible filtering; choice order; 24 h
cooldown; two dismissals snooze 2 days; card and ribbon visible in a widget test; copy
exactly as §10.

### T11. Diagnostics section
Files: `lib/screens/diagnostics_screen.dart`.
Acceptance: section renders with empty state and with seeded progress; "Run review now"
and "Reset level" work against an in-memory DB.

### T12. Final checks
- `flutter analyze`: no issues.
- `flutter test`: all pass except the one pre-existing failure named in §0.
- Grep new UI strings for the em dash character: none.
- Manual run on a real Android phone: set "Rest reminder after" to 5 minutes in
  Diagnostics, play one session, see the rest card, tap "Keep playing" and confirm games
  still start; set the device clock 4 days ahead with trials present, open the app,
  confirm the level changed in Diagnostics.

---

## 14. Worked example

Elder plays Market Basket at level 5 (`d = 0`): list of 4 items, 0 to 1 near distractors.

| Day | Plays | Trials | Notes |
|---|---|---|---|
| 1 | 2 | 10 | mostly all items found |
| 2 | 1 | 5 | |
| 3 | 6 | 30 | about 34 minutes of play: the rest card appears after the 5th session; the elder taps Keep playing and plays once more |
| 4 | 2 | 9 | |

Review on day 5: trials 54, distinct days 4, accuracy 0.87, partial credit 0.92, hint rate
0.05, speed 0.55, abandon 0.0.
`score = 0.65*0.92 + 0.15*0.95 + 0.10*0.55 + 0.10*1.0 = 0.895` -> `raise` -> level 6.0
(list still 4 items, near distractors 1; the next raise to 7 gives 5 items).

Same elder, the following 4 days after a hard week: accuracy 0.55, partial credit 0.62,
hints 0.30, speed 0.40, abandon 0.20.
`score = 0.403 + 0.105 + 0.04 + 0.08 = 0.628` -> `hold` (0.60 to 0.78). Level stays 6.0.
If the score had been 0.50 -> `ease`, level 5.5. A later 0.9 would first record `hold`
(anti-oscillation) and raise on the second qualifying review.

Meanwhile the elder played Market Basket 7 times in 3 days and nothing else: the game
select screen shows "You really enjoy Market Basket! How about trying Trace the Path
today?" because visuospatial had the fewest trials in 7 days and Trace the Path was never
played.

---

## 15. Decisions to confirm with the product owner

These are built as described unless the owner says otherwise:

1. **No hard limits on play.** The owner chose a soft daily rest card over any lock:
   after 30 minutes of play in a day (all games together) a closable card suggests a
   break, repeating after every 15 more minutes if the elder keeps playing. No game is
   ever blocked. The 6-minute per-session cap that already exists stays as it is.
2. **Default numbers.** Variety suggestion when one game is played 6 or more times in
   3 days (confirmed by the owner) and makes up at least 60% of plays; rest card at
   30 minutes, repeat every 15; review every 4 days over a 4-day window.
3. **Storing state in `AppConfigs`** under new `progression.v1.*` keys (no schema change,
   no backend change). The alternative, a new Drift table plus a Supabase table, needs a
   schema migration and backend work and is out of scope.
4. **Level changes are silent for the elder** (optional gentle message stays off).
