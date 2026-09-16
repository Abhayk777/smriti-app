import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// My Day: MMSE orientation subscale.
///
/// Domain: memory + attention.
/// Order the day's events, then conversational orientation questions:
/// what day, what season, what comes after lunch.
///
/// Everything about the day comes from the elder's own routine, as set by the
/// caregiver in the web app. With fewer than three routine items there is
/// nothing meaningful to order, so the game asks calendar questions instead;
/// questions about lunch and dinner are only asked when the routine has them.
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

  /// Fewest routine items worth putting in order.
  static const int minOrderingEvents = 3;

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

  /// The elder's routine, earliest first.
  static List<Map<String, Object>> _routineFrom(GameContent content) {
    final pool = content.routineItems
        .map((r) => <String, Object>{
              'id': r.id,
              'timeMin': r.timeMin,
              'label': r.labelKey,
              'icon': r.iconAsset,
            })
        .toList();
    pool.sort((a, b) => (a['timeMin'] as int).compareTo(b['timeMin'] as int));
    return pool;
  }

  /// Answer and choices for a routine question, or null when the routine
  /// cannot answer it (no lunch or dinner entry, or too few other items).
  ({String answer, List<String> options})? _routineQuestion(
    String questionId,
    List<Map<String, Object>> routine,
  ) {
    final String anchor;
    final int offset;
    switch (questionId) {
      case 'after_lunch':
        anchor = 'lunch';
        offset = 1;
      case 'before_dinner':
        anchor = 'dinner';
        offset = -1;
      default:
        return null;
    }

    final labels = routine.map((r) => r['label'] as String).toList();
    final at = labels.indexWhere((l) => l.toLowerCase().contains(anchor));
    final target = at + offset;
    if (at < 0 || target < 0 || target >= labels.length) return null;

    final answer = labels[target];
    final others = labels
        .where((l) => l != answer && !l.toLowerCase().contains(anchor))
        .toSet()
        .toList()
      ..shuffle(_random);
    if (others.isEmpty) return null;

    final options = [answer, ...others.take(3)]..shuffle(_random);
    return (answer: answer, options: options);
  }

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final routine = _routineFrom(content);
    final mode = routine.length >= minOrderingEvents
        ? modeFor(difficulty)
        : 'orientation';

    if (mode == 'ordering') {
      // Pick routine items and shuffle them for the elder to reorder
      final routinePool = routine;
      final count = min(eventCountFor(difficulty), routinePool.length);

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
      // Orientation question. Routine questions need an answer from the
      // elder's own routine; calendar questions are always available.
      final eligible = <(Map<String, Object>, ({String answer, List<String> options})?)>[];
      var minDifficulty = double.infinity;
      for (final q in _orientationQuestions) {
        final routineAnswer = _routineQuestion(q['id'] as String, routine);
        final needsRoutine =
            q['id'] == 'after_lunch' || q['id'] == 'before_dinner';
        if (needsRoutine && routineAnswer == null) continue;
        final qMin = q['difficulty_min'] as double;
        minDifficulty = min(minDifficulty, qMin);
        if (difficulty >= qMin) eligible.add((q, routineAnswer));
      }
      if (eligible.isEmpty) {
        return generateItem(minDifficulty, content);
      }
      final (question, routineAnswer) = eligible[_random.nextInt(eligible.length)];

      return GameItem(
        id: 'myday_orient_${question['id']}',
        difficulty: difficulty,
        context: {
          'mode': 'orientation',
          'questionId': question['id'],
          if (routineAnswer != null) 'answer': routineAnswer.answer,
          'contentVersion': content.version,
        },
        payload: {
          'question': question,
          'mode': 'orientation',
          if (routineAnswer != null) 'answer': routineAnswer.answer,
          if (routineAnswer != null) 'options': routineAnswer.options,
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
