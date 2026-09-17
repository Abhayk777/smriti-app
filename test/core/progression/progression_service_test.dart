import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/progression_config.dart';
import 'package:smriti/core/progression/progression_service.dart';
import 'package:uuid/uuid.dart';

import '../repo/_test_db.dart';

const _uuid = Uuid();

void main() {
  late SmritiDatabase db;
  late DateTime clock;
  late ProgressionService service;

  DateTime now() => clock;

  setUp(() {
    db = newTestDb();
    clock = DateTime(2026, 1, 1, 9, 0);
    service = ProgressionService(db: db, now: now);
  });

  tearDown(() async => db.close());

  /// Inserts a session and [correctCount] correct plus [incorrectCount]
  /// incorrect trials for `faces_of_family`, spread across [days] distinct
  /// local calendar days ending at [clock], with no hints, no abandonment
  /// and no `trialContext`/`metrics` (faces_of_family scores purely on
  /// `correct`, so nothing else is needed to control the score).
  Future<void> playFaces({
    required int correctCount,
    required int incorrectCount,
    int days = 2,
  }) async {
    final sessionId = _uuid.v4();
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: sessionId,
            startedAt: clock.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
            gameIds: 'faces_of_family',
            endedAt: Value(clock.millisecondsSinceEpoch),
            completed: const Value(true),
          ),
        );

    final total = correctCount + incorrectCount;
    final flags = [
      for (var i = 0; i < correctCount; i++) true,
      for (var i = 0; i < incorrectCount; i++) false,
    ];
    for (var i = 0; i < total; i++) {
      final dayOffset = i % days;
      final ts = clock.subtract(Duration(days: dayOffset, minutes: 1)).millisecondsSinceEpoch;
      await db.into(db.trialEvents).insert(
            TrialEventsCompanion.insert(
              id: _uuid.v4(),
              sessionId: sessionId,
              gameId: 'faces_of_family',
              domain: 'memory',
              itemId: 'item_$i',
              itemDifficulty: 0,
              thetaBefore: 0,
              correct: flags[i],
              initiationMs: 400,
              movementMs: 400,
              responseTimeMs: 800,
              trialIndex: i,
              hintLevel: const Value(0),
              ts: ts,
              hourOfDay: 9,
              tzOffsetMin: 0,
            ),
          );
    }
  }

  test('a game played for the first time is seeded within [1, 4]', () async {
    final level = await service.onSessionStarted('faces_of_family');
    expect(level, inInclusiveRange(1.0, 4.0));
    expect(service.levelFor('faces_of_family'), level);

    final progress = (await service.allProgress())['faces_of_family']!;
    expect(progress.seeded, isTrue);
    expect(progress.lastReviewAtMs, clock.millisecondsSinceEpoch);
  });

  test('4 days of consistently correct play raises the level', () async {
    final startLevel = await service.onSessionStarted('faces_of_family');
    await service.onSessionEnded('faces_of_family');

    // 4 days later, with plenty of correct trials spread over 2 days inside
    // the review window.
    clock = clock.add(const Duration(days: 4));
    await playFaces(correctCount: 10, incorrectCount: 0, days: 2);

    await service.runDueReviews();

    final progress = (await service.allProgress())['faces_of_family']!;
    expect(progress.history, hasLength(1));
    expect(progress.history.single.decision.name, 'raise');
    expect(service.levelFor('faces_of_family'), greaterThan(startLevel));
  });

  test('4 days of consistently incorrect play eases the level', () async {
    final startLevel = await service.onSessionStarted('faces_of_family');
    await service.onSessionEnded('faces_of_family');

    clock = clock.add(const Duration(days: 4));
    await playFaces(correctCount: 0, incorrectCount: 10, days: 2);

    await service.runDueReviews();

    final progress = (await service.allProgress())['faces_of_family']!;
    expect(progress.history, hasLength(1));
    expect(progress.history.single.decision.name, 'easeMore');
    expect(service.levelFor('faces_of_family'), lessThan(startLevel));
  });

  test('leaving the level unchanged when there is not enough play', () async {
    await service.onSessionStarted('faces_of_family');
    await service.onSessionEnded('faces_of_family');

    clock = clock.add(const Duration(days: 4));
    // Too few trials (< minTrialsPerReview) to score a real review.
    await playFaces(correctCount: 2, incorrectCount: 0, days: 2);

    await service.runDueReviews();

    final progress = (await service.allProgress())['faces_of_family']!;
    expect(progress.history, hasLength(1));
    expect(progress.history.single.decision.name, 'notEnoughData');
  });

  test('a device left off for 20 days eases once when play resumes', () async {
    final startLevel = await service.onSessionStarted('faces_of_family');
    await service.onSessionEnded('faces_of_family'); // lastPlayedAtMs = clock

    clock = clock.add(const Duration(days: 20));
    final resumedLevel = await service.onSessionStarted('faces_of_family');

    expect(resumedLevel, closeTo(startLevel - ProgressionConfig.returningStep, 1e-9));

    // Finishing that session and starting straight into another must not
    // ease a second time: lastPlayedAtMs is now fresh.
    await service.onSessionEnded('faces_of_family');
    final secondLevel = await service.onSessionStarted('faces_of_family');
    expect(secondLevel, closeTo(resumedLevel, 1e-9));
  });

  test('concurrent runDueReviews calls share one run', () async {
    await service.onSessionStarted('faces_of_family');
    await service.onSessionEnded('faces_of_family');

    clock = clock.add(const Duration(days: 4));
    await playFaces(correctCount: 10, incorrectCount: 0, days: 2);

    final first = service.runDueReviews();
    final second = service.runDueReviews();
    expect(identical(first, second), isTrue,
        reason: 'the second call should return the same in-flight future');

    await Future.wait([first, second]);

    // The review ran exactly once, not twice.
    final progress = (await service.allProgress())['faces_of_family']!;
    expect(progress.history, hasLength(1));
  });

  test('runDueReviews skips a game that has never been played', () async {
    await service.runDueReviews();
    final progress = (await service.allProgress())['sort_harvest']!;
    expect(progress.history, isEmpty);
    expect(progress.lastReviewAtMs, isNull);
  });

  test('a review failure for one game does not stop the others', () async {
    // Seed two games in the same window; corrupt one game's stored progress
    // JSON directly so loading it throws, and confirm the other still
    // reviews normally.
    await service.onSessionStarted('faces_of_family');
    await service.onSessionEnded('faces_of_family');
    await service.onSessionStarted('sort_harvest');
    await service.onSessionEnded('sort_harvest');

    clock = clock.add(const Duration(days: 4));
    await playFaces(correctCount: 10, incorrectCount: 0, days: 2);

    // A fresh service instance with no in-memory cache, so it must reload
    // sort_harvest's (corrupted) progress from disk.
    await db.appConfigsDao.setValue('progression.v1.game.sort_harvest', '{not json');
    final freshService = ProgressionService(db: db, now: now);

    await freshService.runDueReviews();

    final facesProgress = (await freshService.allProgress())['faces_of_family']!;
    expect(facesProgress.history, hasLength(1));
    expect(facesProgress.history.single.decision.name, 'raise');
  });

  group('restAdvice / onRestCardAnswered (docs/PROGRESSION_PLAN.md §9)', () {
    // Real sessions are capped at 6 minutes by SessionRunner, so
    // playSecondsToday caps each session's contribution at 8 minutes
    // (docs/PROGRESSION_PLAN.md §9.1). A single 20+ minute session can never
    // occur in production, so play time here is spread across several
    // sessions of at most 8 minutes each, exactly like real usage, ending
    // further and further before "now" so they never overlap.
    var nextEndOffsetMin = 1;

    Future<void> addPlayMinutes(int totalMinutes) async {
      var remaining = totalMinutes;
      while (remaining > 0) {
        final chunk = remaining > 8 ? 8 : remaining;
        final startedAt = clock
            .subtract(Duration(minutes: nextEndOffsetMin + chunk))
            .millisecondsSinceEpoch;
        final endedAt =
            clock.subtract(Duration(minutes: nextEndOffsetMin)).millisecondsSinceEpoch;
        await db.into(db.sessions).insert(
              SessionsCompanion.insert(
                id: _uuid.v4(),
                startedAt: startedAt,
                gameIds: 'market_basket',
                endedAt: Value(endedAt),
                completed: const Value(true),
              ),
            );
        remaining -= chunk;
        nextEndOffsetMin += chunk;
      }
    }

    test('not due below the threshold', () async {
      await addPlayMinutes(20); // 20 minutes played today, across sessions
      final advice = await service.restAdvice();
      expect(advice.show, isFalse);
      expect(advice.minutesToday, 20);
    });

    test('due once today\'s play reaches the threshold', () async {
      await addPlayMinutes(30); // exactly 30 minutes played today
      final advice = await service.restAdvice();
      expect(advice.show, isTrue);
      expect(advice.minutesToday, 30);
    });

    test('never due when dailyRestMinutes is turned off', () async {
      await db.appConfigsDao.setValue(
        'progression.v1.settings',
        '{"dailyRestMinutes": 0}',
      );
      await addPlayMinutes(60); // an hour played today
      final advice = await service.restAdvice();
      expect(advice.show, isFalse);
    });

    test('"Keep playing" pushes the next reminder to 15 more minutes of play', () async {
      await addPlayMinutes(30);
      expect((await service.restAdvice()).show, isTrue);

      await service.onRestCardAnswered(keepPlaying: true);
      // Still at 30 minutes: not due again immediately.
      expect((await service.restAdvice()).show, isFalse);

      await addPlayMinutes(15); // 15 more minutes played
      expect((await service.restAdvice()).show, isTrue);
    });

    test('a new day resets the reminder', () async {
      await addPlayMinutes(30);
      expect((await service.restAdvice()).show, isTrue);
      await service.onRestCardAnswered(keepPlaying: false);

      clock = DateTime(clock.year, clock.month, clock.day + 1, 9, 0);
      final advice = await service.restAdvice();
      expect(advice.show, isFalse);
      expect(advice.minutesToday, 0);
    });
  });
}
