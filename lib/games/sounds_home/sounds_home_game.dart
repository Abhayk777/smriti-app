import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Sounds of Home: Continuous performance test, auditory variant.
///
/// Domain: sustained attention.
/// "You'll hear village sounds. Tap the drum when you hear the bird."
/// Sounds play at irregular intervals for 90 seconds. Targets ~1 in 5.
///
/// Block-by-block performance across three 30-second blocks reveals
/// the fluctuating-attention signature of LBD.
///
/// Fully usable by someone with significant visual impairment.
///
/// Metrics: hits, misses, false_alarms, rt_sd,
///          block_hits: [n,n,n], block_rt: [n,n,n]
class SoundsHomeGame implements CognitiveGame {
  SoundsHomeGame({Random? random, GhostHandController? ghostHand})
      : _random = random ?? Random(),
        ghostHand = ghostHand ?? GhostHandController();

  final Random _random;
  final GhostHandController ghostHand;
  final _trials = StreamController<TrialResult>.broadcast();

  @override
  String get id => 'sounds_home';

  @override
  CognitiveDomain get primaryDomain => CognitiveDomain.attention;

  @override
  PhraseKey get introPhrase => PhraseKey.soundsHomeIntro;

  @override
  Stream<TrialResult> get trials => _trials.stream;

  @override
  Future<void> playDemo(BuildContext context) {
    return ghostHand.play(const [
      Offset(0.5, 0.5), // drum tap area
    ]);
  }

  /// Duration in seconds.
  static const int totalDurationSeconds = 90;
  static const int blocksCount = 3;
  static const int blockDurationSeconds = totalDurationSeconds ~/ blocksCount;

  /// Sound types used in the test.
  static const List<String> _distractorSounds = [
    'rain', 'wind', 'cow', 'dog', 'river', 'thunder',
    'cricket', 'bell', 'rooster', 'temple_bell',
  ];

  static const String targetSound = 'bird';

  /// Target frequency (proportion of stimuli that are targets).
  static double targetFrequencyFor(double difficulty) =>
      (0.25 - difficulty * 0.03).clamp(0.1, 0.3);

  /// Inter-stimulus interval range (ms).
  static int isiMinFor(double difficulty) =>
      (2500 - difficulty * 200).round().clamp(1500, 3000);

  static int isiMaxFor(double difficulty) =>
      (4000 - difficulty * 200).round().clamp(2500, 5000);

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final targetFreq = targetFrequencyFor(difficulty);
    final isiMin = isiMinFor(difficulty);
    final isiMax = isiMaxFor(difficulty);

    // Generate a sequence of stimuli for the full 90 seconds
    final stimuli = <Map<String, Object>>[];
    var elapsed = 0;
    while (elapsed < totalDurationSeconds * 1000) {
      final isi = isiMin + _random.nextInt(isiMax - isiMin);
      elapsed += isi;
      if (elapsed >= totalDurationSeconds * 1000) break;

      final isTarget = _random.nextDouble() < targetFreq;
      final sound = isTarget
          ? targetSound
          : _distractorSounds[_random.nextInt(_distractorSounds.length)];

      stimuli.add({
        'timeMs': elapsed,
        'sound': sound,
        'isTarget': isTarget,
        'block': elapsed < 30000
            ? 0
            : (elapsed < 60000 ? 1 : 2),
      });
    }

    return GameItem(
      id: 'sounds_${stimuli.length}',
      difficulty: difficulty,
      context: {
        'stimuliCount': stimuli.length,
        'targetCount': stimuli.where((s) => s['isTarget'] == true).length,
        'targetFrequency': targetFreq,
        'durationSeconds': totalDurationSeconds,
        'contentVersion': content.version,
      },
      payload: {
        'stimuli': stimuli,
        'targetSound': targetSound,
        'durationSeconds': totalDurationSeconds,
      },
    );
  }

  /// Called when the 90-second task completes with all response data.
  void submit({
    required GameItem item,
    required int hits,
    required int misses,
    required int falseAlarms,
    required double rtStdDev,
    required List<int> blockHits,
    required List<double> blockRt,
    required int initiationMs,
    required int movementMs,
  }) {
    // Overall performance: correct if hit rate > miss rate
    final totalTargets = hits + misses;
    final correct = totalTargets > 0 && hits > misses;

    String? errorClass;
    if (!correct) {
      if (falseAlarms > hits) {
        errorClass = 'impulsive'; // More false alarms than hits
      } else {
        errorClass = 'inattentive'; // Too many misses
      }
    }

    _trials.add(TrialResult(
      correct: correct,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      errorClass: errorClass,
      metrics: {
        'hits': hits,
        'misses': misses,
        'false_alarms': falseAlarms,
        'rt_sd': rtStdDev,
        'block_hits': blockHits,
        'block_rt': blockRt,
      },
    ));
  }

  Future<void> dispose() => _trials.close();
}
