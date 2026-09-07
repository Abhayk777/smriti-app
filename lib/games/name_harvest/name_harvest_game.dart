import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Name the Harvest: Category fluency (60-second semantic fluency).
///
/// Domain: language.
/// "Tell me all the vegetables you can think of." 60 seconds.
/// Named items appear as chips.
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

  /// Categories for fluency tasks.
  static const List<String> _categories = [
    'vegetables',
    'fruits',
    'animals',
    'things_in_kitchen',
    'things_in_market',
  ];

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    // Pick a category
    final category = _categories[_random.nextInt(_categories.length)];

    return GameItem(
      id: 'name_$category',
      difficulty: difficulty,
      context: {
        'category': category,
        'duration_seconds': 60,
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
    // A rough threshold for "correct" (meeting expectations for difficulty)
    final expectedMin = max(3, (5 + item.difficulty * 2).round());
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
