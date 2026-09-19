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
              id: uuid.v4(),
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

  setUp(() {
    db = newTestDb();
    clock = DateTime(2026, 1, 1, 10, 0);
    nextEndOffsetMin = 1;
    service = ProgressionService(db: db, now: () => clock);
    ProgressionService.instance = service;
  });

  tearDown(() async => db.close());

  testWidgets('does not render when play time is below threshold', (tester) async {
    await addPlayMinutes(20);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestAdviceCard(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Time for a little rest'), findsNothing);
  });

  testWidgets('renders card when play time reaches 30 minutes', (tester) async {
    await addPlayMinutes(30);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestAdviceCard(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Time for a little rest'), findsOneWidget);
    expect(
      find.text(
        'You have played for 30 minutes today. Well done! How about a cup of tea or a short walk?',
      ),
      findsOneWidget,
    );
    expect(find.text('Rest now'), findsOneWidget);
    expect(find.text('Keep playing'), findsOneWidget);
  });

  testWidgets('"Keep playing" hides the card and marks answered', (tester) async {
    await addPlayMinutes(30);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestAdviceCard(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Time for a little rest'), findsOneWidget);

    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();

    expect(find.text('Time for a little rest'), findsNothing);
    final advice = await service.restAdvice();
    expect(advice.show, isFalse);
  });

  testWidgets('"Rest now" marks answered and pops to first route', (tester) async {
    await addPlayMinutes(30);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pushNamed('/second'),
                  child: const Text('Go to second'),
                ),
              ),
          '/second': (ctx) => Scaffold(
                body: RestAdviceCard(service: service),
              ),
        },
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to second route
    await tester.tap(find.text('Go to second'));
    await tester.pumpAndSettle();

    expect(find.text('Time for a little rest'), findsOneWidget);

    // Tap Rest now -> should pop back to first route
    await tester.tap(find.text('Rest now'));
    await tester.pumpAndSettle();

    expect(find.text('Go to second'), findsOneWidget);
    expect(find.text('Time for a little rest'), findsNothing);

    final advice = await service.restAdvice();
    expect(advice.show, isFalse);
  });

  testWidgets('RestAdviceCard has no negative icons or red color', (tester) async {
    await addPlayMinutes(30);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestAdviceCard(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

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

    final medallions = tester.widgetList<IconMedallion>(find.byType(IconMedallion));
    for (final m in medallions) {
      final codePoint = m.icon.codePoint;
      expect(codePoint != Icons.error.codePoint, isTrue);
      expect(codePoint != Icons.warning.codePoint, isTrue);
      expect(codePoint != Icons.timer.codePoint, isTrue);
      expect(codePoint != Icons.hourglass_empty.codePoint, isTrue);
    }

    expect(
      medallions.any((m) => m.icon == Icons.local_cafe_rounded),
      isTrue,
    );

    final containers = tester.widgetList<Container>(find.byType(Container));
    for (final c in containers) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        expect(decoration.color != Colors.red, isTrue);
        expect(decoration.color != AppColors.gamosaRed, isTrue);
      }
    }
  });

  testWidgets('No game is ever blocked: with 120 minutes played, games still launch',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await addPlayMinutes(120);

    await tester.pumpWidget(
      MaterialApp(
        home: GameSelectScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    // Rest card is present
    expect(find.text('Time for a little rest'), findsOneWidget);

    // Tapping Market Basket game tile pushes GameTutorialScreen before GameScreen
    final marketBasketTile = find.text('Market Basket');
    expect(marketBasketTile, findsOneWidget);

    await tester.tap(marketBasketTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GameTutorialScreen), findsOneWidget);
  });
}
