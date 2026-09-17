import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../../core/progression/game_level_profiles.dart';
import '../../core/progression/level_scale.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Trace the Path: Trail Making Test A and B.
///
/// Domain: visuospatial + executive.
/// Connect numbered stones across a village map. Then alternating (TMT-B).
/// Above a set level, a few unlabelled decoy stones are scattered in too
/// (docs/PROGRESSION_PLAN.md §5.3); tapping one does nothing and is never
/// counted as an error, they are there only to test the elder's ability to
/// stay on the real path amid distraction.
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

  /// Minimum distance between two stones, in the same normalised 0-1 space
  /// as their `x`/`y`. `generateItem` has no idea how large the widget will
  /// actually render (phone or tablet), so this is a conservative constant
  /// tuned to stay comfortably tappable even on a narrow phone.
  static const double _minNormalizedDistance = 0.18;
  static const int _maxSampleAttempts = 50;

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

  static Map<String, double> _paramsFor(double difficulty) =>
      GameLevelProfiles.tracePath.paramsAt(LevelScale.difficultyToLevel(difficulty));

  /// Number of nodes based on difficulty (docs/PROGRESSION_PLAN.md §5.3).
  static int nodeCountFor(double difficulty) => _paramsFor(difficulty)['nodeCount']!.round();

  /// The typical variant at this difficulty. Actual selection is a random
  /// roll against `variantBChance`, so a single call is descriptive rather
  /// than exactly what the next generated item will use.
  static String variantFor(double difficulty) =>
      _paramsFor(difficulty)['variantBChance']! >= 0.5 ? 'B' : 'A';

  /// Number of unlabelled decoy stones at this difficulty.
  static int decoyCountFor(double difficulty) => _paramsFor(difficulty)['decoyStones']!.toInt();

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final params = _paramsFor(difficulty);
    final nodeCount = params['nodeCount']!.round();
    final variant = _random.nextDouble() < params['variantBChance']! ? 'B' : 'A';
    final decoyCount = params['decoyStones']!.toInt();

    // Generate random node positions (normalised 0-1), each kept a minimum
    // distance from every stone placed so far (real or decoy).
    final placed = <({double x, double y})>[];
    final nodes = <Map<String, Object>>[];
    for (var i = 0; i < nodeCount; i++) {
      final pos = _samplePosition(placed);
      placed.add(pos);
      nodes.add({
        'index': i,
        'x': pos.x,
        'y': pos.y,
        'label': variant == 'A'
            ? '${i + 1}'
            : (i.isEven ? '${i ~/ 2 + 1}' : _letterAt(i ~/ 2)),
        'type': variant == 'A' ? 'number' : (i.isEven ? 'number' : 'letter'),
      });
    }

    final decoys = <Map<String, Object>>[];
    for (var i = 0; i < decoyCount; i++) {
      final pos = _samplePosition(placed);
      placed.add(pos);
      decoys.add({'x': pos.x, 'y': pos.y});
    }

    return GameItem(
      id: 'trace_${variant}_$nodeCount',
      difficulty: difficulty,
      context: {
        'variant': variant,
        'nodeCount': nodeCount,
        'decoyCount': decoyCount,
        'contentVersion': content.version,
      },
      payload: {
        'nodes': nodes,
        'variant': variant,
        'decoys': decoys,
      },
    );
  }

  /// Picks a position at least [_minNormalizedDistance] from every entry in
  /// [existing], retrying up to [_maxSampleAttempts] times before accepting
  /// whatever the last try landed on, so a crowded board never loops forever
  /// or fails to produce an item (docs/PROGRESSION_PLAN.md §5.3).
  ({double x, double y}) _samplePosition(List<({double x, double y})> existing) {
    var x = 0.0;
    var y = 0.0;
    for (var attempt = 0; attempt < _maxSampleAttempts; attempt++) {
      x = 0.1 + _random.nextDouble() * 0.8;
      y = 0.1 + _random.nextDouble() * 0.8;
      final farEnough = existing.every((p) {
        final dx = p.x - x;
        final dy = p.y - y;
        return sqrt(dx * dx + dy * dy) >= _minNormalizedDistance;
      });
      if (farEnough) return (x: x, y: y);
    }
    return (x: x, y: y);
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
