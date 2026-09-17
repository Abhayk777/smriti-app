import 'difficulty_axis.dart';

/// One [LevelProfile] per game id, exactly as specified in
/// docs/PROGRESSION_PLAN.md §5.3. Pure data: no randomness, no I/O.
///
/// Each game (`lib/games/*/*_game.dart`) reads its profile's `paramsAt(level)`
/// inside `generateItem` to compute its concrete parameters (list length,
/// option count, and so on). See docs/PROGRESSION_PLAN.md §5.6.
class GameLevelProfiles {
  const GameLevelProfiles._();

  static const LevelProfile marketBasket = LevelProfile(
    gameId: 'market_basket',
    axes: [
      DifficultyAxis(
        name: 'listLength',
        start: 2,
        perLevel: 0.5,
        limit: 7,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'nearDistractors',
        start: 0,
        perLevel: 0.5,
        limit: 4,
        startLevel: 4,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'studySecondsPerItem',
        start: 1.6,
        perLevel: -0.08,
        limit: 0.9,
        startLevel: 8,
      ),
      DifficultyAxis(
        name: 'delaySeconds',
        start: 2,
        perLevel: 0.75,
        limit: 8,
        startLevel: 10,
        rounding: AxisRounding.round,
      ),
    ],
  );

  /// `revealSeconds` here is the axis used ABOVE level 11 (photo starts
  /// disappearing). Below level 11 the game must use 0 (the photo stays on
  /// screen); this axis's own `valueAt` would return 8 in that range, which
  /// is only meaningful once combined with the level < 11 special case
  /// documented in docs/PROGRESSION_PLAN.md §5.3 (faces_of_family notes).
  static const LevelProfile facesOfFamily = LevelProfile(
    gameId: 'faces_of_family',
    axes: [
      DifficultyAxis(
        name: 'optionCount',
        start: 2,
        perLevel: 0.5,
        limit: 4,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'relationshipModeChance',
        start: 0,
        perLevel: 0.1,
        limit: 0.5,
        startLevel: 6,
      ),
      DifficultyAxis(
        name: 'sameRelationshipDistractorChance',
        start: 0,
        perLevel: 0.1,
        limit: 0.7,
        startLevel: 8,
      ),
      DifficultyAxis(
        name: 'revealSeconds',
        start: 8,
        perLevel: -1,
        limit: 3,
        startLevel: 11,
        rounding: AxisRounding.round,
      ),
    ],
  );

  static const LevelProfile sortHarvest = LevelProfile(
    gameId: 'sort_harvest',
    axes: [
      DifficultyAxis(
        name: 'matCount',
        start: 2,
        perLevel: 0.34,
        limit: 4,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'dimensionCount',
        start: 1,
        perLevel: 0.34,
        limit: 3,
        startLevel: 3,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'switchEvery',
        start: 8,
        perLevel: -0.5,
        limit: 3,
        startLevel: 5,
        rounding: AxisRounding.round,
      ),
    ],
  );

  static const LevelProfile tracePath = LevelProfile(
    gameId: 'trace_path',
    axes: [
      DifficultyAxis(
        name: 'nodeCount',
        start: 4,
        perLevel: 1,
        limit: 15,
        rounding: AxisRounding.round,
      ),
      DifficultyAxis(
        name: 'variantBChance',
        start: 0,
        perLevel: 0.125,
        limit: 0.75,
        startLevel: 8,
      ),
      DifficultyAxis(
        name: 'decoyStones',
        start: 0,
        perLevel: 0.5,
        limit: 4,
        startLevel: 13,
        rounding: AxisRounding.floor,
      ),
    ],
  );

  static const LevelProfile myDay = LevelProfile(
    gameId: 'my_day',
    axes: [
      DifficultyAxis(
        name: 'eventCount',
        start: 3,
        perLevel: 0.5,
        limit: 7,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'orientationChance',
        start: 0.2,
        perLevel: 0.05,
        limit: 0.6,
      ),
      DifficultyAxis(
        name: 'questionTier',
        start: 1,
        perLevel: 0.5,
        limit: 5,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'dateOptionSpread',
        start: 2,
        perLevel: -0.25,
        limit: 1,
        startLevel: 6,
        rounding: AxisRounding.round,
      ),
    ],
  );

  static const LevelProfile lampsFestival = LevelProfile(
    gameId: 'lamps_festival',
    axes: [
      DifficultyAxis(
        name: 'span',
        start: 2,
        perLevel: 0.5,
        limit: 7,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'lampCount',
        start: 5,
        perLevel: 0.5,
        limit: 12,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'backwardChance',
        start: 0,
        perLevel: 0.125,
        limit: 0.75,
        startLevel: 9,
      ),
      DifficultyAxis(
        name: 'litMs',
        start: 600,
        perLevel: -25,
        limit: 400,
        startLevel: 11,
        rounding: AxisRounding.round,
      ),
    ],
  );

  static const LevelProfile nameHarvest = LevelProfile(
    gameId: 'name_harvest',
    axes: [
      DifficultyAxis(
        name: 'expectedCount',
        start: 3,
        perLevel: 0.5,
        limit: 15,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'categoryTier',
        start: 1,
        perLevel: 0.25,
        limit: 3,
        rounding: AxisRounding.floor,
      ),
    ],
  );

  static const LevelProfile weavingPatterns = LevelProfile(
    gameId: 'weaving_patterns',
    axes: [
      DifficultyAxis(
        name: 'elementCount',
        start: 3,
        perLevel: 0.5,
        limit: 8,
        rounding: AxisRounding.floor,
      ),
      DifficultyAxis(
        name: 'distractorSimilarity',
        start: 0,
        perLevel: 0.1,
        limit: 1.0,
      ),
      DifficultyAxis(
        name: 'patternTypeTier',
        start: 1,
        perLevel: 0.34,
        limit: 3,
        rounding: AxisRounding.floor,
      ),
    ],
  );

  static const LevelProfile soundsHome = LevelProfile(
    gameId: 'sounds_home',
    axes: [
      DifficultyAxis(
        name: 'targetFrequency',
        start: 0.30,
        perLevel: -0.02,
        limit: 0.12,
      ),
      DifficultyAxis(
        name: 'isiMinMs',
        start: 3000,
        perLevel: -150,
        limit: 1500,
        rounding: AxisRounding.round,
      ),
      DifficultyAxis(
        name: 'isiMaxMs',
        start: 5000,
        perLevel: -150,
        limit: 2500,
        rounding: AxisRounding.round,
      ),
      DifficultyAxis(
        name: 'lureChance',
        start: 0,
        perLevel: 0.05,
        limit: 0.3,
        startLevel: 6,
      ),
    ],
  );

  /// All profiles keyed by game id, matching `lib/games/game_catalog.dart`
  /// exactly (see the T2 acceptance test).
  static const Map<String, LevelProfile> byGameId = {
    'market_basket': marketBasket,
    'faces_of_family': facesOfFamily,
    'sort_harvest': sortHarvest,
    'trace_path': tracePath,
    'my_day': myDay,
    'lamps_festival': lampsFestival,
    'name_harvest': nameHarvest,
    'weaving_patterns': weavingPatterns,
    'sounds_home': soundsHome,
  };
}
