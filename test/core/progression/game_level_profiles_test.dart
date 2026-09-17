import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/progression/game_level_profiles.dart';
import 'package:smriti/games/game_catalog.dart';

void main() {
  test('every game in the catalogue has a profile', () {
    for (final game in gameCatalog) {
      expect(
        GameLevelProfiles.byGameId.containsKey(game.id),
        isTrue,
        reason: '${game.id} has no LevelProfile',
      );
    }
    // And no stray profiles for games that don't exist.
    final catalogueIds = gameCatalog.map((g) => g.id).toSet();
    for (final id in GameLevelProfiles.byGameId.keys) {
      expect(catalogueIds.contains(id), isTrue, reason: '$id is not in gameCatalog');
    }
  });

  test('every axis is monotone in its intended direction and stays within its limit '
      'from level 1 to level 40', () {
    for (final entry in GameLevelProfiles.byGameId.entries) {
      final profile = entry.value;
      for (final axis in profile.axes) {
        double? previous;
        for (var level = 1.0; level <= 40.0; level += 0.5) {
          final value = axis.valueAt(level);

          if (axis.perLevel >= 0) {
            expect(
              value,
              lessThanOrEqualTo(axis.limit + 1e-9),
              reason: '${entry.key}.${axis.name} exceeded its rising limit at L$level',
            );
          } else {
            expect(
              value,
              greaterThanOrEqualTo(axis.limit - 1e-9),
              reason: '${entry.key}.${axis.name} exceeded its falling limit at L$level',
            );
          }

          if (previous != null) {
            if (axis.perLevel >= 0) {
              expect(
                value,
                greaterThanOrEqualTo(previous - 1e-9),
                reason: '${entry.key}.${axis.name} decreased while rising at L$level',
              );
            } else {
              expect(
                value,
                lessThanOrEqualTo(previous + 1e-9),
                reason: '${entry.key}.${axis.name} increased while falling at L$level',
              );
            }
          }
          previous = value;
        }
      }
    }
  });

  test('plateauLevel is reachable and matches every axis being saturated', () {
    for (final entry in GameLevelProfiles.byGameId.entries) {
      final profile = entry.value;
      final plateau = profile.plateauLevel;
      final params = profile.paramsAt(plateau);
      for (final axis in profile.axes) {
        expect(
          params[axis.name],
          closeTo(axis.limit, 1e-6),
          reason: '${entry.key}.${axis.name} is not at its limit at the plateau level',
        );
      }
    }
  });
}
