import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/games/tutorial/game_tutorial_dialog.dart';
import 'package:smriti/screens/game_screen.dart';
import 'package:smriti/screens/game_tutorial_screen.dart';

/// The demonstration plays the real game, which keeps its own timers; unmount
/// it and let them finish so the test ends cleanly.
Future<void> flushDemo(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 40));
}

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
      await flushDemo(tester);
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
      await flushDemo(tester);
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
      await flushDemo(tester);
    });

    testWidgets('renders the My Day demo with its one-line instruction', (tester) async {
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
      expect(find.text('Arrange your daily routine in order of time'), findsOneWidget);
    });
  });
}
