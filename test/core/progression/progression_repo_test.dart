import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/progression_repo.dart';
import 'package:smriti/core/progression/progression_state.dart';

import '../repo/_test_db.dart';

void main() {
  late SmritiDatabase db;
  late ProgressionRepo repo;

  setUp(() {
    db = newTestDb();
    repo = ProgressionRepo(db);
  });

  tearDown(() async => db.close());

  group('game progress', () {
    test('a never-saved game returns a fresh GameProgress', () async {
      final p = await repo.getGameProgress('market_basket');
      expect(p.gameId, 'market_basket');
      expect(p.level, 1.0);
      expect(p.seeded, isFalse);
    });

    test('round-trips through save and get', () async {
      final saved = GameProgress.fresh('market_basket').copyWith(
        level: 6.5,
        seeded: true,
        lastPlayedAtMs: 12345,
      );
      await repo.saveGameProgress(saved);

      final loaded = await repo.getGameProgress('market_basket');
      expect(loaded.level, 6.5);
      expect(loaded.seeded, isTrue);
      expect(loaded.lastPlayedAtMs, 12345);
    });

    test('corrupt stored JSON falls back to fresh rather than throwing',
        () async {
      await db.appConfigsDao
          .setValue('progression.v1.game.market_basket', '{not json');
      final loaded = await repo.getGameProgress('market_basket');
      expect(loaded.level, 1.0);
      expect(loaded.seeded, isFalse);
    });

    test('different games are stored independently', () async {
      await repo.saveGameProgress(
        GameProgress.fresh('market_basket').copyWith(level: 3.0),
      );
      await repo.saveGameProgress(
        GameProgress.fresh('trace_path').copyWith(level: 7.0),
      );

      expect((await repo.getGameProgress('market_basket')).level, 3.0);
      expect((await repo.getGameProgress('trace_path')).level, 7.0);
    });
  });

  group('nudge state', () {
    test('starts at initial() and round-trips after saving', () async {
      expect((await repo.getNudgeState()).dismissStreak, 0);

      await repo.saveNudgeState(
        NudgeState.initial().copyWith(
          lastFavouriteId: 'market_basket',
          dismissStreak: 2,
        ),
      );

      final loaded = await repo.getNudgeState();
      expect(loaded.lastFavouriteId, 'market_basket');
      expect(loaded.dismissStreak, 2);
    });

    test('corrupt stored JSON falls back to initial()', () async {
      await db.appConfigsDao.setValue('progression.v1.nudge', 'nope');
      expect((await repo.getNudgeState()).dismissStreak, 0);
    });
  });

  group('rest state', () {
    test('a never-saved day returns a fresh state for today', () async {
      final s = await repo.getRestState('2026-01-01');
      expect(s.dayKey, '2026-01-01');
      expect(s.shownCount, 0);
    });

    test('round-trips through save and get', () async {
      await repo.saveRestState(
        const RestState(
          dayKey: '2026-01-01',
          nextDueAtSeconds: 1800,
          shownCount: 1,
          keptPlayingCount: 1,
        ),
      );
      final loaded = await repo.getRestState('2026-01-01');
      expect(loaded.nextDueAtSeconds, 1800);
      expect(loaded.shownCount, 1);
    });
  });

  group('settings', () {
    test('missing settings gives an empty override (all defaults apply)',
        () async {
      final s = await repo.getSettings();
      expect(s.dailyRestMinutes, isNull);
      expect(s.effectiveDailyRestMinutes, 30);
    });

    test('round-trips a caregiver override', () async {
      await repo.saveSettings(
        const ProgressionSettings(dailyRestMinutes: 45, nudgeRepeatPlays: 4),
      );
      final loaded = await repo.getSettings();
      expect(loaded.effectiveDailyRestMinutes, 45);
      expect(loaded.effectiveNudgeRepeatPlays, 4);
      // Untouched fields still fall back to the constant.
      expect(loaded.effectiveNudgeWindowDays, 3);
      expect(loaded.effectiveReviewEveryDays, 4);
    });
  });

  group('clearAll', () {
    test('removes every progression.v1.* key and nothing else', () async {
      await repo.saveGameProgress(
        GameProgress.fresh('market_basket').copyWith(level: 5.0),
      );
      await repo.saveGameProgress(
        GameProgress.fresh('trace_path').copyWith(level: 5.0),
      );
      await repo.saveNudgeState(NudgeState.initial().copyWith(dismissStreak: 1));
      await repo.saveRestState(RestState.forNewDay('2026-01-01', 1800));
      await repo.saveSettings(const ProgressionSettings(dailyRestMinutes: 45));

      // Something unrelated that must survive.
      await db.appConfigsDao.setValue('patientId', 'p1');
      await db.appConfigsDao.setValue('elderName', 'Aai');

      await repo.clearAll();

      expect((await repo.getGameProgress('market_basket')).level, 1.0);
      expect((await repo.getGameProgress('trace_path')).level, 1.0);
      expect((await repo.getNudgeState()).dismissStreak, 0);
      expect((await repo.getSettings()).dailyRestMinutes, isNull);
      expect(await db.appConfigsDao.getValue('patientId'), 'p1');
      expect(await db.appConfigsDao.getValue('elderName'), 'Aai');
    });
  });
}
