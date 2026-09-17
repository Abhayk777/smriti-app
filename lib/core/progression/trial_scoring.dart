import 'dart:convert';
import 'dart:math' as math;

import '../db/database.dart';

/// Per-game partial-credit scoring for a single [TrialEvent], per
/// docs/PROGRESSION_PLAN.md §6.4.
///
/// `metrics` and `trialContext` are JSON text columns; any decode failure or
/// missing field falls back to the plain `correct` flag, so a malformed or
/// unexpected row never throws into a review.
class TrialScoring {
  const TrialScoring._();

  /// Score in `[0, 1]` for one trial of `gameId`.
  static double score(String gameId, TrialEvent trial) {
    final metrics = _decode(trial.metrics);
    final context = _decode(trial.trialContext);
    final fallback = trial.correct ? 1.0 : 0.0;

    try {
      switch (gameId) {
        case 'market_basket':
          final targets = _asNum(metrics['targets']);
          if (targets == null || targets <= 0) return fallback;
          final missed = _asNum(metrics['missed']) ?? 0;
          final intrusions = _asNum(metrics['intrusions']) ?? 0;
          return _clamp01(1 - (missed + intrusions) / targets);

        case 'faces_of_family':
        case 'sort_harvest':
        case 'weaving_patterns':
          return fallback;

        case 'trace_path':
          final errors = _asNum(metrics['errors']);
          if (errors == null) return fallback;
          if (trial.correct && errors == 0) return 1.0;
          final nodeCount = _asNum(context['nodeCount']);
          if (nodeCount == null || nodeCount <= 0) return fallback;
          return _clamp01(1 - errors / nodeCount);

        case 'my_day':
          final mode = context['mode'] as String?;
          if (mode == 'ordering') {
            final misplaced = _asNum(metrics['misplaced']);
            final eventCount = _asNum(metrics['event_count']);
            if (misplaced == null || eventCount == null || eventCount <= 0) {
              return fallback;
            }
            return _clamp01(1 - misplaced / eventCount);
          }
          return fallback;

        case 'lamps_festival':
          final span = _asNum(context['span']);
          final spanAchieved = _asNum(metrics['span_achieved']);
          if (span == null || span <= 0 || spanAchieved == null) return fallback;
          return _clamp01(spanAchieved / span);

        case 'name_harvest':
          final itemsNamed = _asNum(metrics['items_named']);
          if (itemsNamed == null) return fallback;
          final expectedCount = _asNum(context['expectedCount']) ??
              math.max(3, (5 + trial.itemDifficulty * 2).round()).toDouble();
          if (expectedCount <= 0) return fallback;
          return _clamp01(itemsNamed / expectedCount);

        case 'sounds_home':
          final hits = _asNum(metrics['hits']);
          final misses = _asNum(metrics['misses']);
          if (hits == null || misses == null) return fallback;
          final targets = hits + misses;
          final hitRate = targets > 0 ? hits / targets : 1.0;
          final falseAlarms = _asNum(metrics['false_alarms']) ?? 0;
          final stimuliCount = _asNum(context['stimuliCount']) ?? 0;
          final targetCount = _asNum(context['targetCount']) ?? 0;
          final distractorCount = math.max(1, stimuliCount - targetCount);
          final faRate = falseAlarms / distractorCount;
          return _clamp01(hitRate - 0.5 * faRate);

        default:
          return fallback;
      }
    } catch (_) {
      return fallback;
    }
  }

  static Map<String, Object?> _decode(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  static double? _asNum(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double _clamp01(double v) => v.clamp(0.0, 1.0);
}
