import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/i18n/app_strings.dart';
import 'package:smriti/core/i18n/locale_controller.dart';
import 'package:smriti/screens/full_screen_reminder_screen.dart';

import '../core/repo/_test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SmritiDatabase db;

  setUp(() async {
    db = newTestDb();
    appDatabase = db;

    await db.into(db.medications).insert(
          MedicationsCompanion.insert(
            id: 'med_test_amlodipine',
            name: 'Amlodipine',
            dose: '5mg in the morning',
            chosenTimeMin: 480,
            daysOfWeek: '1,2,3,4,5,6,7',
            windowStartMin: 420,
            windowEndMin: 540,
          ),
        );

    await db.into(db.reminderEvents).insert(
          ReminderEventsCompanion.insert(
            id: 'event_test_amlodipine',
            medicationId: 'med_test_amlodipine',
            scheduledAt: 1700000000000,
            channel: 'in_app',
            ladderStep: 0,
          ),
        );
  });

  tearDown(() async {
    await LocaleController.instance.setLanguage('en');
    await db.close();
  });

  testWidgets('FullScreenReminderScreen renders localized strings while keeping medicine name in English',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Switch to Assamese
    await LocaleController.instance.setLanguage('as');

    await tester.pumpWidget(
      const MaterialApp(
        home: FullScreenReminderScreen(
          medicationId: 'med_test_amlodipine',
          reminderEventId: 'event_test_amlodipine',
          syncAfterResponse: false,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Medicine name MUST remain in English
    expect(find.text('Amlodipine'), findsOneWidget);

    // Title is localized to Assamese
    expect(find.text(AppStrings.timeForYourMedicine('as')), findsOneWidget);

    // Action buttons are localized to Assamese
    expect(find.text(AppStrings.iHaveTakenIt('as')), findsOneWidget);
    expect(find.text(AppStrings.remindIn10Mins('as')), findsOneWidget);

    // Dose is localized
    expect(find.text(AppStrings.doseLabel('as', '5mg in the morning')), findsOneWidget);

    // Tap "I Have Taken It"
    await tester.tap(find.text(AppStrings.iHaveTakenIt('as')));
    await tester.pump();

    for (var i = 0; i < 10 && find.text(AppStrings.medicineRecordedWellDone('as')).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text(AppStrings.medicineRecordedWellDone('as')), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Switching language to Hindi updates full-screen reminder dynamically',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await LocaleController.instance.setLanguage('hi');

    await tester.pumpWidget(
      const MaterialApp(
        home: FullScreenReminderScreen(
          medicationId: 'med_test_amlodipine',
          reminderEventId: 'event_test_amlodipine',
          syncAfterResponse: false,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Medicine name MUST remain in English
    expect(find.text('Amlodipine'), findsOneWidget);
    expect(find.text(AppStrings.timeForYourMedicine('hi')), findsOneWidget);
    expect(find.text(AppStrings.iHaveTakenIt('hi')), findsOneWidget);
  });
}
