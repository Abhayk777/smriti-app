import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/games/tutorial/game_tutorial_dialog.dart';
import 'package:smriti/screens/game_screen.dart';
import 'package:smriti/screens/game_tutorial_screen.dart';

void main() {
  group('GameTutorialScreen', () {
    testWidgets('renders header, demo stage, instruction banner, and Let\'s Play button',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameTutorialScreen(gameId: 'sort_harvest'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(InteractiveGameDemoStage), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Let\'s Play!'), findsOneWidget);
    });

    testWidgets('tapping Let\'s Play button transitions to GameScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameTutorialScreen(gameId: 'sort_harvest'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final playButton = find.widgetWithText(ElevatedButton, 'Let\'s Play!');
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('renders Resume Game when isFromGame is true', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameTutorialScreen(gameId: 'lamps_festival', isFromGame: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Resume Game'), findsOneWidget);
    });

    testWidgets('renders My Day routine ordering demo with Put in order banner and cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameTutorialScreen(gameId: 'my_day'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InteractiveGameDemoStage), findsOneWidget);
      expect(find.text('Put in order: Morning to Night'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Morning Tea'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
    });
  });
}
