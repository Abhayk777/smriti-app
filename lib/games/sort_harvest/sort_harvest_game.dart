import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../../core/progression/game_level_profiles.dart';
import '../../core/progression/level_scale.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Sort the Harvest: WCST-like card sorting with unsignalled rule shifts.
///
/// Domain: executive.
/// Produce is sorted into baskets by what it is, then by its colour, then by
/// its size. The rule **holds still** until the elder gets it right several
/// times in a row, and only then quietly moves on. That is the whole point of
/// the task: a rule that changed every card could not be learned, so nothing
/// could be measured.
///
/// Perseverative errors (sorting by the rule that has just been retired) are
/// the FTD signature, so they are detected here from the card itself rather
/// than guessed at by the screen.
///
/// Metrics: switch_cost_ms, trials_to_criterion, rule, is_post_switch
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

  // ── The rule in play, which lives across items in a session ──────────────

  /// What the baskets currently stand for.
  String? _rule;

  /// The rule that was just retired, used to recognise perseveration.
  String? _previousRule;

  /// Correct sorts in a row under [_rule].
  int _correctRun = 0;

  /// Sorts made in total since the last shift, for trials-to-criterion.
  int _sinceSwitch = 0;

  /// True while the next item is the first one under a new rule.
  bool _pendingSwitch = false;

  /// Response time on the last settled trial, so the cost of a shift can be
  /// reported as the extra time the first post-switch trial took.
  int? _steadyResponseMs;

  /// The rule the elder is sorting by right now, once the first item has been
  /// generated. Exposed for the screen's rule banner.
  String? get currentRule => _rule;

  // Sorting dimensions, easiest first.
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

  static Map<String, double> _paramsFor(double difficulty) =>
      GameLevelProfiles.sortHarvest.paramsAt(LevelScale.difficultyToLevel(difficulty));

  /// How many categories to sort into based on difficulty
  /// (docs/PROGRESSION_PLAN.md §5.3).
  static int categoryCountFor(double difficulty) => _paramsFor(difficulty)['matCount']!.toInt();

  /// How frequently the rule switches (every N correct trials).
  static int switchFrequencyFor(double difficulty) => _paramsFor(difficulty)['switchEvery']!.round();

  /// How many of [dimensions], from the front, are in play: 1 (type only) at
  /// low difficulty, growing to all 3.
  static int dimensionCountFor(double difficulty) =>
      _paramsFor(difficulty)['dimensionCount']!.toInt().clamp(1, dimensions.length);

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final params = _paramsFor(difficulty);
    final matCount = params['matCount']!.toInt();
    final dimensionCount = params['dimensionCount']!.toInt().clamp(1, dimensions.length);
    final switchFrequency = max(1, params['switchEvery']!.round());

    final eligibleDimensions = dimensions.take(dimensionCount).toList();

    // Settle on the rule. It starts at the plainest one (what the thing is)
    // and only moves on once the elder has shown they have this one.
    if (_rule == null || !eligibleDimensions.contains(_rule)) {
      _rule = eligibleDimensions.first;
      _correctRun = 0;
      _sinceSwitch = 0;
    } else if (eligibleDimensions.length > 1 && _correctRun >= switchFrequency) {
      _previousRule = _rule;
      final next = (eligibleDimensions.indexOf(_rule!) + 1) % eligibleDimensions.length;
      _rule = eligibleDimensions[next];
      _correctRun = 0;
      _sinceSwitch = 0;
      _pendingSwitch = true;
    }
    final rule = _rule!;
    final isPostSwitch = _pendingSwitch;
    _pendingSwitch = false;

    // A card that actually tells the rules apart: its value under the current
    // rule must not put it in the same basket as the retired rule would, or
    // a perseverative answer would look correct.
    final pool = [..._produce]..shuffle(_random);
    final card = pool.firstWhere(
      (c) => _previousRule == null || _previousRule == rule || c[_previousRule!] != c[rule],
      orElse: () => pool.first,
    );

    final correctMat = card[rule]!;

    // Build the baskets: always the right one, plus other real values of the
    // same kind so every basket is a plausible home for something.
    final uniqueValues = <String>{for (final item in _produce) item[rule]!};
    final otherValues = uniqueValues.where((v) => v != correctMat).toList()
      ..shuffle(_random);
    final actualMatCount = min(matCount, uniqueValues.length);
    final mats = [
      correctMat,
      ...otherValues.take(max(0, actualMatCount - 1)),
    ]..shuffle(_random);

    return GameItem(
      id: 'sort_${card['id']}',
      difficulty: difficulty,
      context: {
        'dimension': rule,
        'cardId': card['id'],
        'correctMat': correctMat,
        'matCount': actualMatCount,
        'switchFrequency': switchFrequency,
        'isPostSwitch': isPostSwitch,
        'contentVersion': content.version,
      },
      payload: {
        'card': card,
        'mats': mats,
        'dimension': rule,
        'correctMat': correctMat,

        // The screen shows a calm "we are matching by ..." note on the first
        // card under a new rule, so a shift is never a silent trap.
        'ruleChanged': isPostSwitch,
        'previousDimension': _previousRule,
      },
    );
  }

  /// Called when the elder puts a card in a basket.
  void submit({
    required GameItem item,
    required String chosenMat,
    required int initiationMs,
    required int movementMs,
  }) {
    final correctMat = item.context['correctMat'] as String;
    final correct = chosenMat == correctMat;
    final isPostSwitch = item.context['isPostSwitch'] as bool? ?? false;
    final card = (item.payload['card'] as Map?)?.cast<String, String>();

    _sinceSwitch++;
    if (correct) {
      _correctRun++;
    } else {
      _correctRun = 0;
    }

    // Perseveration: the basket chosen is exactly where the retired rule
    // would have put this card.
    String? errorClass;
    if (!correct) {
      final previous = _previousRule;
      final byOldRule = previous == null ? null : card?[previous];
      errorClass = byOldRule != null && byOldRule == chosenMat
          ? 'perseverative'
          : 'non_perseverative';
    }

    // The cost of a shift: how much longer the first card under a new rule
    // took than the settled pace before it.
    final responseMs = initiationMs + movementMs;
    final switchCostMs =
        isPostSwitch && _steadyResponseMs != null ? max(0, responseMs - _steadyResponseMs!) : 0;
    if (!isPostSwitch) _steadyResponseMs = responseMs;

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
        'switch_cost_ms': switchCostMs,
        'trials_to_criterion': _sinceSwitch,
        'correct_run': _correctRun,
      },
    ));
  }

  Future<void> dispose() => _trials.close();
}
