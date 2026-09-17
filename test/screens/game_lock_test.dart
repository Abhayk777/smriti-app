import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/progression_service.dart';
import 'package:smriti/screens/family_screen.dart';
import 'package:smriti/screens/game_select_screen.dart';
import 'package:smriti/screens/home_screen.dart';

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

  group('Game lock on GameSelectScreen', () {
    testWidgets('shows resting banner and disables launching games when locked', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Lock games for 3 hours
      await service.lockGames(hours: 3);
      expect(await service.isGamesLocked(), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: GameSelectScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      // Verify resting banner is shown
      expect(find.textContaining('Games are resting for another'), findsOneWidget);
      expect(find.textContaining('Take a peaceful break!'), findsOneWidget);

      // Tap on Market Basket card
      await tester.tap(find.text('Market Basket'));
      await tester.pump();

      // Verify SnackBar appears instead of navigating
      expect(find.text('Games are taking a restful break right now.'), findsOneWidget);
    });
  });

  group('Game lock on HomeScreen', () {
    testWidgets('shows gentle resting dialog when tapping Play while locked, keeping other features open',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Lock games
      await service.lockGames(hours: 3);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Play tile
      await tester.tap(find.text('Play'));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify gentle dialog appears
      expect(find.text('Games are Resting'), findsOneWidget);
      expect(
        find.text(
          'Games are taking a peaceful break right now. How about checking your family messages or your daily routine?',
        ),
        findsOneWidget,
      );

      // Buttons for My Family and My Day are offered in dialog
      expect(find.widgetWithText(TextButton, 'My Family'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'My Day'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap My Family button in dialog: navigates to FamilyScreen
      await tester.tap(find.widgetWithText(TextButton, 'My Family'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FamilyScreen), findsOneWidget);
    });
  });
}
