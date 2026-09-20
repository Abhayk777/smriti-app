import 'dart:async';
import 'dart:math';

import 'package:fuzzywuzzy/fuzzywuzzy.dart';

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

  /// Well-known members of each category, used only to *describe* what was
  /// said, never to reject it. An elder naming a local fruit this list has
  /// never heard of still scores it; the list only lets the caregiver's
  /// report say how many answers were plainly on topic.
  static const Map<String, List<String>> _categoryWords = {
    'fruits': [
      'apple', 'banana', 'mango', 'papaya', 'guava', 'orange', 'grape', 'lychee',
      'jackfruit', 'pineapple', 'pomegranate', 'coconut', 'lemon', 'plum', 'pear',
      'watermelon', 'melon', 'berry', 'date', 'fig', 'peach', 'apricot', 'kiwi',
      'aam', 'kela', 'seb', 'angur', 'anar', 'nariyal', 'amrud', 'santra',
    ],
    'vegetables': [
      'potato', 'tomato', 'onion', 'brinjal', 'eggplant', 'okra', 'ladyfinger',
      'cabbage', 'cauliflower', 'carrot', 'radish', 'pumpkin', 'gourd', 'spinach',
      'beans', 'peas', 'chilli', 'garlic', 'ginger', 'cucumber', 'bittergourd',
      'aloo', 'tamatar', 'pyaz', 'baingan', 'bhindi', 'gobi', 'gajar', 'palak',
    ],
    'animals': [
      'cow', 'buffalo', 'goat', 'sheep', 'dog', 'cat', 'horse', 'donkey', 'pig',
      'elephant', 'tiger', 'lion', 'leopard', 'deer', 'monkey', 'rabbit', 'rat',
      'mouse', 'snake', 'frog', 'fish', 'bear', 'fox', 'jackal', 'camel', 'rhino',
      'gai', 'bakri', 'kutta', 'billi', 'ghoda', 'hathi', 'sher', 'bandar',
    ],
    'birds': [
      'crow', 'sparrow', 'pigeon', 'parrot', 'peacock', 'duck', 'hen', 'cock',
      'rooster', 'eagle', 'owl', 'kingfisher', 'myna', 'koel', 'cuckoo', 'heron',
      'stork', 'crane', 'vulture', 'kite', 'hornbill', 'swan', 'goose',
      'kauwa', 'chidiya', 'kabutar', 'tota', 'mor', 'murgi', 'ullu',
    ],
    'things_in_kitchen': [
      'pot', 'pan', 'spoon', 'plate', 'bowl', 'glass', 'cup', 'knife', 'stove',
      'kettle', 'ladle', 'sieve', 'grinder', 'mortar', 'tongs', 'jar', 'bottle',
      'fridge', 'oven', 'bucket', 'tray', 'rice', 'salt', 'oil', 'flour', 'sugar',
      'bartan', 'chamach', 'thali', 'katori', 'chulha', 'kadhai', 'tawa',
    ],
    'things_in_market': [
      'vegetable', 'fruit', 'fish', 'meat', 'rice', 'flour', 'oil', 'soap',
      'cloth', 'basket', 'shop', 'money', 'bag', 'spices', 'tea', 'sugar', 'salt',
      'milk', 'egg', 'bread', 'sweets', 'flowers', 'pots', 'shoes', 'umbrella',
      'sabzi', 'machli', 'chawal', 'atta', 'tel', 'sabun', 'kapda', 'thaila',
    ],
    'things_that_are_red': [
      'tomato', 'apple', 'rose', 'blood', 'chilli', 'brick', 'fire', 'sindoor',
      'lipstick', 'cherry', 'pomegranate', 'flag', 'strawberry', 'watermelon',
      'ladybird', 'sunset', 'ruby', 'carrot', 'radish', 'hibiscus',
      'tamatar', 'gulab', 'mirch', 'laal',
    ],
    'festival_foods': [
      'laddu', 'barfi', 'jalebi', 'halwa', 'kheer', 'gujiya', 'rasgulla',
      'sandesh', 'payesh', 'pitha', 'puri', 'samosa', 'pakora', 'sweets',
      'modak', 'malpua', 'gulabjamun', 'til', 'laru', 'narikol', 'chirer',
      'mithai', 'prasad', 'khichdi', 'biryani', 'pulao',
    ],
  };

  /// Everything lower case, trimmed, with punctuation dropped, so "Mango."
  /// and " mango " are plainly the same answer.
  static String normalise(String raw) {
    final lowered = raw.toLowerCase().trim();
    final cleaned = lowered.replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Whether [word] is one the elder has already given, allowing for a slip
  /// of the tongue or of the speech recogniser.
  static bool isRepeatOf(String word, Iterable<String> already) {
    final w = normalise(word);
    if (w.isEmpty) return false;
    for (final prior in already) {
      final p = normalise(prior);
      if (p == w) return true;
      if (p.length > 3 && w.length > 3 && ratio(p, w) >= 90) return true;
    }
    return false;
  }

  /// Whether [word] is a recognised member of [category]. A false answer here
  /// never costs the elder anything; it only shades the caregiver's report.
  static bool belongsTo(String category, String word) {
    final list = _categoryWords[category];
    if (list == null) return false;
    final w = normalise(word);
    if (w.isEmpty) return false;
    for (final known in list) {
      if (known == w) return true;
      if (w.length > 3 && ratio(known, w) >= 88) return true;
    }
    return false;
  }

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

  /// Called when the fluency task ends, with everything the elder said or
  /// typed, in the order it arrived.
  ///
  /// Scoring follows how the task is scored on paper: repeated answers are
  /// counted once, and an answer the word list does not know is still counted,
  /// because the list can never hold every local name for a thing.
  void submit({
    required GameItem item,
    required List<String> itemsNamed,
    required int initiationMs,
    required int movementMs,
    String? audioPath,
    int clusters = 0,
    int switches = 0,
  }) {
    final category = item.context['category'] as String? ?? '';
    final unique = <String>[];
    var repeats = 0;
    var onCategory = 0;
    for (final raw in itemsNamed) {
      if (normalise(raw).isEmpty) continue;
      if (isRepeatOf(raw, unique)) {
        repeats++;
        continue;
      }
      unique.add(raw);
      if (belongsTo(category, raw)) onCategory++;
    }

    final count = unique.length;
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
        'expected_count': expectedMin,
        'repeats': repeats,
        'on_category': onCategory,
        'audio_path': audioPath ?? '',
        'clusters': clusters,
        'switches': switches,
        'category': category,
      },
    ));
  }

  Future<void> dispose() => _trials.close();
}
