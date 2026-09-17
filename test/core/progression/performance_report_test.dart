import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/ability/estimator.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/performance_report.dart';

TrialEvent _trial({
  required String id,
  required int ts,
  bool correct = true,
  int hintLevel = 0,
  int responseTimeMs = 1000,
  double itemDifficulty = 0,
  String? trialContext,
  String gameId = 'market_basket',
}) {
  return TrialEvent(
    id: id,
    sessionId: 's_$id',
    gameId: gameId,
    domain: 'memory',
    itemId: 'item_$id',
    itemDifficulty: itemDifficulty,
    thetaBefore: 0,
    correct: correct,
    initiationMs: responseTimeMs ~/ 2,
    movementMs: responseTimeMs - responseTimeMs ~/ 2,
    responseTimeMs: responseTimeMs,
    trialIndex: 0,
    trialContext: trialContext,
    hintLevel: hintLevel,
    metrics: null,
    ts: ts,
    hourOfDay: 9,
    tzOffsetMin: 330,
    synced: false,
  );
}

Session _session({
  required String id,
  int startedAt = 0,
  int? endedAt,
  bool completed = false,
  int? abandonedAtMs,
}) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    gameIds: 'market_basket',
    completed: completed,
    abandonedAtMs: abandonedAtMs,
    demoReplays: 0,
    synced: false,
  );
}

