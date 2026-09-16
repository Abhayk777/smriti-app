import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/progression/difficulty_axis.dart';

void main() {
  group('DifficultyAxis, rising', () {
    const axis = DifficultyAxis(
      name: 'listLength',
      start: 2,
      perLevel: 0.5,
      limit: 7,
      startLevel: 1,
      rounding: AxisRounding.floor,
    );

    test('stays at start at and below startLevel', () {
      expect(axis.valueAt(1), 2);
      expect(axis.valueAt(0), 2);
    });

    test('rises by perLevel above startLevel', () {
      expect(axis.valueAt(3), 3); // 2 + 0.5*2 = 3
      expect(axis.valueAt(5), 4); // 2 + 0.5*4 = 4
    });

    test('never passes the limit', () {
      expect(axis.valueAt(100), 7);
      expect(axis.valueAt(1000), 7);
    });

    test('saturationLevel is the first level at the limit', () {
      // start=2, limit=7, perLevel=0.5 -> (7-2)/0.5 = 10 levels above startLevel=1 -> 11
      expect(axis.saturationLevel, closeTo(11, 1e-9));
      expect(axis.valueAt(axis.saturationLevel), 7);
    });
  });

  group('DifficultyAxis, falling', () {
    const axis = DifficultyAxis(
      name: 'isiMinMs',
      start: 3000,
      perLevel: -150,
      limit: 1500,
      startLevel: 1,
      rounding: AxisRounding.round,
    );

    test('falls with level and stops at the limit', () {
      expect(axis.valueAt(1), 3000);
      expect(axis.valueAt(5), 2400); // 3000 - 150*4
      expect(axis.valueAt(100), 1500);
    });

    test('saturationLevel matches a falling axis', () {
      expect(axis.saturationLevel, closeTo(1 + 1500 / 150, 1e-9));
    });
  });

  group('AxisRounding', () {
    test('none leaves fractional values as-is', () {
      const axis = DifficultyAxis(
        name: 'x',
        start: 0,
        perLevel: 0.1,
        limit: 1,
        startLevel: 1,
      );
      expect(axis.valueAt(2), closeTo(0.1, 1e-9));
    });

    test('round rounds to the nearest whole number', () {
      const axis = DifficultyAxis(
        name: 'x',
        start: 0,
        perLevel: 0.6,
        limit: 10,
        startLevel: 1,
        rounding: AxisRounding.round,
      );
      expect(axis.valueAt(2), 1); // 0.6 rounds to 1
      expect(axis.valueAt(3), 1); // 1.2 rounds to 1
    });
  });

  group('LevelProfile', () {
    const profile = LevelProfile(
      gameId: 'example',
      axes: [
        DifficultyAxis(
          name: 'a',
          start: 2,
          perLevel: 0.5,
          limit: 7,
          startLevel: 1,
          rounding: AxisRounding.floor,
        ),
        DifficultyAxis(
          name: 'b',
          start: 0,
          perLevel: 0.5,
          limit: 4,
          startLevel: 4,
          rounding: AxisRounding.floor,
        ),
      ],
    );

    test('paramsAt returns every axis keyed by name', () {
      final params = profile.paramsAt(5);
      expect(params.keys, containsAll(['a', 'b']));
      expect(params['a'], profile.axes[0].valueAt(5));
      expect(params['b'], profile.axes[1].valueAt(5));
    });

    test('plateauLevel is the highest saturationLevel among axes', () {
      final expected = profile.axes
          .map((a) => a.saturationLevel)
          .reduce((a, b) => a > b ? a : b);
      expect(profile.plateauLevel, closeTo(expected, 1e-9));
    });
  });
}
