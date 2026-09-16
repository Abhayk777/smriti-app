import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/progression/level_scale.dart';

void main() {
  test('levelToDifficulty matches the fixed anchor points', () {
    expect(LevelScale.levelToDifficulty(1), closeTo(-2.0, 1e-9));
    expect(LevelScale.levelToDifficulty(5), closeTo(0.0, 1e-9));
    expect(LevelScale.levelToDifficulty(9), closeTo(2.0, 1e-9));
    expect(LevelScale.levelToDifficulty(13), closeTo(4.0, 1e-9));
  });

  test('difficultyToLevel is the inverse of levelToDifficulty', () {
    for (final x in [-3.0, -2.0, -1.0, 0.0, 0.7, 1.5, 2.0, 4.0, 10.0]) {
      final level = LevelScale.difficultyToLevel(x);
      expect(LevelScale.levelToDifficulty(level), closeTo(x, 1e-9));
    }
  });

  test('roundToHalf rounds to the nearest 0.5', () {
    expect(LevelScale.roundToHalf(5.24), closeTo(5.0, 1e-9));
    expect(LevelScale.roundToHalf(5.26), closeTo(5.5, 1e-9));
    expect(LevelScale.roundToHalf(5.75), closeTo(6.0, 1e-9));
    expect(LevelScale.roundToHalf(-0.26), closeTo(-0.5, 1e-9));
  });

  test('clampAndRound enforces the minimum and optional maximum', () {
    expect(LevelScale.clampAndRound(0.2, min: 1.0), closeTo(1.0, 1e-9));
    expect(
      LevelScale.clampAndRound(10.0, min: 1.0, max: 6.0),
      closeTo(6.0, 1e-9),
    );
    expect(
      LevelScale.clampAndRound(3.24, min: 1.0, max: 6.0),
      closeTo(3.0, 1e-9),
    );
  });
}
