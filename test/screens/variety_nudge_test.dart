import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/app_colors.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/progression/progression_service.dart';
import 'package:smriti/screens/game_select_screen.dart';
import 'package:smriti/screens/game_tutorial_screen.dart';
import 'package:smriti/ui/smriti_ui.dart';
import 'package:uuid/uuid.dart';

import '../core/repo/_test_db.dart';

void main() {
  const uuid = Uuid();
  late SmritiDatabase db;
  late DateTime clock;
  late ProgressionService service;

  Future<void> seedFavouriteGame({
    required String gameId,
    int sessionCount = 6,
    int minutesEach = 2,
    int dayOffset = 0,
  }) async {
    for (var i = 0; i < sessionCount; i++) {
      final sId = uuid.v4();
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
      await db.into(db.trialEvents).insert(
            TrialEventsCompanion.insert(
              id: uuid.v4(),
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

  setUp(() {
    db = newTestDb();
    clock = DateTime(2026, 3, 15, 10, 0);
    service = ProgressionService(db: db, now: () => clock);
    ProgressionService.instance = service;
  });

  tearDown(() async => db.close());

  group('VarietySuggestionCard widget', () {
    testWidgets('renders copy exactly as §10 and fires callbacks', (tester) async {
      var tryPressed = false;
      var laterPressed = false;

      const suggestion = VarietySuggestion(
        favouriteGameId: 'market_basket',
        suggestedGameId: 'trace_path',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VarietySuggestionCard(
              suggestion: suggestion,
              onTrySuggested: () => tryPressed = true,
              onMaybeLater: () => laterPressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You really enjoy Market Basket!'), findsOneWidget);
      expect(
        find.text(
          'How about trying Trace the Path today? It is good for the mind to play different games.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try Trace the Path'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);

      await tester.tap(find.text('Try Trace the Path'));
      await tester.pumpAndSettle();
      expect(tryPressed, isTrue);

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(laterPressed, isTrue);
    });

    testWidgets('has no em-dashes, warning/error/timer icons, or red color', (tester) async {
      const suggestion = VarietySuggestion(
        favouriteGameId: 'market_basket',
        suggestedGameId: 'trace_path',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VarietySuggestionCard(
              suggestion: suggestion,
              onTrySuggested: () {},
              onMaybeLater: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check text strings for em dash
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final t in textWidgets) {
        final content = t.data ?? t.textSpan?.toPlainText() ?? '';
        expect(content.contains('\u2014'), isFalse, reason: 'Must not contain em dash');
        expect(content.toLowerCase().contains('wrong'), isFalse);
        expect(content.toLowerCase().contains('failed'), isFalse);
        expect(content.toLowerCase().contains('error'), isFalse);
        expect(content.toLowerCase().contains('limit'), isFalse);
        expect(content.toLowerCase().contains('blocked'), isFalse);
      }

      // Check icons
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      for (final icon in icons) {
        final codePoint = icon.icon?.codePoint;
        expect(codePoint != Icons.error.codePoint, isTrue);
        expect(codePoint != Icons.error_outline.codePoint, isTrue);
        expect(codePoint != Icons.warning.codePoint, isTrue);
        expect(codePoint != Icons.warning_amber.codePoint, isTrue);
        expect(codePoint != Icons.timer.codePoint, isTrue);
        expect(codePoint != Icons.hourglass_empty.codePoint, isTrue);
      }

      // Check medallions
      final medallions = tester.widgetList<IconMedallion>(find.byType(IconMedallion));
      for (final m in medallions) {
        final codePoint = m.icon.codePoint;
        expect(codePoint != Icons.error.codePoint, isTrue);
        expect(codePoint != Icons.warning.codePoint, isTrue);
        expect(codePoint != Icons.timer.codePoint, isTrue);
        expect(codePoint != Icons.hourglass_empty.codePoint, isTrue);
      }

      // Check container colors
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final c in containers) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          expect(decoration.color != Colors.red, isTrue);
          expect(decoration.color != AppColors.gamosaRed, isTrue);
        }
      }
    });
  });

  group('GameSelectScreen with variety nudge', () {
    testWidgets('shows suggestion card and "Try today" ribbon on tablet', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await seedFavouriteGame(gameId: 'market_basket', sessionCount: 6);

      await tester.pumpWidget(
        MaterialApp(
          home: GameSelectScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      // Suggestion card is visible
      expect(find.text('You really enjoy Market Basket!'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);

      // Ribbon is visible on the suggested game
      expect(find.text('Try today'), findsOneWidget);

      // "Maybe later" removes the card
      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();

      expect(find.text('You really enjoy Market Basket!'), findsNothing);
    });

    testWidgets('tapping "Try {suggested}" launches GameScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await seedFavouriteGame(gameId: 'market_basket', sessionCount: 6);

      await tester.pumpWidget(
        MaterialApp(
          home: GameSelectScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      final tryButton = find.widgetWithText(ElevatedButton, 'Try Trace the Path');
      if (tryButton.evaluate().isNotEmpty) {
        await tester.tap(tryButton);
      } else {
        // Find whatever game is suggested
        final anyTryButton = find.byWidgetPredicate(
          (w) => w is ElevatedButton && w.child is Text && (w.child as Text).data!.startsWith('Try '),
        );
        expect(anyTryButton, findsOneWidget);
        await tester.tap(anyTryButton);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GameTutorialScreen), findsOneWidget);
    });

    testWidgets('rest card wins over variety suggestion when both are due', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 6 sessions of 6 minutes = 36 minutes played today -> rest card is due!
      await seedFavouriteGame(gameId: 'market_basket', sessionCount: 6, minutesEach: 6, dayOffset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: GameSelectScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      // Rest card is shown
      expect(find.text('Time for a little rest'), findsOneWidget);
      // Variety suggestion card is NOT shown
      expect(find.text('You really enjoy Market Basket!'), findsNothing);
    });

    testWidgets('shows suggestion card and ribbon on phone without overflow', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await seedFavouriteGame(gameId: 'market_basket', sessionCount: 6);

      await tester.pumpWidget(
        MaterialApp(
          home: GameSelectScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You really enjoy Market Basket!'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Try today'), 100);
      expect(find.text('Try today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
