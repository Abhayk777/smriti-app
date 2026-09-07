import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/ability/estimator.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/ability_repo.dart';

import '_test_db.dart';

void main() {
  late SmritiDatabase db;
  late AbilityRepo repo;

  setUp(() {
    db = newTestDb();
    repo = AbilityRepo(db);
  });

  tearDown(() async => db.close());

  test('round-trips an ability record', () async {
    const record = AbilityRecord(
      theta: 0.875,
      nTrials: 42,
      rtMeanLog: 7.9,
      rtVar: 0.31,
    );
    final now = DateTime.fromMillisecondsSinceEpoch(1757200000000);

    await repo.saveRecord(CognitiveDomain.memory, record, now: now);

    final read = await repo.getRecord(CognitiveDomain.memory);
    expect(read, isNotNull);
    expect(read!.theta, closeTo(0.875, 1e-12));
    expect(read.nTrials, 42);
    expect(read.rtMeanLog, closeTo(7.9, 1e-12));
    expect(read.rtVar, closeTo(0.31, 1e-12));
    expect(await repo.getUpdatedAt(CognitiveDomain.memory), 1757200000000);

    // Unwritten domains stay absent rather than defaulting to zero.
    expect(await repo.getRecord(CognitiveDomain.attention), isNull);
  });

  test('saving the same domain twice updates in place', () async {
    await repo.saveRecord(
      CognitiveDomain.executive,
      const AbilityRecord(theta: 0.1, nTrials: 1, rtMeanLog: 8.0, rtVar: 0.25),
    );
    await repo.saveRecord(
      CognitiveDomain.executive,
      const AbilityRecord(theta: 0.6, nTrials: 2, rtMeanLog: 7.8, rtVar: 0.22),
    );

    final rows = await db.select(db.abilityStates).get();
    expect(rows, hasLength(1));
    expect(rows.single.theta, closeTo(0.6, 1e-12));
    expect(rows.single.nTrials, 2);
  });

  test('getAllRecords returns one entry per written domain', () async {
    await repo.saveRecord(
      CognitiveDomain.memory,
      const AbilityRecord(theta: 0.2, nTrials: 3, rtMeanLog: 8.1, rtVar: 0.2),
    );
    await repo.saveRecord(
      CognitiveDomain.language,
      const AbilityRecord(theta: -0.4, nTrials: 5, rtMeanLog: 8.4, rtVar: 0.3),
    );

    final all = await repo.getAllRecords();
    expect(all.keys, containsAll([CognitiveDomain.memory, CognitiveDomain.language]));
    expect(all[CognitiveDomain.memory]!.nTrials, 3);
    expect(all[CognitiveDomain.language]!.theta, closeTo(-0.4, 1e-12));
    expect(all.containsKey(CognitiveDomain.visuospatial), isFalse);
  });

  test('getOrSeed seeds from AppConfigs demographics, then is stable', () async {
    await db.appConfigsDao.setValue(AbilityRepo.ageKey, '76');
    await db.appConfigsDao.setValue(AbilityRepo.educationYearsKey, '12');

    final expected = AbilityEstimator.seed(76, 12);
    final seeded = await repo.getOrSeed(CognitiveDomain.visuospatial);
    expect(seeded.theta, closeTo(expected.theta, 1e-12));
    expect(seeded.nTrials, 0);

    // Persisted, so the second call reads rather than re-seeds.
    expect((await repo.getRecord(CognitiveDomain.visuospatial))!.theta,
        closeTo(expected.theta, 1e-12));
    expect((await repo.getOrSeed(CognitiveDomain.visuospatial)).theta,
        closeTo(expected.theta, 1e-12));
  });

  test('getOrSeed falls back to neutral demographics when config is missing',
      () async {
    final seeded = await repo.getOrSeed(CognitiveDomain.attention);
    expect(seeded.theta, closeTo(0.0, 1e-12));
  });

  test('applyTrial persists the estimator update', () async {
    await db.appConfigsDao.setValue(AbilityRepo.ageKey, '76');
    await db.appConfigsDao.setValue(AbilityRepo.educationYearsKey, '8');

    final before = await repo.getOrSeed(CognitiveDomain.memory);
    final after = await repo.applyTrial(
      domain: CognitiveDomain.memory,
      itemDifficulty: AbilityEstimator.nextDifficulty(before.theta),
      correct: true,
      responseTimeMs: 2500,
    );

    expect(after.nTrials, before.nTrials + 1);
    expect(after.theta, greaterThan(before.theta));

    final persisted = await repo.getRecord(CognitiveDomain.memory);
    expect(persisted!.theta, closeTo(after.theta, 1e-12));
    expect(persisted.nTrials, after.nTrials);
    expect(persisted.rtMeanLog, closeTo(after.rtMeanLog, 1e-12));
    expect(persisted.rtVar, closeTo(after.rtVar, 1e-12));
  });
}
