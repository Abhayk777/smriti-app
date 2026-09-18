import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/i18n/app_strings.dart';
import 'package:smriti/core/i18n/locale_controller.dart';
import 'package:smriti/screens/medicine_screen.dart';

import '../core/repo/_test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SmritiDatabase db;

  setUp(() async {
    db = newTestDb();
    appDatabase = db;

    await db.into(db.medications).insert(
          MedicationsCompanion.insert(
            id: 'med_test_metformin',
            name: 'Metformin 500mg',
            dose: '1 tablet after meals',
            chosenTimeMin: 540,
            daysOfWeek: '1,2,3,4,5,6,7',
            windowStartMin: 480,
            windowEndMin: 600,
          ),
        );
  });

  tearDown(() async {
    await LocaleController.instance.setLanguage('en');
    await db.close();
  });

  testWidgets('MedicineScreen preserves English med name and translates UI labels to Assamese',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await LocaleController.instance.setLanguage('as');

    await tester.pumpWidget(
      const MaterialApp(
        home: MedicineScreen(syncInBackground: false),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Medicine name strictly in English
    expect(find.text('Metformin 500mg'), findsOneWidget);

    // Header title and subtitle in Assamese
    expect(find.text(AppStrings.myMedicines('as')), findsOneWidget);
    expect(find.text(AppStrings.tapTakeOnceHad('as')), findsOneWidget);

    // Action button labels in Assamese
    expect(find.text(AppStrings.take('as')), findsOneWidget);
    expect(find.text(AppStrings.hearInstruction('as')), findsOneWidget);

    // Tap "Take"
    await tester.tap(find.text(AppStrings.take('as')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Button flips to "Taken" in Assamese
    expect(find.text(AppStrings.taken('as')), findsOneWidget);

    // Second tap shows SnackBar with English med name interpolated into Assamese prompt
    await tester.tap(find.text(AppStrings.taken('as')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(AppStrings.alreadyMarkedTaken('as', 'Metformin 500mg')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
