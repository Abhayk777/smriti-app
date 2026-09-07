import 'dart:math';

enum CognitiveDomain { memory, attention, executive, visuospatial, language }

class AbilityRecord {
  final double theta;
  final int nTrials;
  final double rtMeanLog;
  final double rtVar;
  const AbilityRecord({
    required this.theta,
    required this.nTrials,
    required this.rtMeanLog,
    required this.rtVar,
  });
  AbilityRecord copyWith({
    double? theta,
    int? nTrials,
    double? rtMeanLog,
    double? rtVar,
  }) =>
      AbilityRecord(
        theta: theta ?? this.theta,
        nTrials: nTrials ?? this.nTrials,
        rtMeanLog: rtMeanLog ?? this.rtMeanLog,
        rtVar: rtVar ?? this.rtVar,
      );
}

class AbilityEstimator {
  static const double targetP = 0.78;
  static const double kMax = 0.40;
  static const double kMin = 0.08;
  static const double tau = 60.0;
  static const double rtAlpha = 0.1;

  /// Seed from demographics rather than zero — better than cold start.
  /// Coefficients are heuristic and documented as requiring local norming.
  static AbilityRecord seed(int age, int educationYears) {
    final theta =
        0.35 * (educationYears - 8) / 4.0 - 0.30 * (age - 70) / 10.0;
    return AbilityRecord(
      theta: theta.clamp(-2.0, 2.0),
      nTrials: 0,
      rtMeanLog: log(4000),
      rtVar: 0.25,
    );
  }

  static AbilityRecord update(
      AbilityRecord s, double itemDifficulty, bool correct, int responseTimeMs) {
    final p = 1.0 / (1.0 + exp(-(s.theta - itemDifficulty)));
    final k = kMin + (kMax - kMin) * exp(-s.nTrials / tau);
    final theta = s.theta + k * ((correct ? 1.0 : 0.0) - p);

    final clamped = responseTimeMs.clamp(200, 30000).toDouble();
    final lrt = log(clamped);
    final mean = s.rtMeanLog + rtAlpha * (lrt - s.rtMeanLog);
    final variance = s.rtVar + rtAlpha * (pow(lrt - mean, 2) - s.rtVar);

    return AbilityRecord(
      theta: theta.clamp(-4.0, 4.0),
      nTrials: s.nTrials + 1,
      rtMeanLog: mean,
      rtVar: variance,
    );
  }

  /// Difficulty that yields targetP success probability.
  static double nextDifficulty(double theta) =>
      theta - log(targetP / (1 - targetP)); // ≈ theta − 1.266
}
