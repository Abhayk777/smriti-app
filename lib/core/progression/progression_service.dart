import '../ability/estimator.dart';
import '../db/app_database.dart';
import '../db/database.dart';
import '../repo/ability_repo.dart';
import '../repo/content_repo.dart';
import '../repo/event_repo.dart';
import 'difficulty_source.dart';
import 'game_level_profiles.dart';
import 'level_scale.dart';
import 'performance_report.dart';
import 'play_policy.dart';
import 'progression_config.dart';
import 'progression_policy.dart';
import 'progression_repo.dart';
import 'progression_state.dart';

/// A suggestion to try a different game when one game has become a repeat
/// favourite (docs/PROGRESSION_PLAN.md §8).
class VarietySuggestion {
  const VarietySuggestion({
    required this.favouriteGameId,
    required this.suggestedGameId,
  });

  final String favouriteGameId;
  final String suggestedGameId;
}

/// Whether the elder should be shown a gentle rest reminder right now
/// (docs/PROGRESSION_PLAN.md §9.5). Advice, never a lock: every game stays
/// playable regardless of [show].
class RestAdvice {
  const RestAdvice({required this.show, required this.minutesToday});

  final bool show;

  /// Whole minutes played today, rounded down to the nearest 5.
  final int minutesToday;
}

/// Every game id and the cognitive domain it belongs to
/// (docs/PROGRESSION_PLAN.md §3). Duplicated here, rather than imported from
/// `lib/games/game_catalog.dart`, because `lib/core/` must never depend on
/// `lib/games/` (docs/APP-BUILD-SPEC.md §4's layering: UI/games sit above
/// repositories, not below them). Keep in sync with `game_catalog.dart` and
/// `GameLevelProfiles.byGameId` if a game is ever added or removed.
const Map<String, CognitiveDomain> kGameDomains = {
  'faces_of_family': CognitiveDomain.memory,
  'market_basket': CognitiveDomain.memory,
  'my_day': CognitiveDomain.memory,
  'trace_path': CognitiveDomain.visuospatial,
  'lamps_festival': CognitiveDomain.visuospatial,
  'weaving_patterns': CognitiveDomain.visuospatial,
  'sort_harvest': CognitiveDomain.executive,
  'name_harvest': CognitiveDomain.language,
  'sounds_home': CognitiveDomain.attention,
};

/// Orchestrates progressive game levels: the 4-day review
/// (docs/PROGRESSION_PLAN.md §6), the in-session staircase's data source
/// (§7, via [GameLevelSource]), and the starting level and returning-ease
/// rules (§6.7, §6.5 rule 1).
///
/// Construct with no arguments for real use (reads/writes the on-device
/// database and the real clock), or with [db] and [now] overridden for
/// tests. [ProgressionService.instance] is the shared instance screens use;
/// tests normally construct their own instance instead of touching it.
class ProgressionService implements GameLevelSource {
  ProgressionService({
    SmritiDatabase? db,
    DateTime Function()? now,
    ContentRepo? contentRepo,
  })  : db = db ?? appDatabase,
        _now = now ?? DateTime.now,
        repo = ProgressionRepo(db ?? appDatabase),
        eventRepo = EventRepo(db ?? appDatabase),
        abilityRepo = AbilityRepo(db ?? appDatabase),
        contentRepo = contentRepo ?? ContentRepo(db ?? appDatabase);

  static ProgressionService? _instance;

  /// The shared instance used by screens. Tests should construct their own
  /// instance instead, so they never touch the on-device database or
  /// real clock; production code may still assign a fresh instance here
  /// (for example after re-pairing) if a clean cache is ever needed.
  static ProgressionService get instance => _instance ??= ProgressionService();

  static set instance(ProgressionService value) => _instance = value;

  final SmritiDatabase db;
  final ProgressionRepo repo;
  final EventRepo eventRepo;
  final AbilityRepo abilityRepo;
  final ContentRepo contentRepo;
  final DateTime Function() _now;

  /// In-memory cache of every game touched this run, so [levelFor] and
  /// [concernFor] can be synchronous (required by [GameLevelSource], read
  /// from inside a running session). Populated by [onSessionStarted] and by
  /// [runDueReviews].
  final Map<String, GameProgress> _cache = {};

