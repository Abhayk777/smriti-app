import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/i18n/app_strings.dart';
import 'package:smriti/core/i18n/locale_controller.dart';
import 'package:smriti/screens/my_day_screen.dart';

import '../core/repo/_test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SmritiDatabase db;

  setUp(() async {
    db = newTestDb();
    appDatabase = db;

    // Seed routine items entered in English by the caregiver on the web app
    await db.into(db.routineItems).insert(
          RoutineItemsCompanion.insert(
            id: 'routine_1',
            labelKey: 'Morning Walk in Garden',
            timeMin: 420, // 7:00 AM
            iconAsset: '🌅',
          ),
        );
    await db.into(db.routineItems).insert(
          RoutineItemsCompanion.insert(
            id: 'routine_2',
            labelKey: 'Breakfast with Family',
            timeMin: 510, // 8:30 AM
            iconAsset: '🥣',
          ),
        );
  });

  tearDown(() async {
    await LocaleController.instance.setLanguage('en');
    await db.close();
  });

  testWidgets('MyDayScreen translates English routine activities to Bengali',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await LocaleController.instance.setLanguage('bn');

    await tester.pumpWidget(
      const MaterialApp(
        home: MyDayScreen(syncInBackground: false),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Screen title should be Bengali "My Day"
    expect(find.text(AppStrings.myDay('bn')), findsOneWidget);

    // English "Morning Walk in Garden" should be mapped to Bengali "সকালের হাঁটা"
    expect(find.text('সকালের হাঁটা'), findsOneWidget);

    // English "Breakfast with Family" should be mapped to Bengali "সকালের প্রাতঃরাশ"
    expect(find.text('সকালের প্রাতঃরাশ'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('MyDayScreen translates English routine activities to Assamese',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await LocaleController.instance.setLanguage('as');

    await tester.pumpWidget(
      const MaterialApp(
        home: MyDayScreen(syncInBackground: false),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.myDay('as')), findsOneWidget);
    expect(find.text('খোজকাঢ়া'), findsOneWidget);
    expect(find.text('ৰাতিপুৱাৰ জলপান'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
