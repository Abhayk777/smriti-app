import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Weaving Patterns: Visual discrimination / figure matching (Benton-family).
///
/// Domain: visuospatial perception.
/// A Manipuri textile pattern is shown. Pick the matching one from four,
/// or complete the missing section of a woven border.
///
/// LBD's earliest deficit is visual perception, not memory.
///
/// Error classes:
///   - `mirror`: chose the mirror image
///   - `rotation`: chose a rotated version
///   - `detail`: chose the near-identical distractor
///   - `random`: chose a completely different pattern
///
/// Metrics: distractor_similarity (0.0–1.0), rotation_deg
class WeavingGame implements CognitiveGame {
  WeavingGame({Random? random, GhostHandController? ghostHand})
      : _random = random ?? Random(),
        ghostHand = ghostHand ?? GhostHandController();

  final Random _random;
  final GhostHandController ghostHand;
  final _trials = StreamController<TrialResult>.broadcast();

  @override
  String get id => 'weaving_patterns';

  @override
  CognitiveDomain get primaryDomain => CognitiveDomain.visuospatial;

  @override
  PhraseKey get introPhrase => PhraseKey.weavingPatternsIntro;

  @override
  Stream<TrialResult> get trials => _trials.stream;

  @override
  Future<void> playDemo(BuildContext context) {
    return ghostHand.play(const [
      Offset(0.5, 0.2), // look at pattern
      Offset(0.3, 0.7), // tap matching one
    ]);
  }

  /// Number of elements in the pattern based on difficulty.
  static int elementCountFor(double difficulty) =>
      (3 + difficulty).round().clamp(2, 8);

  /// Distractor similarity increases with difficulty (0.0 = easy, 1.0 = hard).
  static double distractorSimilarityFor(double difficulty) =>
      ((difficulty + 2) / 5).clamp(0.0, 1.0);

  /// Pattern types for procedural generation.
  static const List<String> _patternTypes = [
    'stripes',
    'diamonds',
    'zigzag',
    'chevron',
    'dots',
    'crosses',
  ];

  /// Colours used in patterns (warm, Manipuri-inspired).
  static const List<int> _patternColors = [
    0xFFC75B39, // terracotta
    0xFF3D5A8A, // indigo
    0xFFD99A2B, // marigold
    0xFF4A7C59, // leaf green
    0xFF8F3E26, // dark terracotta
    0xFF26385A, // dark indigo
  ];

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final elementCount = elementCountFor(difficulty);
    final similarity = distractorSimilarityFor(difficulty);
    final patternType =
        _patternTypes[_random.nextInt(_patternTypes.length)];

    // Generate a "seed" pattern as a list of color indices
    final patternSeed = List.generate(
      elementCount,
      (_) => _random.nextInt(_patternColors.length),
    );

    // Generate distractors with varying error types
    final correctId = 'correct';
    final options = <Map<String, Object>>[
      {'id': correctId, 'pattern': patternSeed, 'errorType': 'none'},
    ];

    // Mirror distractor
    options.add({
      'id': 'mirror',
      'pattern': patternSeed.reversed.toList(),
      'errorType': 'mirror',
    });

    // Rotation distractor (shift elements)
    final rotated = [...patternSeed];
    final shift = max(1, elementCount ~/ 3);
    for (var i = 0; i < shift && rotated.length > 1; i++) {
      rotated.insert(0, rotated.removeLast());
    }
    options.add({
      'id': 'rotation',
      'pattern': rotated,
      'errorType': 'rotation',
    });

    // Detail distractor (change one element)
    final detail = [...patternSeed];
    final changeIdx = _random.nextInt(detail.length);
    detail[changeIdx] = (detail[changeIdx] + 1) % _patternColors.length;
    options.add({
      'id': 'detail',
      'pattern': detail,
      'errorType': 'detail',
    });

    options.shuffle(_random);

    return GameItem(
      id: 'weave_${patternType}_$elementCount',
      difficulty: difficulty,
      context: {
        'patternType': patternType,
        'elementCount': elementCount,
        'distractor_similarity': similarity,
        'contentVersion': content.version,
      },
      payload: {
        'targetPattern': patternSeed,
        'patternType': patternType,
        'options': options,
        'colors': _patternColors,
        'correctId': correctId,
      },
    );
  }

  /// Called when the elder picks a pattern.
  void submit({
    required GameItem item,
    required String chosenId,
    required int initiationMs,
    required int movementMs,
  }) {
    final correctId = item.payload['correctId'] as String;
    final correct = chosenId == correctId;
    final options = (item.payload['options'] as List<Object?>)
        .cast<Map<String, Object>>();

    String? errorClass;
    if (!correct) {
      final chosen = options.where((o) => o['id'] == chosenId).firstOrNull;
      errorClass = (chosen?['errorType'] as String?) ?? 'random';
    }

    _trials.add(TrialResult(
      correct: correct,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      chosenId: correct ? null : chosenId,
      errorClass: errorClass,
      metrics: {
        'distractor_similarity': item.context['distractor_similarity'],
        'rotation_deg': errorClass == 'rotation' ? 90 : 0,
        'pattern_type': item.context['patternType'],
      },
    ));
  }

  Future<void> dispose() => _trials.close();
}
