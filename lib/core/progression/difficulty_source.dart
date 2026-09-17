import '../ability/estimator.dart';
import '../repo/ability_repo.dart';
import 'level_scale.dart';
import 'progression_config.dart';

// `CognitiveGame` and `TrialResult` are declared in `lib/games/cognitive_game.dart`,
// which already depends on `lib/core/ability/estimator.dart`. Importing that
// file from here (core -> games) would invert the app's layering, so this
// file is imported the other way around instead: `session_runner.dart`
// (in `lib/games/`) imports this file, not the reverse. To keep this file
// free of that dependency, the interface below is expressed in terms of the
// small subset of `TrialResult` it actually needs.

/// How a game's next item difficulty is chosen, and what gets recorded about
/// that choice on the trial (docs/PROGRESSION_PLAN.md §7).
///
/// [G] is `CognitiveGame` and [R] is `TrialResult`; both are supplied as type
/// parameters so this file has no import from `lib/games/`.
abstract class DifficultySource<G, R> {
  /// The difficulty to hand to `game.generateItem(...)`, on the same scale as
  /// `AbilityEstimator.nextDifficulty` already returns.
  Future<double> difficultyFor(G game);

  /// Called after every trial, so a level-based source can react within the
  /// session (docs/PROGRESSION_PLAN.md §7).
  void onTrial(G game, R result);

  /// Extra data merged into the trial's `trialContext` JSON. Empty for the
  /// default source, so existing rows stay byte-identical.
  Map<String, Object?> contextFor(G game);
}

/// Read-only view of stored progression levels that [LevelDifficultySource]
/// needs. Implemented by `ProgressionService` (docs/PROGRESSION_PLAN.md §8's
/// service is built in a later task; this interface lets this file, and its
/// tests, exist independently of that one).
///
/// Both methods are synchronous: the level for the game(s) in a session is
/// loaded once when the session starts, so nothing here should need to touch
/// the database mid-session.
abstract class GameLevelSource {
  /// The currently stored level for [gameId].
  double levelFor(String gameId);

  /// The most recent review's concern flag for [gameId] (docs/PROGRESSION_PLAN.md
  /// §6.6), or false when there isn't one yet.
  bool concernFor(String gameId);
}

/// Today's behaviour, unchanged: the next item's difficulty comes straight
/// from `AbilityEstimator.nextDifficulty(theta)`. Used whenever no
/// [DifficultySource] is supplied to `SessionRunner`, so every existing
/// caller and test keeps working exactly as before.
class ThetaDifficultySource<G extends Object, R extends Object>
    implements DifficultySource<G, R> {
  ThetaDifficultySource(this.abilityRepo, this.domainOf);

  final AbilityRepo abilityRepo;

  /// Reads `game.primaryDomain` without this file importing `CognitiveGame`.
  final CognitiveDomain Function(G game) domainOf;

  @override
  Future<double> difficultyFor(G game) async {
    final record = await abilityRepo.getOrSeed(domainOf(game));
    return AbilityEstimator.nextDifficulty(record.theta);
  }

  @override
  void onTrial(G game, R result) {}

  @override
  Map<String, Object?> contextFor(G game) => const {};
}

/// Uses the elder's stored per-game level (docs/PROGRESSION_PLAN.md §5, §6)
/// instead of the raw ability estimate, with a small in-session staircase
/// (§7) for quick relief when today's level is too hard, or a nudge upward
/// when it is clearly too easy. The staircase offset lives only in memory:
/// it resets every session, and only the 4-day review ever changes the
/// stored level.
class LevelDifficultySource<G extends Object, R extends Object>
    implements DifficultySource<G, R> {
  LevelDifficultySource(
    this.service,
    this.idOf,
    this.correctOf, {
    this.enableStaircase = false,
  });

  final GameLevelSource service;

  /// Reads `game.id` without this file importing `CognitiveGame`.
  final String Function(G game) idOf;

  /// Reads `result.correct` without this file importing `TrialResult`.
  final bool Function(R result) correctOf;

  /// Whether the in-session staircase is enabled. Defaults to false so difficulty
  /// remains strictly fixed to the elder's stored level throughout the session,
  /// changing only when the 4-day review analyses the elder's pattern.
  final bool enableStaircase;

  double _offset = 0;
  int _hitStreak = 0;
  int _missStreak = 0;

  @override
  Future<double> difficultyFor(G game) async {
    final level = (service.levelFor(idOf(game)) + _offset)
        .clamp(ProgressionConfig.minLevel, double.infinity);
    return LevelScale.levelToDifficulty(level);
  }

  @override
  void onTrial(G game, R result) {
    if (!enableStaircase) return;
    if (correctOf(result)) {
      _missStreak = 0;
      _hitStreak++;
      if (_hitStreak >= ProgressionConfig.staircaseUpAfterHits) {
        _adjustOffset(ProgressionConfig.staircaseStep);
        _hitStreak = 0;
      }
    } else {
      _hitStreak = 0;
      _missStreak++;
      if (_missStreak >= ProgressionConfig.staircaseDownAfterMisses) {
        _adjustOffset(-ProgressionConfig.staircaseStep);
        _missStreak = 0;
      }
    }
  }

  void _adjustOffset(double delta) {
    _offset = (_offset + delta).clamp(
      -ProgressionConfig.staircaseMaxOffset,
      ProgressionConfig.staircaseMaxOffset,
    );
  }

  @override
  Map<String, Object?> contextFor(G game) {
    final gameId = idOf(game);
    final storedLevel = service.levelFor(gameId);
    final effectiveLevel = (storedLevel + _offset)
        .clamp(ProgressionConfig.minLevel, double.infinity);
    return {
      'progression': {
        'v': 1,
        'level': storedLevel,
        'offset': _offset,
        'effectiveLevel': effectiveLevel,
        'concern': service.concernFor(gameId),
      },
    };
  }
}