  /// De-duplicates concurrent [runDueReviews] calls so they run once.
  Future<void>? _runningReviews;

  static const int _dayMs = Duration.millisecondsPerDay;

  // ── GameLevelSource (read by LevelDifficultySource mid-session) ─────────

  @override
  double levelFor(String gameId) =>
      _cache[gameId]?.level ?? ProgressionConfig.minLevel;

  @override
  bool concernFor(String gameId) {
    final history = _cache[gameId]?.history;
    if (history == null || history.isEmpty) return false;
    return history.last.concern;
  }

  // ── Session lifecycle ────────────────────────────────────────────────────

  /// Call once, before a session of [gameId] starts. Seeds the game's
  /// starting level on its first play (docs/PROGRESSION_PLAN.md §6.7), eases
  /// it once if the elder is returning after a long break (§6.5 rule 1), and
  /// primes the in-memory cache so [levelFor] has an answer for the session
  /// about to run. Returns the level the session will play at.
  Future<double> onSessionStarted(String gameId) async {
    var progress = await _reload(gameId);
    final nowMs = _now().millisecondsSinceEpoch;

    if (!progress.seeded) {
      progress = progress.copyWith(
        level: await _startingLevelFor(gameId),
        seeded: true,
      );
    }

    progress = ProgressionPolicy.applyReturningEaseIfDue(progress, nowMs: nowMs);

    // The 4-day review cycle starts counting from the first play, not from
    // pairing (docs/PROGRESSION_PLAN.md §6.1).
    if (progress.lastReviewAtMs == null) {
      progress = progress.copyWith(lastReviewAtMs: nowMs);
    }

    await _save(progress);
    return progress.level;
  }

  /// Call once, after a session of [gameId] ends (however it ended).
  /// Records that the game was just played, then checks whether any game is
  /// due for its 4-day review.
  Future<void> onSessionEnded(String gameId) async {
    final progress = await _load(gameId);
    await _save(progress.copyWith(lastPlayedAtMs: _now().millisecondsSinceEpoch));
    await runDueReviews();
  }

  // ── The 4-day review ─────────────────────────────────────────────────────

  /// Reviews every game whose 4-day cycle is due. Concurrent calls share one
  /// run. Safe to call often (for example on every app foreground): a game
  /// that isn't due, or has never been played, is skipped cheaply.
  Future<void> runDueReviews({bool force = false}) {
    return _runningReviews ??= _runDueReviewsImpl(force).whenComplete(() {
      _runningReviews = null;
    });
  }

  Future<void> _runDueReviewsImpl(bool force) async {
    final settings = await repo.getSettings();
    final reviewEveryMs = settings.effectiveReviewEveryDays * _dayMs;
    final nowMs = _now().millisecondsSinceEpoch;

    for (final gameId in kGameDomains.keys) {
      try {
        final progress = await _load(gameId);
        final lastReviewAtMs = progress.lastReviewAtMs;
        if (lastReviewAtMs == null) continue; // never played; nothing to review

        final due = force || (nowMs - lastReviewAtMs) >= reviewEveryMs;
        if (!due) continue;

        await _reviewOne(gameId, progress, nowMs);
      } catch (_) {
        // One game's review must never take the others down with it, and
        // must never surface to the UI (docs/PROGRESSION_PLAN.md §6.1).
      }
    }
  }

  Future<void> _reviewOne(String gameId, GameProgress progress, int nowMs) async {
    final toMs = nowMs;
    final fromMs = toMs - ProgressionConfig.reviewWindowDays * _dayMs;
    final prevFromMs = fromMs - ProgressionConfig.reviewWindowDays * _dayMs;

    final report = await _buildReport(gameId, fromMs, toMs, previousWindowFromMs: prevFromMs);
    final profile = GameLevelProfiles.byGameId[gameId]!;

    final updated = ProgressionPolicy.review(
      progress: progress,
      report: report,
      plateauLevel: profile.plateauLevel,
      nowMs: nowMs,
    );
    await _save(updated);
  }

