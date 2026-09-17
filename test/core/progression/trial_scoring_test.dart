import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/trial_scoring.dart';

TrialEvent _trial({
  bool correct = false,
  double itemDifficulty = 0,
  String? metrics,
  String? trialContext,
}) {
  return TrialEvent(
    id: 't1',
    sessionId: 's1',
    gameId: 'x',
    domain: 'memory',
    itemId: 'i1',
    itemDifficulty: itemDifficulty,
    thetaBefore: 0,
    correct: correct,
    initiationMs: 500,
    movementMs: 500,
    responseTimeMs: 1000,
    trialIndex: 0,
    trialContext: trialContext,
    hintLevel: 0,
    metrics: metrics,
    ts: 0,
    hourOfDay: 0,
    tzOffsetMin: 0,
    synced: false,
  );
}

void main() {
  group('market_basket', () {
    test('uses missed and intrusions against targets', () {
      final t = _trial(
        metrics: jsonEncode({'targets': 4, 'missed': 1, 'intrusions': 1}),
      );
      expect(TrialScoring.score('market_basket', t), closeTo(0.5, 1e-9));
    });

    test('falls back to correct when targets is missing', () {
      final t = _trial(correct: true, metrics: jsonEncode({'picked': 2}));
      expect(TrialScoring.score('market_basket', t), 1.0);
    });
  });

  group('single correct/incorrect games', () {
    for (final gameId in ['faces_of_family', 'sort_harvest', 'weaving_patterns']) {
      test('$gameId scores 1 when correct, 0 when not', () {
        expect(TrialScoring.score(gameId, _trial(correct: true)), 1.0);
        expect(TrialScoring.score(gameId, _trial(correct: false)), 0.0);
      });
    }
  });

  group('trace_path', () {
    test('perfect completion with no errors scores 1', () {
      final t = _trial(
        correct: true,
        metrics: jsonEncode({'errors': 0}),
        trialContext: jsonEncode({'nodeCount': 10}),
      );
      expect(TrialScoring.score('trace_path', t), 1.0);
    });

    test('partial credit for some errors against node count', () {
      final t = _trial(
        correct: false,
        metrics: jsonEncode({'errors': 2}),
        trialContext: jsonEncode({'nodeCount': 10}),
      );
      expect(TrialScoring.score('trace_path', t), closeTo(0.8, 1e-9));
    });

    test('falls back to correct when nodeCount is missing', () {
      final t = _trial(correct: true, metrics: jsonEncode({'errors': 3}));
      expect(TrialScoring.score('trace_path', t), 1.0);
    });
  });

  group('my_day', () {
    test('ordering mode uses misplaced against event_count', () {
      final t = _trial(
        trialContext: jsonEncode({'mode': 'ordering'}),
        metrics: jsonEncode({'misplaced': 1, 'event_count': 4}),
      );
      expect(TrialScoring.score('my_day', t), closeTo(0.75, 1e-9));
    });

    test('orientation mode falls back to correct', () {
      final t = _trial(
        correct: true,
        trialContext: jsonEncode({'mode': 'orientation'}),
      );
      expect(TrialScoring.score('my_day', t), 1.0);
    });
  });

  group('lamps_festival', () {
    test('uses span_achieved against span', () {
      final t = _trial(
        trialContext: jsonEncode({'span': 5}),
        metrics: jsonEncode({'span_achieved': 3}),
      );
      expect(TrialScoring.score('lamps_festival', t), closeTo(0.6, 1e-9));
    });

    test('falls back to correct when span is 0', () {
      final t = _trial(
        correct: true,
        trialContext: jsonEncode({'span': 0}),
        metrics: jsonEncode({'span_achieved': 0}),
      );
      expect(TrialScoring.score('lamps_festival', t), 1.0);
    });
  });

  group('name_harvest', () {
    test('uses items_named against expectedCount from context', () {
      final t = _trial(
        trialContext: jsonEncode({'expectedCount': 8}),
        metrics: jsonEncode({'items_named': 4}),
      );
      expect(TrialScoring.score('name_harvest', t), closeTo(0.5, 1e-9));
    });

    test('falls back to the old difficulty formula when expectedCount is absent', () {
      // max(3, (5 + 0*2).round()) == 5
      final t = _trial(
        itemDifficulty: 0,
        metrics: jsonEncode({'items_named': 5}),
      );
      expect(TrialScoring.score('name_harvest', t), closeTo(1.0, 1e-9));
    });

    test('clamps above 1', () {
      final t = _trial(
        trialContext: jsonEncode({'expectedCount': 3}),
        metrics: jsonEncode({'items_named': 10}),
      );
      expect(TrialScoring.score('name_harvest', t), 1.0);
    });
  });

  group('sounds_home', () {
    test('combines hit rate and false alarm rate', () {
      final t = _trial(
        metrics: jsonEncode({'hits': 8, 'misses': 2, 'false_alarms': 2}),
        trialContext: jsonEncode({'stimuliCount': 20, 'targetCount': 10}),
      );
      // hitRate = 0.8, faRate = 2/10 = 0.2 -> 0.8 - 0.1 = 0.7
      expect(TrialScoring.score('sounds_home', t), closeTo(0.7, 1e-9));
    });

    test('falls back to correct when hits/misses are missing', () {
      final t = _trial(correct: false, metrics: jsonEncode({'rt_sd': 100}));
      expect(TrialScoring.score('sounds_home', t), 0.0);
    });
  });

  group('malformed data', () {
    test('invalid JSON in metrics falls back to correct', () {
      final t = _trial(correct: true, metrics: '{not json');
      expect(TrialScoring.score('market_basket', t), 1.0);
      expect(TrialScoring.score('trace_path', t), 1.0);
      expect(TrialScoring.score('sounds_home', t), 1.0);
    });

    test('null metrics and context fall back to correct', () {
      expect(TrialScoring.score('market_basket', _trial(correct: false)), 0.0);
      expect(TrialScoring.score('name_harvest', _trial(correct: true)), 1.0);
    });

    test('unknown game id falls back to correct', () {
      expect(TrialScoring.score('not_a_real_game', _trial(correct: true)), 1.0);
    });
  });
}
