import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Lamps of the Festival: Corsi block-tapping (spatial span).
///
/// Domain: visuospatial working memory.
/// Oil lamps arranged in irregular pattern. They light in sequence; elder taps
/// same order. Backward variant at higher difficulty.
///
/// Language-free, literacy-independent.
///
/// Error classes:
///   - `sequence_error`: right lamps, wrong order (working-memory failure)
///   - `item_error`: wrong lamp entirely (encoding failure)
///
/// Metrics: span_achieved, direction (forward/backward)
class LampsGame implements CognitiveGame {
  LampsGame({Random? random, GhostHandController? ghostHand})
      : _random = random ?? Random(),
        ghostHand = ghostHand ?? GhostHandController();

  final Random _random;
  final GhostHandController ghostHand;
  final _trials = StreamController<TrialResult>.broadcast();

  @override
  String get id => 'lamps_festival';

  @override
  CognitiveDomain get primaryDomain => CognitiveDomain.visuospatial;

  @override
  PhraseKey get introPhrase => PhraseKey.lampsFestivalIntro;

  @override
  Stream<TrialResult> get trials => _trials.stream;

  @override
  Future<void> playDemo(BuildContext context) {
    return ghostHand.play(const [
      Offset(0.3, 0.4),
      Offset(0.6, 0.3),
      Offset(0.5, 0.6),
    ]);
  }

  /// Sequence length (span) based on difficulty.
  static int spanFor(double difficulty) =>
      (2 + difficulty).round().clamp(2, 7);

  /// Total lamp count on screen based on difficulty.
  static int lampCountFor(double difficulty) =>
      (6 + difficulty).round().clamp(5, 12);

  /// Whether to use backward direction at higher difficulty.
  static String directionFor(double difficulty) =>
      difficulty >= 1.5 ? 'backward' : 'forward';

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final span = spanFor(difficulty);
    final lampCount = lampCountFor(difficulty);
    final direction = directionFor(difficulty);

    // Generate lamp positions in irregular pattern
    final lamps = <Map<String, Object>>[];
    for (var i = 0; i < lampCount; i++) {
      lamps.add({
        'index': i,
        'x': 0.1 + _random.nextDouble() * 0.8,
        'y': 0.15 + _random.nextDouble() * 0.7,
      });
    }

    // Generate sequence (which lamps light up, in order)
    final indices = List.generate(lampCount, (i) => i)..shuffle(_random);
    final sequence = indices.take(span).toList();

    return GameItem(
      id: 'lamps_${direction}_$span',
      difficulty: difficulty,
      context: {
        'span': span,
        'lampCount': lampCount,
        'direction': direction,
        'sequence': sequence,
        'contentVersion': content.version,
      },
      payload: {
        'lamps': lamps,
        'sequence': sequence,
        'direction': direction,
      },
    );
  }

  /// Called when the elder finishes tapping lamps.
  void submit({
    required GameItem item,
    required List<int> tappedSequence,
    required int initiationMs,
    required int movementMs,
  }) {
    final originalSequence =
        (item.context['sequence'] as List<Object?>).cast<int>();
    final direction = item.context['direction'] as String;

    // Expected sequence depends on direction
    final expectedSequence = direction == 'backward'
        ? originalSequence.reversed.toList()
        : originalSequence;

    final correct = _sequencesMatch(tappedSequence, expectedSequence);

    String? errorClass;
    if (!correct) {
      // Check error type
      final tappedSet = tappedSequence.toSet();
      final expectedSet = expectedSequence.toSet();
      if (tappedSet.difference(expectedSet).isNotEmpty) {
        errorClass = 'item_error'; // Tapped a lamp not in the sequence
      } else {
        errorClass = 'sequence_error'; // Right lamps, wrong order
      }
    }

    _trials.add(TrialResult(
      correct: correct,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      errorClass: errorClass,
      metrics: {
        'span_achieved': correct ? expectedSequence.length : _longestCorrectPrefix(tappedSequence, expectedSequence),
        'direction': direction,
      },
    ));
  }

  static bool _sequencesMatch(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _longestCorrectPrefix(List<int> tapped, List<int> expected) {
    var count = 0;
    for (var i = 0; i < min(tapped.length, expected.length); i++) {
      if (tapped[i] == expected[i]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  Future<void> dispose() => _trials.close();
}
