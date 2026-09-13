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
          syncAfterResponse: false,
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

    // Confirmation shows once the response is written (and the ladder-cancel
    // and notification-dismiss platform calls settle).
    // Drift's real I/O only completes when real time passes (runAsync).
    for (var i = 0; i < 10 && find.text('Thank you!').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Thank you!'), findsOneWidget);

    // The response is a NEW row (ReminderEvents are insert-only); the fired
    // row is untouched so its already-uploaded copy stays consistent.
    final fired = await (db.select(db.reminderEvents)
          ..where((t) => t.id.equals('event_test_1')))
        .getSingle();
    expect(fired.outcome, isNull);

    final response = await (db.select(db.reminderEvents)
          ..where((t) => t.outcome.equals('confirmed')))
        .getSingle();
    expect(response.id, isNot('event_test_1'));
    expect(response.medicationId, 'med_test_1');
    expect(response.scheduledAt, fired.scheduledAt);
    expect(response.respondedAt, isNotNull);
    expect(response.synced, isFalse);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Test reminders never write a ReminderEvent outcome',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FullScreenReminderScreen(
          medicationId: 'med_test_1',
          reminderEventId: 'test-123',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('I Have Taken It'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    final rows = await db.select(db.reminderEvents).get();
    expect(rows, hasLength(1), reason: 'only the seeded fired row');
    expect(rows.single.outcome, isNull);
  });

  testWidgets('Portrait phone layout renders without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FullScreenReminderScreen(
          medicationId: 'med_test_1',
          reminderEventId: 'event_test_1',
          syncAfterResponse: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Donepezil'), findsOneWidget);
    expect(find.text('I Have Taken It'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
