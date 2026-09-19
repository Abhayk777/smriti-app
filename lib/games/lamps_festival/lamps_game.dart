import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../../core/progression/game_level_profiles.dart';
import '../../core/progression/level_scale.dart';
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

  static Map<String, double> _paramsFor(double difficulty) =>
      GameLevelProfiles.lampsFestival.paramsAt(LevelScale.difficultyToLevel(difficulty));

  /// Sequence length (span) based on difficulty (docs/PROGRESSION_PLAN.md §5.3).
  static int spanFor(double difficulty) => _paramsFor(difficulty)['span']!.toInt();

  /// Total lamp count on screen based on difficulty.
  static int lampCountFor(double difficulty) => _paramsFor(difficulty)['lampCount']!.toInt();

  /// The typical direction at this difficulty. Actual selection is a random
  /// roll against `backwardChance`, so a single call is descriptive rather
  /// than exactly what the next generated item will use.
  static String directionFor(double difficulty) =>
      _paramsFor(difficulty)['backwardChance']! >= 0.5 ? 'backward' : 'forward';

  /// How long (ms) each lamp stays lit while the sequence plays.
  static int litMsFor(double difficulty) => _paramsFor(difficulty)['litMs']!.round();

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final params = _paramsFor(difficulty);
    final span = params['span']!.toInt();
    final lampCount = params['lampCount']!.toInt();
    final direction =
        _random.nextDouble() < params['backwardChance']! ? 'backward' : 'forward';
    final litMs = params['litMs']!.round();

    // Generate lamp positions with collision prevention
    final placed = <({double x, double y})>[];
    final minDistance = lampCount <= 6
        ? 0.20
        : (lampCount <= 8 ? 0.17 : 0.14);

    final lamps = <Map<String, Object>>[];
    for (var i = 0; i < lampCount; i++) {
      final pos = _samplePosition(placed, minDistance);
      placed.add(pos);
      lamps.add({
        'index': i,
        'x': pos.x,
        'y': pos.y,
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
        'litMs': litMs,
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

  static const int _maxSampleAttempts = 50;

  /// Samples a position at least [minDistance] from all [existing] lamps.
  /// If after [_maxSampleAttempts] no position satisfies [minDistance], returns
  /// the candidate with the greatest separation to prevent overlaps.
  ({double x, double y}) _samplePosition(
    List<({double x, double y})> existing,
    double minDistance,
  ) {
    var bestX = 0.1 + _random.nextDouble() * 0.8;
    var bestY = 0.15 + _random.nextDouble() * 0.7;
    var bestDist = 0.0;

    for (var attempt = 0; attempt < _maxSampleAttempts; attempt++) {
      final x = 0.1 + _random.nextDouble() * 0.8;
      final y = 0.15 + _random.nextDouble() * 0.7;
      if (existing.isEmpty) return (x: x, y: y);

      var closest = double.infinity;
      for (final p in existing) {
        final dx = p.x - x;
        final dy = p.y - y;
        final d = sqrt(dx * dx + dy * dy);
        if (d < closest) closest = d;
      }

      if (closest >= minDistance) {
        return (x: x, y: y);
      }
      if (closest > bestDist) {
        bestDist = closest;
        bestX = x;
        bestY = y;
      }
    }
    return (x: bestX, y: bestY);
  }

  Future<void> dispose() => _trials.close();
}
