import '../ability/estimator.dart';
import '../db/database.dart';

/// Persistence for per-domain ability estimates.
///
/// The estimator itself ([AbilityEstimator]) is pure maths with no storage; this
/// repo is the only place `AbilityStates` rows are read or written. One row per
/// [CognitiveDomain], keyed by its name.
class AbilityRepo {
  AbilityRepo(this.db);

  final SmritiDatabase db;

  static const String ageKey = 'age';
  static const String educationYearsKey = 'educationYears';

  Future<AbilityRecord?> getRecord(CognitiveDomain domain) async {
    final row = await (db.select(db.abilityStates)
          ..where((t) => t.domain.equals(domain.name)))
        .getSingleOrNull();
    if (row == null) return null;
    return AbilityRecord(
      theta: row.theta,
      nTrials: row.nTrials,
      rtMeanLog: row.rtMeanLog,
      rtVar: row.rtVar,
    );
  }

  Future<Map<CognitiveDomain, AbilityRecord>> getAllRecords() async {
    final rows = await db.select(db.abilityStates).get();
    final byName = {for (final d in CognitiveDomain.values) d.name: d};
    return {
      for (final row in rows)
        if (byName[row.domain] case final domain?)
          domain: AbilityRecord(
            theta: row.theta,
            nTrials: row.nTrials,
            rtMeanLog: row.rtMeanLog,
            rtVar: row.rtVar,
          ),
    };
  }

  Future<void> saveRecord(
    CognitiveDomain domain,
    AbilityRecord record, {
    DateTime? now,
  }) async {
    await db.into(db.abilityStates).insertOnConflictUpdate(
          AbilityStatesCompanion.insert(
            domain: domain.name,
            theta: record.theta,
            nTrials: record.nTrials,
            rtMeanLog: record.rtMeanLog,
            rtVar: record.rtVar,
            updatedAt: (now ?? DateTime.now()).millisecondsSinceEpoch,
          ),
        );
  }

  Future<int?> getUpdatedAt(CognitiveDomain domain) async {
    final row = await (db.select(db.abilityStates)
          ..where((t) => t.domain.equals(domain.name)))
        .getSingleOrNull();
    return row?.updatedAt;
  }

  /// Returns the stored estimate, seeding it from demographics on first use so
  /// early sessions start near the elder's expected baseline rather than zero.
  ///
  /// Age and education years come from `AppConfigs`; if either is missing the
  /// estimator's neutral defaults (70 / 8, which seed θ = 0) are used.
  Future<AbilityRecord> getOrSeed(CognitiveDomain domain, {DateTime? now}) async {
    final existing = await getRecord(domain);
    if (existing != null) return existing;

    final age = int.tryParse(await db.appConfigsDao.getValue(ageKey) ?? '') ?? 70;
    final educationYears =
        int.tryParse(await db.appConfigsDao.getValue(educationYearsKey) ?? '') ?? 8;

    final seeded = AbilityEstimator.seed(age, educationYears);
    await saveRecord(domain, seeded, now: now);
    return seeded;
  }

  /// Applies one trial outcome to the stored estimate and returns the updated
  /// record. The θ used for the trial must be read *before* calling this, since
  /// `TrialEvents.thetaBefore` records the pre-update value.
  Future<AbilityRecord> applyTrial({
    required CognitiveDomain domain,
    required double itemDifficulty,
    required bool correct,
    required int responseTimeMs,
    DateTime? now,
  }) async {
    final before = await getOrSeed(domain, now: now);
    final after = AbilityEstimator.update(
      before,
      itemDifficulty,
      correct,
      responseTimeMs,
    );
    await saveRecord(domain, after, now: now);
    return after;
  }
}
