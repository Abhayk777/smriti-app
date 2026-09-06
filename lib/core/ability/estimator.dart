import 'dart:math';

class AbilityEstimator {
  double updateTheta({
    required double thetaBefore,
    required double itemDifficulty,
    required bool correct,
  }) {
    final probability = _probability(thetaBefore, itemDifficulty);

    final response = correct ? 1.0 : 0.0;

    const learningRate = 0.1;

    return thetaBefore + learningRate * (response - probability);
  }

  double _probability(double theta, double difficulty) {
    return 1.0 / (1.0 + exp(difficulty - theta));
  }
}
