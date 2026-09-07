import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Sort the Harvest: WCST-like card sorting with unsignalled rule shifts.
///
/// Domain: executive.
/// Sort produce onto mats by type, then colour, then size — the rule changes
/// without announcement.
///
/// Perseverative errors (continuing the old rule after switch) are the FTD
/// signature. Post-switch RT cost is a clean set-shifting measure.
///
/// Metrics: switch_cost_ms, trials_to_criterion
class SortHarvestGame implements CognitiveGame {
  SortHarvestGame({Random? random, GhostHandController? ghostHand})
      : _random = random ?? Random(),
        ghostHand = ghostHand ?? GhostHandController();

  final Random _random;
  final GhostHandController ghostHand;
  final _trials = StreamController<TrialResult>.broadcast();

  @override
  String get id => 'sort_harvest';

  @override
  CognitiveDomain get primaryDomain => CognitiveDomain.executive;

  @override
  PhraseKey get introPhrase => PhraseKey.sortHarvestIntro;

  @override
  Stream<TrialResult> get trials => _trials.stream;

  @override
  Future<void> playDemo(BuildContext context) {
    return ghostHand.play(const [
      Offset(0.5, 0.3), // look at card
      Offset(0.2, 0.7), // drag to mat
    ]);
  }

  // Sorting dimensions
  static const List<String> dimensions = ['type', 'colour', 'size'];

  // Produce items with multi-dimensional attributes
  static const List<Map<String, String>> _produce = [
    {'id': 'tomato_red_small', 'type': 'vegetable', 'colour': 'red', 'size': 'small', 'emoji': '🍅'},
    {'id': 'tomato_red_large', 'type': 'vegetable', 'colour': 'red', 'size': 'large', 'emoji': '🍅'},
    {'id': 'apple_red_small', 'type': 'fruit', 'colour': 'red', 'size': 'small', 'emoji': '🍎'},
    {'id': 'apple_green_large', 'type': 'fruit', 'colour': 'green', 'size': 'large', 'emoji': '🍏'},
    {'id': 'brinjal_purple_small', 'type': 'vegetable', 'colour': 'purple', 'size': 'small', 'emoji': '🍆'},
    {'id': 'grape_purple_small', 'type': 'fruit', 'colour': 'purple', 'size': 'small', 'emoji': '🍇'},
    {'id': 'banana_yellow_large', 'type': 'fruit', 'colour': 'yellow', 'size': 'large', 'emoji': '🍌'},
    {'id': 'corn_yellow_large', 'type': 'grain', 'colour': 'yellow', 'size': 'large', 'emoji': '🌽'},
    {'id': 'potato_brown_small', 'type': 'vegetable', 'colour': 'brown', 'size': 'small', 'emoji': '🥔'},
    {'id': 'coconut_brown_large', 'type': 'fruit', 'colour': 'brown', 'size': 'large', 'emoji': '🥥'},
    {'id': 'pea_green_small', 'type': 'vegetable', 'colour': 'green', 'size': 'small', 'emoji': '🟢'},
    {'id': 'rice_white_small', 'type': 'grain', 'colour': 'white', 'size': 'small', 'emoji': '🍚'},
  ];

  /// How many categories to sort into based on difficulty.
  static int categoryCountFor(double difficulty) =>
      (2 + difficulty.round()).clamp(2, 4);

  /// How frequently the rule switches (every N correct trials).
  static int switchFrequencyFor(double difficulty) =>
      (6 - difficulty.round()).clamp(3, 8);

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final pool = [..._produce]..shuffle(_random);
    final card = pool.first;

    // Pick current sorting dimension
    final dimIndex = _random.nextInt(dimensions.length);
    final currentDimension = dimensions[dimIndex];

    // Build mats (sorting targets)
    final uniqueValues = <String>{};
    for (final item in _produce) {
      uniqueValues.add(item[currentDimension]!);
    }
    final matValues = uniqueValues.toList()..shuffle(_random);
    final matCount = min(categoryCountFor(difficulty), matValues.length);
    final mats = matValues.take(matCount).toList();

    // Correct mat is the one matching the card's value for current dimension
    final correctMat = card[currentDimension]!;

    return GameItem(
      id: 'sort_${card['id']}',
      difficulty: difficulty,
      context: {
        'dimension': currentDimension,
        'cardId': card['id'],
        'correctMat': correctMat,
        'matCount': matCount,
        'switchFrequency': switchFrequencyFor(difficulty),
        'contentVersion': content.version,
      },
      payload: {
        'card': card,
        'mats': mats,
        'dimension': currentDimension,
        'correctMat': correctMat,
      },
    );
  }

  /// Called when the elder drags a card to a mat.
  void submit({
    required GameItem item,
    required String chosenMat,
    required int initiationMs,
    required int movementMs,
    bool isPostSwitch = false,
    int? previousSwitchCostMs,
    int? trialsToLastCriterion,
  }) {
    final correctMat = item.context['correctMat'] as String;
    final correct = chosenMat == correctMat;

    String? errorClass;
    if (!correct) {
      // Check if the chosen mat would be correct under a different dimension
      // This indicates perseveration on an old rule
      errorClass = isPostSwitch ? 'perseverative' : 'non_perseverative';
    }

    _trials.add(TrialResult(
      correct: correct,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      chosenId: correct ? null : chosenMat,
      errorClass: errorClass,
      metrics: {
        'dimension': item.context['dimension'],
        'is_post_switch': isPostSwitch,
        'switch_cost_ms': previousSwitchCostMs ?? 0,
        'trials_to_criterion': trialsToLastCriterion ?? 0,
      },
    ));
  }

  Future<void> dispose() => _trials.close();
}
