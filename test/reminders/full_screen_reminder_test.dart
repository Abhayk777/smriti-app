import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/reminders/native_reminder_bridge.dart';
import 'package:smriti/screens/full_screen_reminder_screen.dart';

import '../core/repo/_test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SmritiDatabase db;

  setUp(() async {
    db = newTestDb();
    appDatabase = db;

    // Seed medication and reminder event
    await db.into(db.medications).insert(
          MedicationsCompanion.insert(
            id: 'med_test_1',
            name: 'Donepezil',
            dose: '5mg at night',
            chosenTimeMin: 1200,
            daysOfWeek: '1,2,3,4,5,6,7',
            windowStartMin: 1140,
            windowEndMin: 1260,
          ),
        );

    await db.into(db.reminderEvents).insert(
          ReminderEventsCompanion.insert(
            id: 'event_test_1',
            medicationId: 'med_test_1',
            scheduledAt: 1700000000000,
            channel: 'fullscreen',
            ladderStep: 0,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('NativeReminderBridge returns default booleans without crash', () async {
    expect(await NativeReminderBridge.canUseFullScreenIntent(), isTrue);
    expect(await NativeReminderBridge.canScheduleExactAlarms(), isTrue);
  });

  testWidgets('FullScreenReminderScreen renders medicine name, dose, and action buttons',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FullScreenReminderScreen(
          medicationId: 'med_test_1',
          reminderEventId: 'event_test_1',
        ),
      ),
    );

    await tester.pump(); // Start load
    await tester.pump(const Duration(milliseconds: 100)); // Complete load

    // Verify UI components
    expect(find.text('Time for Your Medicine'), findsOneWidget);
    expect(find.text('Donepezil'), findsOneWidget);
    expect(find.text('Dose: 5mg at night'), findsOneWidget);
    expect(find.text('I Have Taken It'), findsOneWidget);
    expect(find.text('Remind in 10 Mins'), findsOneWidget);

    // Tap "I Have Taken It"
    await tester.tap(find.text('I Have Taken It'));
    await tester.pump();

    // Check DB was updated with confirmed outcome
    final updatedEvent = await (db.select(db.reminderEvents)
          ..where((t) => t.id.equals('event_test_1')))
        .getSingle();

    expect(updatedEvent.outcome, 'confirmed');
    expect(updatedEvent.respondedAt, isNotNull);
  });
}
