import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/progression_config.dart';
import 'package:smriti/core/progression/progression_service.dart';
import 'package:smriti/core/progression/progression_state.dart';
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

    test('restAdvice accounts for inSessionElapsedSeconds', () async {
      await addPlayMinutes(28);
      // Not due without in-session elapsed:
      expect((await service.restAdvice()).show, isFalse);
      // Due when adding 2 minutes of mid-session play (28 + 2 = 30):
      final advice = await service.restAdvice(inSessionElapsedSeconds: 120);
      expect(advice.show, isTrue);
      expect(advice.minutesToday, 30);
    });

    test('games locking and unlocking', () async {
      expect(await service.isGamesLocked(), isFalse);
      await service.lockGames(hours: 3);
      expect(await service.isGamesLocked(), isTrue);

      final advice = await service.restAdvice();
      expect(advice.isLocked, isTrue);
      expect(advice.lockRemaining, isNotNull);

      await service.unlockGames();
      expect(await service.isGamesLocked(), isFalse);
      expect((await service.restAdvice()).isLocked, isFalse);
    });

    test('resetNudgeCooldown clears snooze and shownAt', () async {
      final nowMs = clock.millisecondsSinceEpoch;
      await service.repo.saveNudgeState(NudgeState(
        lastFavouriteId: 'market_basket',
        lastSuggestedId: 'trace_path',
        lastShownAtMs: nowMs,
        dismissStreak: 2,
        snoozedUntilMs: nowMs + 100000,
      ));
      await service.resetNudgeCooldown();
      final fresh = await service.repo.getNudgeState();
      expect(fresh.lastShownAtMs, isNull);
      expect(fresh.snoozedUntilMs, isNull);
      expect(fresh.dismissStreak, 0);
    });

    test('updateDailyRestMinutes syncs nextDueAtSeconds and triggers restAdvice immediately when met', () async {
      // Initially 30m default. Play 2 minutes.
      await addPlayMinutes(2);
      var advice = await service.restAdvice();
      expect(advice.show, isFalse);

      // Caregiver updates rest reminder to 1 minute
      await service.updateDailyRestMinutes(1);

      // Now with 2 minutes played >= 1 minute threshold, restAdvice triggers immediately!
      advice = await service.restAdvice();
      expect(advice.show, isTrue);
      expect(advice.minutesToday, 2);
    });

    test('simulateCountedPlays registers counted sessions and detectFavouriteGame finds it', () async {
      expect(await service.detectFavouriteGame(), isNull);

      await service.simulateCountedPlays('market_basket', count: 6);
      final counted = await service.countedPlaysByGame();
      expect(counted['market_basket'], 6);

      final fav = await service.detectFavouriteGame();
      expect(fav, 'market_basket');
    });
  });

  group('variety suggestion (docs/PROGRESSION_PLAN.md §8)', () {
    Future<void> addSessionsForGame({
      required String gameId,
      required int sessionCount,
      int minutesEach = 3,
      int dayOffset = 0,
    }) async {
      for (var i = 0; i < sessionCount; i++) {
        final sId = _uuid.v4();
        final startedAt = clock
            .subtract(Duration(days: dayOffset, minutes: (i + 1) * (minutesEach + 2)))
            .millisecondsSinceEpoch;
        final endedAt = startedAt + minutesEach * 60 * 1000;
        await db.into(db.sessions).insert(
              SessionsCompanion.insert(
                id: sId,
                startedAt: startedAt,
                gameIds: gameId,
                endedAt: Value(endedAt),
                completed: const Value(true),
              ),
            );
        // insert 1 trial so it's a counted play
        await db.into(db.trialEvents).insert(
              TrialEventsCompanion.insert(
                id: _uuid.v4(),
                sessionId: sId,
                gameId: gameId,
                domain: 'executive',
                itemId: 'item_0',
                itemDifficulty: 0,
                thetaBefore: 0,
                correct: true,
                initiationMs: 400,
                movementMs: 400,
                responseTimeMs: 800,
                trialIndex: 0,
                hintLevel: const Value(0),
                ts: startedAt + 10000,
                hourOfDay: 9,
                tzOffsetMin: 0,
              ),
            );
      }
    }

    test('returns suggestion when favourite has >= 6 plays in 3 days (>= 60% share)', () async {
      // 6 sessions of market_basket over the last 2 days (3 mins each = 18 mins total, rest card not due)
      await addSessionsForGame(gameId: 'market_basket', sessionCount: 6, minutesEach: 2, dayOffset: 1);

      final suggestion = await service.suggestionFor();
      expect(suggestion, isNotNull);
      expect(suggestion!.favouriteGameId, 'market_basket');
      expect(suggestion.suggestedGameId, isNotEmpty);
      expect(suggestion.suggestedGameId, isNot('market_basket'));
    });

    test('rest card wins over variety suggestion when rest card is due (§9.2)', () async {
      // 6 sessions of market_basket of 6 minutes each = 36 minutes played today
      await addSessionsForGame(gameId: 'market_basket', sessionCount: 6, minutesEach: 6, dayOffset: 0);

      // 36 minutes played today: restAdvice().show is true
      final rest = await service.restAdvice();
      expect(rest.show, isTrue);

      // When rest is due, suggestionFor returns null
      final suggestion = await service.suggestionFor();
      expect(suggestion, isNull);
    });

    test('onNudgeShown puts suggestion into 24h cooldown', () async {
      await addSessionsForGame(gameId: 'market_basket', sessionCount: 6, minutesEach: 2, dayOffset: 1);

      final suggestion = (await service.suggestionFor())!;
      await service.onNudgeShown(suggestion);

      // Now within cooldown: null
      expect(await service.suggestionFor(), isNull);

      // Advance clock by 25 hours
      clock = clock.add(const Duration(hours: 25));
      expect(await service.suggestionFor(), isNotNull);
    });

    test('two dismissals snooze suggestion for 2 days', () async {
      await addSessionsForGame(gameId: 'market_basket', sessionCount: 6, minutesEach: 2, dayOffset: 0);

      final suggestion = (await service.suggestionFor())!;
      expect(suggestion, isNotNull);
      // First dismissal: increments streak
      await service.onNudgeDismissed();
      // Second dismissal: snoozes for 2 days
      await service.onNudgeDismissed();

      // State is snoozed
      expect(await service.suggestionFor(), isNull);

      // Advance 48 hours + 1 min: snooze expires, sessions still within 3-day window
      clock = clock.add(const Duration(hours: 48, minutes: 1));
      expect(await service.suggestionFor(), isNotNull);
    });

    test('onNudgeAccepted resets dismiss streak', () async {
      await service.onNudgeDismissed();
      var state = await service.repo.getNudgeState();
      expect(state.dismissStreak, 1);

      await service.onNudgeAccepted('trace_path');
      state = await service.repo.getNudgeState();
      expect(state.dismissStreak, 0);
    });
  });
}
