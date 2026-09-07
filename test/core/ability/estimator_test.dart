import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/ability/estimator.dart';

void main() {
  test('theta converges to true ability', () {
    const trueTheta = 1.2;
    var s = AbilityEstimator.seed(76, 8);
    final rng = Random(42);
    for (var i = 0; i < 200; i++) {
      final b = AbilityEstimator.nextDifficulty(s.theta);
      final p = 1.0 / (1.0 + exp(-(trueTheta - b)));
      s = AbilityEstimator.update(s, b, rng.nextDouble() < p, 3000);
    }
    expect((s.theta - trueTheta).abs(), lessThan(0.3));
  });

  test('seed is education-positive, age-negative, and clamped', () {
    expect(AbilityEstimator.seed(70, 8).theta, closeTo(0.0, 1e-9));
    expect(AbilityEstimator.seed(70, 16).theta,
        greaterThan(AbilityEstimator.seed(70, 8).theta));
    expect(AbilityEstimator.seed(85, 8).theta,
        lessThan(AbilityEstimator.seed(70, 8).theta));
    expect(AbilityEstimator.seed(60, 40).theta, lessThanOrEqualTo(2.0));
    expect(AbilityEstimator.seed(110, 0).theta, greaterThanOrEqualTo(-2.0));
    expect(AbilityEstimator.seed(76, 8).nTrials, 0);
  });

  test('nextDifficulty targets a 0.78 success probability', () {
    const theta = 0.5;
    final b = AbilityEstimator.nextDifficulty(theta);
    final p = 1.0 / (1.0 + exp(-(theta - b)));
    expect(p, closeTo(AbilityEstimator.targetP, 1e-9));
    expect(b, closeTo(theta - 1.266, 0.001));
  });

  test('theta stays clamped under a pathological all-correct run', () {
    var s = AbilityEstimator.seed(70, 8);
    for (var i = 0; i < 1000; i++) {
      s = AbilityEstimator.update(s, -5.0, true, 3000);
    }
    expect(s.theta, lessThanOrEqualTo(4.0));

    var t = AbilityEstimator.seed(70, 8);
    for (var i = 0; i < 1000; i++) {
      t = AbilityEstimator.update(t, 5.0, false, 3000);
    }
    expect(t.theta, greaterThanOrEqualTo(-4.0));
  });

  test('k decays with trial count, so early updates move theta further', () {
    final cold = AbilityEstimator.seed(70, 8);
    final warm = cold.copyWith(nTrials: 500);
    final coldStep =
        (AbilityEstimator.update(cold, 0.0, true, 3000).theta - cold.theta)
            .abs();
    final warmStep =
        (AbilityEstimator.update(warm, 0.0, true, 3000).theta - warm.theta)
            .abs();
    expect(coldStep, greaterThan(warmStep));
    expect(coldStep, lessThanOrEqualTo(AbilityEstimator.kMax));
    expect(warmStep, greaterThan(0.0));
  });

  test('response time tracking moves rtMeanLog and clamps outliers', () {
    final s = AbilityEstimator.seed(76, 8);
    expect(s.rtMeanLog, closeTo(log(4000), 1e-9));

    var fast = s;
    for (var i = 0; i < 50; i++) {
      fast = AbilityEstimator.update(fast, 0.0, true, 1000);
    }
    expect(fast.rtMeanLog, closeTo(log(1000), 0.05));
    expect(fast.nTrials, 50);

    // 200ms floor and 30000ms ceiling.
    expect(AbilityEstimator.update(s, 0.0, true, 1).rtMeanLog,
        closeTo(AbilityEstimator.update(s, 0.0, true, 200).rtMeanLog, 1e-12));
    expect(AbilityEstimator.update(s, 0.0, true, 999999).rtMeanLog,
        closeTo(AbilityEstimator.update(s, 0.0, true, 30000).rtMeanLog, 1e-12));
  });

  test('rtVar grows when response times are erratic', () {
    var steady = AbilityEstimator.seed(76, 8);
    var erratic = steady;
    final rng = Random(7);
    for (var i = 0; i < 100; i++) {
      steady = AbilityEstimator.update(steady, 0.0, true, 3000);
      erratic = AbilityEstimator.update(
          erratic, 0.0, true, rng.nextBool() ? 800 : 12000);
    }
    expect(erratic.rtVar, greaterThan(steady.rtVar));
  });
}
