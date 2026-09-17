import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/ability/estimator.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/difficulty_source.dart';
import 'package:smriti/core/progression/level_scale.dart';
import 'package:smriti/core/progression/progression_config.dart';
import 'package:smriti/core/repo/ability_repo.dart';

import '../repo/_test_db.dart';

// Minimal stand-ins for CognitiveGame/TrialResult, so this file tests the
// progression module without any dependency on lib/games/.
class _FakeGame {
  const _FakeGame(this.id, this.domain);
  final String id;
  final CognitiveDomain domain;
}

class _FakeResult {
  const _FakeResult(this.correct);
  final bool correct;
}

class _FakeLevelSource implements GameLevelSource {
  _FakeLevelSource(this.levels, [this.concerns = const {}]);
  final Map<String, double> levels;
  final Map<String, bool> concerns;

  @override
  double levelFor(String gameId) => levels[gameId]!;

  @override
  bool concernFor(String gameId) => concerns[gameId] ?? false;
}

void main() {
  group('ThetaDifficultySource', () {
    late SmritiDatabase db;
    late AbilityRepo abilityRepo;

    setUp(() {
      db = newTestDb();
      abilityRepo = AbilityRepo(db);
    });

    tearDown(() async => db.close());

    test('difficultyFor matches AbilityEstimator.nextDifficulty(theta)', () async {
      const game = _FakeGame('g', CognitiveDomain.memory);
      final source = ThetaDifficultySource<_FakeGame, _FakeResult>(
        abilityRepo,
        (g) => g.domain,
      );

      final record = await abilityRepo.getOrSeed(CognitiveDomain.memory);
      final difficulty = await source.difficultyFor(game);
      expect(difficulty, closeTo(AbilityEstimator.nextDifficulty(record.theta), 1e-12));
    });

    test('onTrial is a no-op and contextFor is always empty', () async {
      const game = _FakeGame('g', CognitiveDomain.memory);
      final source = ThetaDifficultySource<_FakeGame, _FakeResult>(
        abilityRepo,
        (g) => g.domain,
      );
      source.onTrial(game, const _FakeResult(true));
      source.onTrial(game, const _FakeResult(false));
      expect(source.contextFor(game), isEmpty);
    });
  });

  group('LevelDifficultySource', () {
    test('difficultyFor starts at the stored level with no offset', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': 5.0}),
        (g) => g.id,
        (r) => r.correct,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);
      final d = await source.difficultyFor(game);
      expect(d, closeTo(LevelScale.levelToDifficulty(5.0), 1e-9));
    });

    test('by default, mid-session difficulty is fixed and does not change on misses or hits', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': 5.0}),
        (g) => g.id,
        (r) => r.correct,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);

      for (var i = 0; i < 10; i++) {
        source.onTrial(game, const _FakeResult(false));
      }
      var d = await source.difficultyFor(game);
      expect(d, closeTo(LevelScale.levelToDifficulty(5.0), 1e-9));

      for (var i = 0; i < 10; i++) {
        source.onTrial(game, const _FakeResult(true));
      }
      d = await source.difficultyFor(game);
      expect(d, closeTo(LevelScale.levelToDifficulty(5.0), 1e-9));
    });

    test('when enableStaircase is true, two misses in a row lower difficulty by half a level', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': 5.0}),
        (g) => g.id,
        (r) => r.correct,
        enableStaircase: true,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);

      source.onTrial(game, const _FakeResult(false));
      source.onTrial(game, const _FakeResult(false));

      final d = await source.difficultyFor(game);
      expect(d, closeTo(LevelScale.levelToDifficulty(4.5), 1e-9));
    });

    test('when enableStaircase is true, three hits in a row raise difficulty by half a level', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': 5.0}),
        (g) => g.id,
        (r) => r.correct,
        enableStaircase: true,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);

      source.onTrial(game, const _FakeResult(true));
      source.onTrial(game, const _FakeResult(true));
      source.onTrial(game, const _FakeResult(true));

      final d = await source.difficultyFor(game);
      expect(d, closeTo(LevelScale.levelToDifficulty(5.5), 1e-9));
    });

    test('a single miss (or hit) short of the streak threshold changes nothing', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': 5.0}),
        (g) => g.id,
        (r) => r.correct,
        enableStaircase: true,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);

      source.onTrial(game, const _FakeResult(false)); // 1 miss, threshold is 2
      final d = await source.difficultyFor(game);
      expect(d, closeTo(LevelScale.levelToDifficulty(5.0), 1e-9));
    });

    test('a hit resets the miss streak and vice versa', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': 5.0}),
        (g) => g.id,
        (r) => r.correct,
        enableStaircase: true,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);

      source.onTrial(game, const _FakeResult(false));
      source.onTrial(game, const _FakeResult(true)); // resets the miss streak
      source.onTrial(game, const _FakeResult(false));
      // Only 1 consecutive miss again, not 2 -> no change.
      final d = await source.difficultyFor(game);
      expect(d, closeTo(LevelScale.levelToDifficulty(5.0), 1e-9));
    });

    test('the offset never exceeds the configured bound in either direction', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': 5.0}),
        (g) => g.id,
        (r) => r.correct,
        enableStaircase: true,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);

      // Many consecutive hits: offset should clamp at staircaseMaxOffset.
      for (var i = 0; i < 30; i++) {
        source.onTrial(game, const _FakeResult(true));
      }
      final d = await source.difficultyFor(game);
      final maxLevel = 5.0 + ProgressionConfig.staircaseMaxOffset;
      expect(d, closeTo(LevelScale.levelToDifficulty(maxLevel), 1e-9));
    });

    test('the effective level never drops below the minimum level', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': ProgressionConfig.minLevel}),
        (g) => g.id,
        (r) => r.correct,
        enableStaircase: true,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);

      for (var i = 0; i < 30; i++) {
        source.onTrial(game, const _FakeResult(false));
      }
      final d = await source.difficultyFor(game);
      expect(d, greaterThanOrEqualTo(LevelScale.levelToDifficulty(ProgressionConfig.minLevel)));
    });

    test('contextFor reports the stored level, offset, effective level and concern', () async {
      final source = LevelDifficultySource<_FakeGame, _FakeResult>(
        _FakeLevelSource({'g': 5.0}, {'g': true}),
        (g) => g.id,
        (r) => r.correct,
        enableStaircase: true,
      );
      const game = _FakeGame('g', CognitiveDomain.memory);

      source.onTrial(game, const _FakeResult(false));
      source.onTrial(game, const _FakeResult(false));

      final context = source.contextFor(game);
      final progression = context['progression'] as Map<String, Object?>;
      expect(progression['level'], 5.0);
      expect(progression['offset'], closeTo(-0.5, 1e-9));
      expect(progression['effectiveLevel'], closeTo(4.5, 1e-9));
      expect(progression['concern'], isTrue);
      expect(progression['v'], 1);
    });
  });
}
