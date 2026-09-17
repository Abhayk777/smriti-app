import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../../core/progression/game_level_profiles.dart';
import '../../core/progression/level_scale.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Name the Harvest: Category fluency (60-second semantic fluency).
///
/// Domain: language.
/// "Tell me all the vegetables you can think of." 60 seconds.
/// Named items appear as chips.
///
/// Difficulty raises how many items count as a good showing, then widens the
/// pool of categories offered (docs/PROGRESSION_PLAN.md §5.3).
///
/// Among the most sensitive brief screens. Entirely verbal, no reading.
/// Stores audio always so a human can verify.
///
/// Metrics: items_named, audio_path, clusters, switches
class NameHarvestGame implements CognitiveGame {
  NameHarvestGame({Random? random, GhostHandController? ghostHand})
      : _random = random ?? Random(),
        ghostHand = ghostHand ?? GhostHandController();

  final Random _random;
  final GhostHandController ghostHand;
  final _trials = StreamController<TrialResult>.broadcast();

  @override
  String get id => 'name_harvest';

  @override
  CognitiveDomain get primaryDomain => CognitiveDomain.language;

  @override
  PhraseKey get introPhrase => PhraseKey.nameHarvestIntro;

  @override
  Stream<TrialResult> get trials => _trials.stream;

  @override
  Future<void> playDemo(BuildContext context) {
    return ghostHand.play(const [
      Offset(0.5, 0.5), // microphone area
    ]);
  }

  /// Categories for fluency tasks, grouped by the tier that unlocks them
  /// (docs/PROGRESSION_PLAN.md §5.3). New tiers or categories can be appended
  /// here without touching anything else, other than the widget's display
  /// labels for any brand-new category id.
  static const List<List<String>> _categoriesByTier = [
    ['fruits', 'vegetables', 'animals'],
    ['things_in_kitchen', 'things_in_market'],
    ['things_that_are_red', 'festival_foods', 'birds'],
  ];

  static Map<String, double> _paramsFor(double difficulty) =>
      GameLevelProfiles.nameHarvest.paramsAt(LevelScale.difficultyToLevel(difficulty));

  /// How many items named counts as a good showing at this difficulty
  /// (docs/PROGRESSION_PLAN.md §5.3).
  static int expectedCountFor(double difficulty) => _paramsFor(difficulty)['expectedCount']!.toInt();

  /// How many category tiers are unlocked.
  static int categoryTierFor(double difficulty) =>
      _paramsFor(difficulty)['categoryTier']!.toInt().clamp(1, _categoriesByTier.length);

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final params = _paramsFor(difficulty);
    final expectedCount = params['expectedCount']!.toInt();
    final categoryTier =
        params['categoryTier']!.toInt().clamp(1, _categoriesByTier.length);

    final eligibleCategories = _categoriesByTier
        .take(categoryTier)
        .expand((tier) => tier)
        .toList();
    final category = eligibleCategories[_random.nextInt(eligibleCategories.length)];

    return GameItem(
      id: 'name_$category',
      difficulty: difficulty,
      context: {
        'category': category,
        'duration_seconds': 60,
        'expectedCount': expectedCount,
        'contentVersion': content.version,
      },
      payload: {
        'category': category,
        'durationSeconds': 60,
      },
    );
  }

  /// Called when the 60-second fluency task completes.
  void submit({
    required GameItem item,
    required List<String> itemsNamed,
    required int initiationMs,
    required int movementMs,
    String? audioPath,
    int clusters = 0,
    int switches = 0,
  }) {
    // Score: more items named = better performance
    final count = itemsNamed.length;
    final expectedMin = (item.context['expectedCount'] as int?) ??
        max(3, (5 + item.difficulty * 2).round());
    final correct = count >= expectedMin;

    _trials.add(TrialResult(
      correct: correct,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      metrics: {
        'items_named': count,
        'audio_path': audioPath ?? '',
        'clusters': clusters,
        'switches': switches,
        'category': item.context['category'],
      },
    ));
  }

  Future<void> dispose() => _trials.close();
}