  /// A fresh [GameReport] for [gameId] over `[fromMs, toMs)`, for the
  /// Diagnostics screen or a caregiver-triggered "run review now".
  Future<GameReport> reportsFor(String gameId, {int? windowDays}) async {
    final toMs = _now().millisecondsSinceEpoch;
    final days = windowDays ?? ProgressionConfig.reviewWindowDays;
    final fromMs = toMs - days * _dayMs;
    return _buildReport(gameId, fromMs, toMs, previousWindowFromMs: fromMs - days * _dayMs);
  }

  /// Every game's current [GameProgress], for the Diagnostics "Game levels"
  /// section (docs/PROGRESSION_PLAN.md §11).
  Future<Map<String, GameProgress>> allProgress() async {
    final result = <String, GameProgress>{};
    for (final gameId in kGameDomains.keys) {
      result[gameId] = await _load(gameId);
    }
    return result;
  }

  /// One [GenreReport] per domain, aggregating every game in it over the
  /// last [windowDays] days (docs/PROGRESSION_PLAN.md §6.8).
  Future<Map<CognitiveDomain, GenreReport>> genreReports({int windowDays = 7}) async {
    final toMs = _now().millisecondsSinceEpoch;
    final fromMs = toMs - windowDays * _dayMs;

    final byDomain = <CognitiveDomain, List<GenreGameSummary>>{};
    for (final entry in kGameDomains.entries) {
      final report = await _buildReport(entry.key, fromMs, toMs);
      final progress = await _load(entry.key);
      final concern = progress.history.isNotEmpty && progress.history.last.concern;
      (byDomain[entry.value] ??= []).add(
        GenreGameSummary(gameId: entry.key, trials: report.trials, score: report.score, concern: concern),
      );
    }

    return {
      for (final entry in byDomain.entries) entry.key: GenreReport.build(entry.key, entry.value),
    };
  }

  // ── Daily rest card (docs/PROGRESSION_PLAN.md §9) ───────────────────────

  /// Whether a gentle rest reminder is due right now, and today's play time
  /// to show on it. Marks the card as shown (so it is not repeated
  /// immediately) whenever it returns `show: true`.
  Future<RestAdvice> restAdvice({DateTime? now}) async {
    final n = now ?? _now();
    final settings = await repo.getSettings();
    final thresholdSeconds = settings.effectiveDailyRestMinutes * 60;
    final todayKey = PlayPolicy.dayKeyOf(n);

    final stored = await repo.getRestState(todayKey);
    final rolledOver = stored.dayKey != todayKey;
    var state = PlayPolicy.forToday(stored, todayKey, thresholdSeconds);

    final seconds = await _playSecondsToday(n);
    final due = PlayPolicy.restCardDue(state, seconds, thresholdSeconds);

    if (due) {
      state = PlayPolicy.afterRestCardShown(state);
      await repo.saveRestState(state);
    } else if (rolledOver) {
      // Persist the new-day rollover even when the card isn't due yet.
      await repo.saveRestState(state);
    }

    return RestAdvice(show: due, minutesToday: PlayPolicy.displayMinutes(seconds));
  }

  /// Call when the elder answers the rest card, however they answered it
  /// (closing it any other way counts as "Keep playing",
  /// docs/PROGRESSION_PLAN.md §9.3).
  Future<void> onRestCardAnswered({required bool keepPlaying, DateTime? now}) async {
    final n = now ?? _now();
    final settings = await repo.getSettings();
    final thresholdSeconds = settings.effectiveDailyRestMinutes * 60;
    final todayKey = PlayPolicy.dayKeyOf(n);

    var state = await repo.getRestState(todayKey);
    state = PlayPolicy.forToday(state, todayKey, thresholdSeconds);

    final seconds = await _playSecondsToday(n);
    final updated = PlayPolicy.afterRestCardAnswered(
      state,
      keptPlaying: keepPlaying,
      playSecondsToday: seconds,
      repeatMinutes: ProgressionConfig.restCardRepeatMinutes,
    );
    await repo.saveRestState(updated);
  }

