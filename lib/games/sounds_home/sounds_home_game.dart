import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../../core/progression/game_level_profiles.dart';
import '../../core/progression/level_scale.dart';
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

  /// The sounds most easily mistaken for the target or for each other
  /// (docs/PROGRESSION_PLAN.md §5.3): the rooster and cricket are bird-like,
  /// the bell and temple bell are their own confusable family. Drawn from
  /// more often as `lureChance` rises.
  static const List<String> _lureSounds = ['rooster', 'cricket', 'bell', 'temple_bell'];

  static const String targetSound = 'bird';

  static Map<String, double> _paramsFor(double difficulty) =>
      GameLevelProfiles.soundsHome.paramsAt(LevelScale.difficultyToLevel(difficulty));

  /// Target frequency (proportion of stimuli that are targets)
  /// (docs/PROGRESSION_PLAN.md §5.3).
  static double targetFrequencyFor(double difficulty) => _paramsFor(difficulty)['targetFrequency']!;

  /// Inter-stimulus interval range (ms).
  static int isiMinFor(double difficulty) => _paramsFor(difficulty)['isiMinMs']!.round();

  static int isiMaxFor(double difficulty) => _paramsFor(difficulty)['isiMaxMs']!.round();

  /// How often a non-target stimulus is one of the easily-confused
  /// [_lureSounds] rather than any of [_distractorSounds].
  static double lureChanceFor(double difficulty) => _paramsFor(difficulty)['lureChance']!;

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final params = _paramsFor(difficulty);
    final targetFreq = params['targetFrequency']!;
    final isiMin = params['isiMinMs']!.round();
    final isiMax = params['isiMaxMs']!.round();
    final lureChance = params['lureChance']!;

    // Generate a sequence of stimuli for the full 90 seconds
    final stimuli = <Map<String, Object>>[];
    var elapsed = 0;
    while (elapsed < totalDurationSeconds * 1000) {
      final isi = isiMin + _random.nextInt(isiMax - isiMin);
      elapsed += isi;
      if (elapsed >= totalDurationSeconds * 1000) break;

      final isTarget = _random.nextDouble() < targetFreq;
      final isLure = !isTarget && _random.nextDouble() < lureChance;
      final sound = isTarget
          ? targetSound
          : isLure
              ? _lureSounds[_random.nextInt(_lureSounds.length)]
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
