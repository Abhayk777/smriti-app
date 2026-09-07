import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Trace the Path: Trail Making Test A and B.
///
/// Domain: visuospatial + executive.
/// Connect numbered stones across a village map. Then alternating (TMT-B).
///
/// B minus A is a standard executive index. Touchscreen gives stroke velocity,
/// jitter, and pen-lifts for free.
///
/// Metrics: variant (A/B), completion_ms, stroke_velocity, lifts, jitter
class TracePathGame implements CognitiveGame {
  TracePathGame({Random? random, GhostHandController? ghostHand})
      : _random = random ?? Random(),
        ghostHand = ghostHand ?? GhostHandController();

  final Random _random;
  final GhostHandController ghostHand;
  final _trials = StreamController<TrialResult>.broadcast();

  @override
  String get id => 'trace_path';

  @override
  CognitiveDomain get primaryDomain => CognitiveDomain.visuospatial;

  @override
  PhraseKey get introPhrase => PhraseKey.tracePathIntro;

  @override
  Stream<TrialResult> get trials => _trials.stream;

  @override
  Future<void> playDemo(BuildContext context) {
    return ghostHand.play(const [
      Offset(0.2, 0.3),
      Offset(0.4, 0.5),
      Offset(0.6, 0.3),
      Offset(0.8, 0.6),
    ]);
  }

  /// Number of nodes based on difficulty.
  static int nodeCountFor(double difficulty) =>
      (5 + difficulty * 2).round().clamp(4, 15);

  /// Whether to use alternating mode (TMT-B) at higher difficulty.
  static String variantFor(double difficulty) =>
      difficulty >= 1.0 ? 'B' : 'A';

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final nodeCount = nodeCountFor(difficulty);
    final variant = variantFor(difficulty);

    // Generate random node positions (normalised 0-1)
    final nodes = <Map<String, Object>>[];
    for (var i = 0; i < nodeCount; i++) {
      nodes.add({
        'index': i,
        'x': 0.1 + _random.nextDouble() * 0.8,
        'y': 0.1 + _random.nextDouble() * 0.8,
        'label': variant == 'A'
            ? '${i + 1}'
            : (i.isEven ? '${i ~/ 2 + 1}' : _letterAt(i ~/ 2)),
        'type': variant == 'A' ? 'number' : (i.isEven ? 'number' : 'letter'),
      });
    }

    return GameItem(
      id: 'trace_${variant}_$nodeCount',
      difficulty: difficulty,
      context: {
        'variant': variant,
        'nodeCount': nodeCount,
        'contentVersion': content.version,
      },
      payload: {
        'nodes': nodes,
        'variant': variant,
      },
    );
  }

  static String _letterAt(int i) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[i % letters.length];
  }

  /// Called when the elder completes (or abandons) the trail.
  void submit({
    required GameItem item,
    required bool completed,
    required int completionMs,
    required double strokeVelocity,
    required int lifts,
    required double jitter,
    required int initiationMs,
    required int movementMs,
    int errorsCount = 0,
  }) {
    _trials.add(TrialResult(
      correct: completed && errorsCount == 0,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      errorClass: errorsCount > 0 ? 'sequence_error' : null,
      metrics: {
        'variant': item.context['variant'],
        'completion_ms': completionMs,
        'stroke_velocity': strokeVelocity,
        'lifts': lifts,
        'jitter': jitter,
        'errors': errorsCount,
      },
    ));
  }

  Future<void> dispose() => _trials.close();
}