  Future<int> _playSecondsToday(DateTime now) async {
    final startOfDay = DateTime(now.year, now.month, now.day);
    final sessionsToday = await eventRepo.sessionsBetween(
      startOfDay.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch + 5000,
    );
    return PlayPolicy.playSecondsToday(sessionsToday);
  }

  // ── Variety nudge (docs/PROGRESSION_PLAN.md §8) ─────────────────────────

  /// Returns an active variety suggestion if [gameId] (or any game, if
  /// [gameId] is null) is a repeat favourite and the suggestion is eligible
  /// and not in cooldown (docs/PROGRESSION_PLAN.md §8).
  ///
  /// Returns null if the rest card is currently due (the rest card wins over
  /// the suggestion, §9.2), if no favourite exists, if the nudge is in
  /// cooldown or snoozed, or if no other game is eligible.
  Future<VarietySuggestion?> suggestionFor({String? gameId, DateTime? now}) async {
    final n = now ?? _now();

    // Rest card wins over the variety suggestion when both are due (§9.2).
    final rest = await restAdvice(now: n);
    if (rest.show) return null;

    final settings = await repo.getSettings();
    final windowDays = settings.effectiveNudgeWindowDays;
    final repeatPlays = settings.effectiveNudgeRepeatPlays;

    final nudgeState = await repo.getNudgeState();
    final nowMs = n.millisecondsSinceEpoch;
    if (nudgeState.snoozedUntilMs != null && nowMs < nudgeState.snoozedUntilMs!) {
      return null;
    }

    final windowFromMs = n.subtract(Duration(days: windowDays)).millisecondsSinceEpoch;
    final sessions = await eventRepo.sessionsBetween(windowFromMs, nowMs);
    final trialCounts = await eventRepo.trialCountsBySessionBetween(windowFromMs, nowMs);

    final countedPlaysByGame = <String, int>{};
    for (final s in sessions) {
      final gid = s.gameIds;
      if (gid.isEmpty) continue;
      final tCount = trialCounts[s.id] ?? 0;
      final durSec = s.completed && s.endedAt != null
          ? ((s.endedAt! - s.startedAt) / 1000).round()
          : (s.abandonedAtMs != null ? (s.abandonedAtMs! / 1000).round() : null);
      final isCounted = tCount > 0 ||
          (durSec != null && durSec >= ProgressionConfig.minCountedPlaySeconds);
      if (isCounted) {
        countedPlaysByGame[gid] = (countedPlaysByGame[gid] ?? 0) + 1;
      }
    }

    final livingPeople = await contentRepo.getLivingPeople();
    final facesEligible = livingPeople.length >= 2;
    final eligibleGameIds = {
      for (final g in kGameDomains.keys)
        if (g != 'faces_of_family' || facesEligible) g,
    };

    final favourite = PlayPolicy.findFavouriteGame(
      countedPlaysByGame: countedPlaysByGame,
      eligibleGameIds: eligibleGameIds,
      gameId: gameId,
      repeatPlays: repeatPlays,
      shareOfPlays: ProgressionConfig.nudgeShareOfPlays,
    );
    if (favourite == null) return null;

    final available = PlayPolicy.isNudgeAvailable(
      state: nudgeState,
      favouriteId: favourite,
      now: n,
      cooldownHours: ProgressionConfig.nudgeCooldownHours,
    );
    if (!available) return null;

    final gReports = await genreReports(windowDays: 7);
    final trialsByDomain = <CognitiveDomain, int>{
      for (final entry in gReports.entries) entry.key: entry.value.totalTrials,
    };
    final lastPlayedAtMsByGame = <String, int?>{};
    for (final gid in eligibleGameIds) {
      final prog = await repo.getGameProgress(gid);
      lastPlayedAtMsByGame[gid] = prog.lastPlayedAtMs;
    }

    final suggested = PlayPolicy.chooseSuggestedGame(
      favouriteId: favourite,
      favouriteDomain: kGameDomains[favourite]!,
      eligibleGameIds: eligibleGameIds,
      gameDomains: kGameDomains,
      trialsByDomainLast7Days: trialsByDomain,
      lastPlayedAtMsByGame: lastPlayedAtMsByGame,
      gameCatalogOrder: kGameDomains.keys.toList(),
    );
    if (suggested == null) return null;

    return VarietySuggestion(
      favouriteGameId: favourite,
      suggestedGameId: suggested,
    );
  }

