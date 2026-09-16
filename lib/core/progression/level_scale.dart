/// Converts between the elder-facing "level" (`L >= 1.0`, steps of 0.5) and
/// the existing difficulty scale (`d`, the same logit scale as `theta`),
/// per docs/PROGRESSION_PLAN.md §3.
///
///   d = (L - 5) / 2        L = 5 + 2 * d
///   L = 1  -> d = -2.0
///   L = 5  -> d =  0.0
///   L = 9  -> d = +2.0
///
/// This is the only place either conversion is written; every other file
/// (games, session runner, service) calls through here.
class LevelScale {
  const LevelScale._();

  static double levelToDifficulty(double level) => (level - 5) / 2;

  static double difficultyToLevel(double difficulty) => 5 + 2 * difficulty;

  /// Rounds a level to the nearest 0.5, per the stored-level convention.
  static double roundToHalf(double level) => (level * 2).round() / 2;

  /// Clamps then rounds to the nearest 0.5. Used whenever a computed level
  /// must be stored.
  static double clampAndRound(double level, {required double min, double? max}) {
    var v = level < min ? min : level;
    if (max != null && v > max) v = max;
    return roundToHalf(v);
  }
}
