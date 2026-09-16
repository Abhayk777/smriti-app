import 'dart:math' as math;

/// How a [DifficultyAxis]'s raw value is rounded before use.
enum AxisRounding { none, floor, round }

/// One tunable dimension of a game's difficulty (docs/PROGRESSION_PLAN.md
/// §5.2): for example "items to remember" or "chance of a distractor".
///
/// The value is `start` up to [startLevel], then moves by [perLevel] for
/// every level above that, until it reaches [limit] (a humane maximum or
/// minimum — the value never moves past it, however high the level goes).
class DifficultyAxis {
  const DifficultyAxis({
    required this.name,
    required this.start,
    required this.perLevel,
    required this.limit,
    this.startLevel = 1.0,
    this.rounding = AxisRounding.none,
  }) : assert(perLevel != 0, 'perLevel must be non-zero, or the axis never moves');

  /// Key this axis's value is stored under in [LevelProfile.paramsAt].
  final String name;

  /// Value at [startLevel] and below.
  final double start;

  /// Change per +1 level once the level passes [startLevel]. May be
  /// negative, for axes that get smaller (for example inter-stimulus
  /// interval) as the level rises.
  final double perLevel;

  /// The bound this axis never moves past. Must be reachable from [start]
  /// by moving in the direction of [perLevel] (i.e. `limit > start` when
  /// `perLevel > 0`, `limit < start` when `perLevel < 0`).
  final double limit;

  /// Level at and below which this axis stays at [start].
  final double startLevel;

  final AxisRounding rounding;

  /// The value of this axis at [level], bounded by [limit] and rounded per
  /// [rounding].
  double valueAt(double level) {
    final raw = start + perLevel * math.max(0, level - startLevel);
    final bounded = perLevel >= 0 ? math.min(raw, limit) : math.max(raw, limit);
    switch (rounding) {
      case AxisRounding.none:
        return bounded;
      case AxisRounding.floor:
        return bounded.floorToDouble();
      case AxisRounding.round:
        return bounded.roundToDouble();
    }
  }

  /// First level at which this axis reaches [limit] and stops moving.
  double get saturationLevel =>
      startLevel + (limit - start).abs() / perLevel.abs();
}

/// The set of [DifficultyAxis]es that together define one game's difficulty
/// curve (docs/PROGRESSION_PLAN.md §5.2-§5.3). Pure data; games read
/// [paramsAt] and interpret the values themselves.
class LevelProfile {
  const LevelProfile({required this.gameId, required this.axes});

  final String gameId;
  final List<DifficultyAxis> axes;

  /// Every axis's value at [level], keyed by [DifficultyAxis.name].
  Map<String, double> paramsAt(double level) => {
        for (final axis in axes) axis.name: axis.valueAt(level),
      };

  /// The level at which every axis in this profile has reached its limit.
  /// Above this level the game is at its hardest fair setting; see
  /// docs/PROGRESSION_PLAN.md §5.4 for the soft-top behaviour built on this.
  double get plateauLevel =>
      axes.map((a) => a.saturationLevel).fold(1.0, math.max);
}