  /// Call when a suggestion card is presented to the elder so the 24h cooldown
  /// is recorded.
  Future<void> onNudgeShown(VarietySuggestion suggestion, {DateTime? now}) async {
    final n = now ?? _now();
    final state = await repo.getNudgeState();
    final updated = PlayPolicy.afterNudgeShown(
      state,
      favouriteId: suggestion.favouriteGameId,
      suggestedId: suggestion.suggestedGameId,
      nowMs: n.millisecondsSinceEpoch,
    );
    await repo.saveNudgeState(updated);
  }

  /// Call when "Maybe later" is tapped.
  Future<void> onNudgeDismissed({DateTime? now}) async {
    final n = now ?? _now();
    final state = await repo.getNudgeState();
    final updated = PlayPolicy.afterNudgeDismissed(
      state,
      nowMs: n.millisecondsSinceEpoch,
      snoozeDays: ProgressionConfig.nudgeSnoozeDaysAfterTwoDismissals,
    );
    await repo.saveNudgeState(updated);
  }

  /// Call when the elder taps the suggested game.
  Future<void> onNudgeAccepted(String gameId, {DateTime? now}) async {
    final state = await repo.getNudgeState();
    final updated = PlayPolicy.afterSuggestedGameTapped(state);
    await repo.saveNudgeState(updated);
  }

  // ── Internals ────────────────────────────────────────────────────────────

  Future<double> _startingLevelFor(String gameId) async {
    final domain = kGameDomains[gameId]!;

    final others = <GameProgress>[];
    for (final otherId in kGameDomains.keys) {
      if (otherId == gameId || kGameDomains[otherId] != domain) continue;
      final otherProgress = await _load(otherId);
      if (otherProgress.seeded) others.add(otherProgress);
    }

    double thetaBasedLevel;
    try {
      final record = await abilityRepo.getOrSeed(domain);
      thetaBasedLevel = LevelScale.difficultyToLevel(AbilityEstimator.nextDifficulty(record.theta));
    } catch (_) {
      thetaBasedLevel = ProgressionConfig.minLevel;
    }

    return ProgressionPolicy.startingLevel(
      domain: domain,
      otherSeededGamesInDomain: others,
      thetaBasedLevel: thetaBasedLevel,
    );
  }

  Future<GameReport> _buildReport(
    String gameId,
    int fromMs,
    int toMs, {
    int? previousWindowFromMs,
  }) async {
    final trials = await eventRepo.trialsForGameBetween(gameId, fromMs, toMs);
    final sessionsInWindow = await eventRepo.sessionsBetween(fromMs, toMs);
    final gameSessions = sessionsInWindow
        .where((s) => s.gameIds.split(',').contains(gameId))
        .toList();
    final trialCounts = await eventRepo.trialCountsBySessionBetween(fromMs, toMs);

    double? previousMedian;
    if (previousWindowFromMs != null) {
      final previousTrials =
          await eventRepo.trialsForGameBetween(gameId, previousWindowFromMs, fromMs);
      previousMedian = _median(previousTrials.map((t) => t.responseTimeMs).toList());
    }

    return GameReport.build(
      gameId: gameId,
      windowFromMs: fromMs,
      windowToMs: toMs,
      trials: trials,
      gameSessions: gameSessions,
      trialCountsBySession: trialCounts,
      previousMedianResponseTimeMs: previousMedian,
    );
  }

  static double? _median(List<int> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid].toDouble();
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  Future<GameProgress> _load(String gameId) async {
    final cached = _cache[gameId];
    if (cached != null) return cached;
    return _reload(gameId);
  }

  Future<GameProgress> _reload(String gameId) async {
    final progress = await repo.getGameProgress(gameId);
    _cache[gameId] = progress;
    return progress;
  }

  Future<void> _save(GameProgress progress) async {
    await repo.saveGameProgress(progress);
    _cache[progress.gameId] = progress;
  }
}
