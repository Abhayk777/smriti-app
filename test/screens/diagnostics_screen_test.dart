import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/progression_service.dart';
import 'package:smriti/core/progression/progression_state.dart';
import 'package:smriti/screens/diagnostics_screen.dart';

import '../core/repo/_test_db.dart';

void main() {
  late SmritiDatabase db;
  late DateTime clock;
  late ProgressionService service;

  setUp(() {
    db = newTestDb();
    clock = DateTime(2026, 3, 15, 10, 0);
    service = ProgressionService(db: db, now: () => clock);
    ProgressionService.instance = service;
  });

  tearDown(() async => db.close());

  testWidgets('renders Game levels section in empty state', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to Game levels section
    await tester.scrollUntilVisible(
      find.text('Game levels'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Game levels'), findsOneWidget);

    // Today's play summary
    expect(find.text("Today's Play Time"), findsOneWidget);
    expect(find.text('Rest Card Shown Today'), findsOneWidget);
    expect(find.text('Keep Playing Chosen'), findsOneWidget);

    // By genre table
    expect(find.text('By genre'), findsOneWidget);
    expect(find.text('Executive'), findsOneWidget);
    expect(find.text('Memory'), findsOneWidget);

    // Games list with default/empty state
    await tester.scrollUntilVisible(
      find.text('Market Basket'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Market Basket'), findsOneWidget);
    expect(find.text('Not enough play yet'), findsWidgets);
  });

  testWidgets('renders seeded progress and concern flag', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Seed progress for market_basket with concern
    final progress = GameProgress(
      gameId: 'market_basket',
      level: 6.5,
      seeded: true,
      lastReviewAtMs: clock.millisecondsSinceEpoch,
      history: [
        ReviewRecord(
          atMs: clock.millisecondsSinceEpoch,
          windowFromMs: clock.subtract(const Duration(days: 4)).millisecondsSinceEpoch,
          windowToMs: clock.millisecondsSinceEpoch,
          trials: 24,
          countedPlays: 4,
          distinctDays: 4,
          accuracy: 0.85,
          score: 0.88,
          levelBefore: 6.0,
          levelAfter: 6.5,
          decision: ReviewDecision.raise,
          concern: true,
          plateau: false,
        ),
      ],
    );
    await service.repo.saveGameProgress(progress);
    final check = await service.repo.getGameProgress('market_basket');
    expect(check.level, 6.5);

    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reset_level_market_basket')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Market Basket'), findsOneWidget);
    expect(find.text('6.5'), findsOneWidget);
    expect(find.text('Raised'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
  });

  testWidgets('"Run review now" triggers review against in-memory DB', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Run review now'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final runButton = find.text('Run review now');
    expect(runButton, findsOneWidget);

    await tester.tap(runButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Reviews completed'), findsOneWidget);
  });

  testWidgets('"Reset level" shows confirm dialog and resets level to start value', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Save game at high level 8.0
    final prog = GameProgress(
      gameId: 'market_basket',
      level: 8.0,
      seeded: true,
      lastReviewAtMs: clock.millisecondsSinceEpoch,
    );
    await service.repo.saveGameProgress(prog);

    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reset_level_market_basket')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final resetButton = find.byKey(const ValueKey('reset_level_market_basket'));
    expect(resetButton, findsOneWidget);

    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Reset Level for Market Basket?'), findsOneWidget);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // Read back level from DB: must be starting value (clamped to [1.0, 4.0])
    final updated = await service.repo.getGameProgress('market_basket');
    expect(updated.level, inInclusiveRange(1.0, 4.0));
  });

  testWidgets('number field updates dailyRestMinutes in progression settings', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Run review now'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final field = find.byKey(const ValueKey('daily_rest_minutes_field'));
    expect(field, findsOneWidget);

    await tester.enterText(field, '45');
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const ValueKey('save_daily_rest_minutes'));
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final settings = await service.repo.getSettings();
    expect(settings.dailyRestMinutes, 45);
  });

  testWidgets('Unlock Games Now unlocks locked games in diagnostics', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Lock games
    await service.lockGames(hours: 3);
    expect(await service.isGamesLocked(), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('unlock_games_now_button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Resting'), findsOneWidget);
    expect(find.byKey(const ValueKey('unlock_games_now_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('unlock_games_now_button')));
    await tester.pumpAndSettle();

    expect(await service.isGamesLocked(), isFalse);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('Reset Nudge Cooldown resets nudge cooldown state in diagnostics', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Seed nudge in cooldown
    await service.repo.saveNudgeState(NudgeState(
      lastFavouriteId: 'market_basket',
      lastSuggestedId: 'trace_path',
      lastShownAtMs: clock.millisecondsSinceEpoch,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reset_nudge_cooldown_button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('In 24h Cooldown'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reset_nudge_cooldown_button')));
    await tester.pumpAndSettle();

    final state = await service.repo.getNudgeState();
    expect(state.lastShownAtMs, isNull);
    expect(find.text('Ready to show'), findsOneWidget);
  });
}