void main() {
  group('GameReport.build with no trials', () {
    test('everything trial-derived is null or zero', () {
      final report = GameReport.build(
        gameId: 'market_basket',
        windowFromMs: 0,
        windowToMs: 1000,
        trials: const [],
        gameSessions: const [],
        trialCountsBySession: const {},
      );
      expect(report.trials, 0);
      expect(report.countedPlays, 0);
      expect(report.distinctDays, 0);
      expect(report.accuracy, isNull);
      expect(report.partialCredit, isNull);
      expect(report.hintRate, 0);
      expect(report.abandonRate, 0);
      expect(report.meanLevel, isNull);
      expect(report.score, isNull);
      expect(report.speedScore, 0.5, reason: 'no previous window to compare');
    });
  });

  test('accuracy, hintRate and partialCredit reflect the trials given', () {
    final trials = [
      _trial(id: 'a', ts: 1000, correct: true, hintLevel: 0),
      _trial(id: 'b', ts: 2000, correct: false, hintLevel: 1),
      _trial(id: 'c', ts: 3000, correct: true, hintLevel: 1),
      _trial(id: 'd', ts: 4000, correct: true, hintLevel: 0),
    ];
    final report = GameReport.build(
      gameId: 'faces_of_family',
      windowFromMs: 0,
      windowToMs: 5000,
      trials: trials,
      gameSessions: const [],
      trialCountsBySession: const {},
    );
    expect(report.trials, 4);
    expect(report.accuracy, closeTo(0.75, 1e-9)); // 3/4 correct
    expect(report.hintRate, closeTo(0.5, 1e-9)); // 2/4 hinted
    // faces_of_family scores plain correct/incorrect, so partialCredit == accuracy here.
    expect(report.partialCredit, closeTo(0.75, 1e-9));
  });

  test('distinctDays counts distinct local calendar dates', () {
    final day1 = DateTime(2026, 1, 1, 9, 0);
    final day2 = DateTime(2026, 1, 2, 9, 0);
    final trials = [
      _trial(id: 'a', ts: day1.millisecondsSinceEpoch),
      _trial(id: 'b', ts: day1.add(const Duration(hours: 2)).millisecondsSinceEpoch),
      _trial(id: 'c', ts: day2.millisecondsSinceEpoch),
    ];
    final report = GameReport.build(
      gameId: 'faces_of_family',
      windowFromMs: 0,
      windowToMs: day2.millisecondsSinceEpoch + 1,
      trials: trials,
      gameSessions: const [],
      trialCountsBySession: const {},
    );
    expect(report.distinctDays, 2);
  });

  test('meanLevel prefers trialContext.progression.level over the difficulty scale', () {
    final withProgression = _trial(
      id: 'a',
      ts: 1000,
      itemDifficulty: 0, // would map to level 5 via the scale
      trialContext: jsonEncode({
        'progression': {'level': 8.0},
      }),
    );
    final withoutProgression = _trial(id: 'b', ts: 2000, itemDifficulty: 0);

    final report = GameReport.build(
      gameId: 'faces_of_family',
      windowFromMs: 0,
      windowToMs: 3000,
      trials: [withProgression, withoutProgression],
      gameSessions: const [],
      trialCountsBySession: const {},
    );
    // (8.0 + 5.0) / 2 = 6.5
    expect(report.meanLevel, closeTo(6.5, 1e-9));
  });

  test('meanLevel falls back to the difficulty scale on malformed trialContext', () {
    final trial = _trial(id: 'a', ts: 1000, itemDifficulty: 0, trialContext: '{not json');
    final report = GameReport.build(
      gameId: 'faces_of_family',
      windowFromMs: 0,
      windowToMs: 2000,
      trials: [trial],
      gameSessions: const [],
      trialCountsBySession: const {},
    );
    expect(report.meanLevel, closeTo(5.0, 1e-9));
  });

  group('countedPlays', () {
    test('a session counts when it lasted at least the minimum, even with no trials', () {
      final session = _session(
        id: 's1',
        startedAt: 0,
        endedAt: 40000, // 40s
        completed: true,
      );
      final report = GameReport.build(
        gameId: 'market_basket',
        windowFromMs: 0,
        windowToMs: 100000,
        trials: const [],
        gameSessions: [session],
        trialCountsBySession: const {},
      );
      expect(report.countedPlays, 1);
    });

    test('a short session still counts if it produced at least one trial', () {
      final session = _session(id: 's1', startedAt: 0, endedAt: 5000, completed: true);
      final report = GameReport.build(
        gameId: 'market_basket',
        windowFromMs: 0,
        windowToMs: 100000,
        trials: const [],
        gameSessions: [session],
        trialCountsBySession: {'s1': 2},
      );
      expect(report.countedPlays, 1);
    });

    test('a short session with no trials does not count', () {
      final session = _session(id: 's1', startedAt: 0, endedAt: 5000, completed: true);
      final report = GameReport.build(
        gameId: 'market_basket',
        windowFromMs: 0,
        windowToMs: 100000,
        trials: const [],
        gameSessions: [session],
        trialCountsBySession: const {},
      );
      expect(report.countedPlays, 0);
    });

    test('an abandoned session uses abandonedAtMs for its duration', () {
      final session = _session(id: 's1', startedAt: 0, abandonedAtMs: 45000);
      final report = GameReport.build(
        gameId: 'market_basket',
        windowFromMs: 0,
        windowToMs: 100000,
        trials: const [],
        gameSessions: [session],
        trialCountsBySession: const {},
      );
      expect(report.countedPlays, 1);
    });
  });

  test('abandonRate is the share of counted plays abandoned within 2 minutes', () {
    final sessions = [
      _session(id: 's1', startedAt: 0, abandonedAtMs: 50000), // counted, abandoned early
      _session(id: 's2', startedAt: 0, endedAt: 40000, completed: true), // counted, completed
      _session(id: 's3', startedAt: 0, abandonedAtMs: 150000), // counted, abandoned but after 2 min
    ];
    final report = GameReport.build(
      gameId: 'market_basket',
      windowFromMs: 0,
      windowToMs: 100000,
      trials: const [],
      gameSessions: sessions,
      trialCountsBySession: const {},
    );
    expect(report.countedPlays, 3);
    expect(report.abandonRate, closeTo(1 / 3, 1e-9));
  });

  group('speedScore', () {
    test('is 0.5 with no previous median', () {
      final trials = [_trial(id: 'a', ts: 1000, responseTimeMs: 1000)];
      final report = GameReport.build(
        gameId: 'faces_of_family',
        windowFromMs: 0,
        windowToMs: 2000,
        trials: trials,
        gameSessions: const [],
        trialCountsBySession: const {},
      );
      expect(report.speedScore, 0.5);
    });

    test('rewards a faster median than before', () {
      final trials = [_trial(id: 'a', ts: 1000, responseTimeMs: 1000)];
      final report = GameReport.build(
        gameId: 'faces_of_family',
        windowFromMs: 0,
        windowToMs: 2000,
        trials: trials,
        gameSessions: const [],
        trialCountsBySession: const {},
        previousMedianResponseTimeMs: 2000,
      );
      // 0.5 + 0.5*(2000-1000)/2000 = 0.75
      expect(report.speedScore, closeTo(0.75, 1e-9));
    });

    test('penalises a slower median than before, clamped at 0', () {
      final trials = [_trial(id: 'a', ts: 1000, responseTimeMs: 10000)];
      final report = GameReport.build(
        gameId: 'faces_of_family',
        windowFromMs: 0,
        windowToMs: 2000,
        trials: trials,
        gameSessions: const [],
        trialCountsBySession: const {},
        previousMedianResponseTimeMs: 1000,
      );
      expect(report.speedScore, 0.0);
    });
  });

  test('score combines partialCredit, hintRate, speedScore and abandonRate', () {
    // All correct, no hints, no previous speed data, no abandoned plays.
    final trials = [
      _trial(id: 'a', ts: 1000, correct: true, hintLevel: 0),
      _trial(id: 'b', ts: 2000, correct: true, hintLevel: 0),
    ];
    final report = GameReport.build(
      gameId: 'faces_of_family',
      windowFromMs: 0,
      windowToMs: 3000,
      trials: trials,
      gameSessions: const [],
      trialCountsBySession: const {},
    );
    // partialCredit=1, hintRate=0, speedScore=0.5, abandonRate=0
    // score = 0.65*1 + 0.15*1 + 0.10*0.5 + 0.10*1 = 0.65+0.15+0.05+0.10 = 0.95
    expect(report.score, closeTo(0.95, 1e-9));
  });

  group('GenreReport', () {
    test('weights the mean score by trial count', () {
      final report = GenreReport.build(CognitiveDomain.memory, const [
        GenreGameSummary(gameId: 'a', trials: 10, score: 0.8),
        GenreGameSummary(gameId: 'b', trials: 30, score: 0.4),
      ]);
      // (10*0.8 + 30*0.4) / 40 = (8+12)/40 = 0.5
      expect(report.totalTrials, 40);
      expect(report.meanScore, closeTo(0.5, 1e-9));
      expect(report.gamesPlayed, 2);
    });

    test('a game with zero trials does not count as played and contributes no score',
        () {
      final report = GenreReport.build(CognitiveDomain.memory, const [
        GenreGameSummary(gameId: 'a', trials: 10, score: 1.0),
        GenreGameSummary(gameId: 'b', trials: 0, score: null),
      ]);
      expect(report.gamesPlayed, 1);
      expect(report.meanScore, closeTo(1.0, 1e-9));
    });

    test('meanScore is null when there are no trials at all', () {
      final report = GenreReport.build(CognitiveDomain.memory, const [
        GenreGameSummary(gameId: 'a', trials: 0, score: null),
      ]);
      expect(report.meanScore, isNull);
      expect(report.totalTrials, 0);
      expect(report.gamesPlayed, 0);
    });

    test('counts games flagged with concern', () {
      final report = GenreReport.build(CognitiveDomain.memory, const [
        GenreGameSummary(gameId: 'a', trials: 5, score: 0.5, concern: true),
        GenreGameSummary(gameId: 'b', trials: 5, score: 0.5, concern: false),
      ]);
      expect(report.gamesWithConcern, 1);
    });
  });
}
