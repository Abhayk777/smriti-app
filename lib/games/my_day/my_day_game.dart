import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// My Day: MMSE orientation subscale.
///
/// Domain: memory + attention.
/// Order the day's events, then conversational orientation questions —
/// what day, what season, what comes after lunch.
///
/// Difficulty: item count → question specificity (season → month → date)
class MyDayGame implements CognitiveGame {
  MyDayGame({Random? random, GhostHandController? ghostHand})
      : _random = random ?? Random(),
        ghostHand = ghostHand ?? GhostHandController();

  final Random _random;
  final GhostHandController ghostHand;
  final _trials = StreamController<TrialResult>.broadcast();

  @override
  String get id => 'my_day';

  @override
  CognitiveDomain get primaryDomain => CognitiveDomain.memory;

  @override
  PhraseKey get introPhrase => PhraseKey.myDayIntro;

  @override
  Stream<TrialResult> get trials => _trials.stream;

  @override
  Future<void> playDemo(BuildContext context) {
    return ghostHand.play(const [
      Offset(0.5, 0.2),
      Offset(0.3, 0.5),
      Offset(0.7, 0.5),
    ]);
  }

  /// Default routine if none from content.
  static const List<Map<String, Object>> _defaultRoutine = [
    {'id': 'wake_up', 'timeMin': 360, 'label': 'Wake Up', 'icon': '☀️'},
    {'id': 'morning_tea', 'timeMin': 390, 'label': 'Morning Tea', 'icon': '🍵'},
    {'id': 'breakfast', 'timeMin': 480, 'label': 'Breakfast', 'icon': '🍳'},
    {'id': 'morning_walk', 'timeMin': 540, 'label': 'Morning Walk', 'icon': '🚶'},
    {'id': 'lunch', 'timeMin': 720, 'label': 'Lunch', 'icon': '🍛'},
    {'id': 'afternoon_rest', 'timeMin': 840, 'label': 'Rest', 'icon': '😴'},
    {'id': 'evening_tea', 'timeMin': 960, 'label': 'Evening Tea', 'icon': '🍵'},
    {'id': 'dinner', 'timeMin': 1140, 'label': 'Dinner', 'icon': '🍽️'},
    {'id': 'sleep', 'timeMin': 1260, 'label': 'Sleep', 'icon': '🌙'},
  ];

  /// Orientation questions with increasing specificity.
  static const List<Map<String, Object>> _orientationQuestions = [
    {
      'id': 'season',
      'question': 'What season is it now?',
      'difficulty_min': -1.0,
    },
    {
      'id': 'day_of_week',
      'question': 'What day of the week is it?',
      'difficulty_min': 0.0,
    },
    {
      'id': 'month',
      'question': 'What month is it?',
      'difficulty_min': 0.5,
    },
    {
      'id': 'after_lunch',
      'question': 'What do you usually do after lunch?',
      'difficulty_min': -0.5,
    },
    {
      'id': 'before_dinner',
      'question': 'What do you usually do before dinner?',
      'difficulty_min': 0.0,
    },
    {
      'id': 'date',
      'question': 'What is today\'s date?',
      'difficulty_min': 1.5,
    },
  ];

  /// Number of events to order based on difficulty.
  static int eventCountFor(double difficulty) =>
      (3 + difficulty).round().clamp(3, 7);

  /// Mode: 'ordering' at low difficulty, 'orientation' at higher.
  static String modeFor(double difficulty) =>
      difficulty < 0.5 ? 'ordering' : 'orientation';

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final mode = modeFor(difficulty);

    if (mode == 'ordering') {
      // Pick routine items and shuffle them for the elder to reorder
      final routinePool = content.routineItems.isNotEmpty
          ? content.routineItems
              .map((r) => {
                    'id': r.id,
                    'timeMin': r.timeMin,
                    'label': r.labelKey,
                    'icon': r.iconAsset,
                  })
              .toList()
          : _defaultRoutine.toList();

      final count = min(eventCountFor(difficulty), routinePool.length);
      routinePool.sort(
          (a, b) => (a['timeMin'] as int).compareTo(b['timeMin'] as int));

      // Pick evenly spaced items so the ordering is clear
      final step = routinePool.length / count;
      final selected = <Map<String, Object>>[];
      for (var i = 0; i < count; i++) {
        selected.add(routinePool[(i * step).floor()]);
      }
      final correctOrder =
          selected.map((e) => e['id'] as String).toList();
      final shuffled = [...selected]..shuffle(_random);

      return GameItem(
        id: 'myday_order_$count',
        difficulty: difficulty,
        context: {
          'mode': 'ordering',
          'eventCount': count,
          'correctOrder': correctOrder,
          'contentVersion': content.version,
        },
        payload: {
          'events': shuffled,
          'correctOrder': correctOrder,
          'mode': 'ordering',
        },
      );
    } else {
      // Orientation question
      final eligible = _orientationQuestions
          .where((q) => difficulty >= (q['difficulty_min'] as double))
          .toList();
      if (eligible.isEmpty) {
        return generateItem(difficulty - 1, content);
      }
      final question = eligible[_random.nextInt(eligible.length)];

      return GameItem(
        id: 'myday_orient_${question['id']}',
        difficulty: difficulty,
        context: {
          'mode': 'orientation',
          'questionId': question['id'],
          'contentVersion': content.version,
        },
        payload: {
          'question': question,
          'mode': 'orientation',
        },
      );
    }
  }

  /// Called when the elder submits an event ordering.
  void submitOrdering({
    required GameItem item,
    required List<String> chosenOrder,
    required int initiationMs,
    required int movementMs,
  }) {
    final correctOrder =
        (item.context['correctOrder'] as List<Object?>).cast<String>();
    final correct =
        _listsEqual(chosenOrder, correctOrder);
    final misplacedCount = _countMisplaced(chosenOrder, correctOrder);

    _trials.add(TrialResult(
      correct: correct,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      errorClass: correct ? null : 'ordering_error',
      metrics: {
        'mode': 'ordering',
        'event_count': correctOrder.length,
        'misplaced': misplacedCount,
      },
    ));
  }

  /// Called when the elder answers an orientation question.
  void submitOrientation({
    required GameItem item,
    required bool correct,
    required int initiationMs,
    required int movementMs,
  }) {
    _trials.add(TrialResult(
      correct: correct,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      errorClass: correct ? null : 'orientation_error',
      metrics: {
        'mode': 'orientation',
        'questionId': item.context['questionId'],
      },
    ));
  }

  static bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _countMisplaced(List<String> chosen, List<String> correct) {
    var count = 0;
    for (var i = 0; i < min(chosen.length, correct.length); i++) {
      if (chosen[i] != correct[i]) count++;
    }
    return count;
  }

  Future<void> dispose() => _trials.close();
}
