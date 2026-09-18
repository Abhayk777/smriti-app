import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/i18n/app_strings.dart';
import 'package:smriti/core/i18n/locale_controller.dart';
import 'package:smriti/widgets/language_switcher_button.dart';

import '../core/repo/_test_db.dart';

void main() {
  late SmritiDatabase db;
  late LocaleController controller;

  setUp(() {
    db = newTestDb();
    controller = LocaleController(db: db, defaultLanguage: 'as');
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: LanguageSwitcherButton(controller: controller),
        ),
      ),
    );
  }

  group('LanguageSwitcherButton & Picker', () {
    testWidgets('displays active language in native script', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Default is Assamese
      expect(find.text('অসমীয়া'), findsOneWidget);
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    });

    testWidgets('opens language picker modal and shows languages', (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap button to open picker
      await tester.tap(find.byType(LanguageSwitcherButton));
      await tester.pumpAndSettle();

      // Bottom sheet header
      expect(find.text(AppStrings.chooseLanguage('as')), findsOneWidget);
      expect(find.text('North-East India Languages'), findsOneWidget);

      // Verify native names for languages are visible
      expect(find.text('অসমীয়া'), findsWidgets);
      expect(find.text('বাংলা'), findsOneWidget);
      expect(find.text("बर'"), findsOneWidget);
      expect(find.text('A·chik'), findsOneWidget);
      expect(find.text('Khasi'), findsOneWidget);
      expect(find.text('Mizo'), findsOneWidget);
    });

    testWidgets('selecting a language updates controller and button label', (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap button
      await tester.tap(find.byType(LanguageSwitcherButton));
      await tester.pumpAndSettle();

      // Tap Mizo
      await tester.tap(find.text('Mizo'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed and button should now display 'Mizo'
      expect(controller.currentLanguage, equals('lus'));
      expect(find.text('Mizo'), findsOneWidget);
      expect(find.text('North-East India Languages'), findsNothing);

      // Check SQLite persistence
      final saved = await db.appConfigsDao.getValue('langCode');
      expect(saved, equals('lus'));
    });

    testWidgets('switching to Garo (A·chik) works seamlessly', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LanguageSwitcherButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A·chik'));
      await tester.pumpAndSettle();

      expect(controller.currentLanguage, equals('grt'));
      expect(find.text('A·chik'), findsOneWidget);
    });
  });
}
