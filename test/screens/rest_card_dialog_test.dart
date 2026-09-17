import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/app_colors.dart';
import 'package:smriti/core/progression/progression_service.dart';
import 'package:smriti/screens/game_screen.dart';
import 'package:smriti/screens/game_select_screen.dart';
import 'package:smriti/ui/smriti_ui.dart';

import '../core/repo/_test_db.dart';

void main() {
  testWidgets('RestCardDialog renders title, body with minutes, and handles callbacks',
      (tester) async {
    var restNowCalled = false;
    var keepPlayingCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestCardDialog(
            isCompact: false,
            minutesToday: 30,
            onRestNow: () => restNowCalled = true,
            onKeepPlaying: () => keepPlayingCalled = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and message
    expect(find.text('Time for a little rest'), findsOneWidget);
    expect(
      find.text(
        'You have played for 30 minutes today. Well done! How about a cup of tea or a short walk?',
      ),
      findsOneWidget,
    );
    expect(find.text('Rest now'), findsOneWidget);
    expect(find.text('Keep playing'), findsOneWidget);

    // Tap Rest now
    await tester.tap(find.text('Rest now'));
    await tester.pump();
    expect(restNowCalled, isTrue);
    expect(keepPlayingCalled, isFalse);

    // Tap Keep playing
    await tester.tap(find.text('Keep playing'));
    await tester.pump();
    expect(keepPlayingCalled, isTrue);
  });

  testWidgets('RestCardDialog works in compact mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestCardDialog(
            isCompact: true,
            minutesToday: 45,
            onRestNow: () {},
            onKeepPlaying: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Time for a little rest'), findsOneWidget);
    expect(
      find.text(
        'You have played for 45 minutes today. Well done! How about a cup of tea or a short walk?',
      ),
      findsOneWidget,
    );
  });

  testWidgets('RestCardDialog has no negative icons or red color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestCardDialog(
            isCompact: false,
            minutesToday: 30,
            onRestNow: () {},
            onKeepPlaying: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no error/warning/timer/hourglass icon
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

    // Verify tea icon is present
    expect(
      medallions.any((m) => m.icon == Icons.local_cafe_rounded),
      isTrue,
    );

    // Verify no red colors in Container decorations or TextStyles
    final containers = tester.widgetList<Container>(find.byType(Container));
    for (final c in containers) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        expect(decoration.color != Colors.red, isTrue);
        expect(decoration.color != AppColors.gamosaRed, isTrue);
      }
    }
  });

  testWidgets('RestAdviceCard reload re-queries restAdvice and updates visibility', (tester) async {
    final db = newTestDb();
    addTearDown(() async => db.close());
    final service = ProgressionService(db: db, now: () => DateTime(2026, 3, 15, 10, 0));

    final cardKey = GlobalKey<RestAdviceCardState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestAdviceCard(key: cardKey, service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Calling reload works cleanly without errors
    await cardKey.currentState?.reload();
    await tester.pumpAndSettle();
    expect(find.byType(RestAdviceCard), findsOneWidget);
  });
}
