import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/reminders/ladder.dart';

void main() {
  group('ladder shape', () {
    test('matches the steps and timings in spec section 10', () {
      expect(ReminderLadder.delayFor(0), Duration.zero);
      expect(ReminderLadder.delayFor(1), const Duration(minutes: 15));
      expect(ReminderLadder.delayFor(2), const Duration(minutes: 30));

      // Steps 3-5 belong to the server; the device must not invent them.
      expect(() => ReminderLadder.delayFor(3), throwsArgumentError);
      expect(ReminderLadder.lastDeviceStep, 2);
    });

    test('steps 0 and 1 are local, step 2 is the server handoff', () {
      expect(ReminderLadder.isLocalStep(0), isTrue);
      expect(ReminderLadder.isLocalStep(1), isTrue);
      expect(ReminderLadder.isLocalStep(2), isFalse);
    });

    test('step 1 is louder than step 0', () {
      expect(ReminderLadder.isLouder(0), isFalse);
      expect(ReminderLadder.isLouder(1), isTrue);
    });

    test('escalation ids are the deterministic {eventId}_{step} form', () {
      expect(ReminderLadder.escalationId('abc', 2), 'abc_2');
      // Same inputs, same id, forever - this is what stops a second call.
      expect(
        ReminderLadder.escalationId('abc', 2),
        ReminderLadder.escalationId('abc', 2),
      );
    });
  });

  group('alarm ids', () {
    test('are stable for the same medication and day', () {
      final first = ReminderLadder.doseAlarmId('med-1', 3);
      final second = ReminderLadder.doseAlarmId('med-1', 3);
      expect(first, second);
    });

    test('differ per day and per medication', () {
      final monday = ReminderLadder.doseAlarmId('med-1', 1);
      final tuesday = ReminderLadder.doseAlarmId('med-1', 2);
      final other = ReminderLadder.doseAlarmId('med-2', 1);

      expect(monday, isNot(tuesday));
      expect(monday, isNot(other));
    });

    test('ladder ids are keyed on the dose, not the medication', () {
      // Two doses of the same medicine must not cancel each other's ladder.
      final today = ReminderLadder.ladderAlarmId('event-1', 2);
      final tomorrow = ReminderLadder.ladderAlarmId('event-2', 2);
      expect(today, isNot(tomorrow));

      // And the two steps of one dose are distinct.
      expect(
        ReminderLadder.ladderAlarmId('event-1', 1),
        isNot(ReminderLadder.ladderAlarmId('event-1', 2)),
      );
    });

    test('all ids fit in the positive 32-bit range Android accepts', () {
      for (final id in [
        ReminderLadder.doseAlarmId('a-very-long-medication-uuid-here', 7),
        ReminderLadder.ladderAlarmId('a-very-long-event-uuid-here', 2),
      ]) {
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThan(1 << 31));
      }
    });

    test('the hash is content-based, not identity-based', () {
      // The literals below are separate String instances with equal content.
      final a = ['med', '-', '1'].join();
      const b = 'med-1';
      expect(ReminderLadder.stableHash(a), ReminderLadder.stableHash(b));
    });
  });

  group('days of week', () {
    test('parses the stored comma form', () {
      expect(ReminderLadder.parseDays('1,2,3,4,5,6,7'), [1, 2, 3, 4, 5, 6, 7]);
      expect(ReminderLadder.parseDays('1,3,5'), [1, 3, 5]);
      expect(ReminderLadder.parseDays(' 2 , 4 '), [2, 4]);
    });

    test('drops junk rather than scheduling a nonsense day', () {
      expect(ReminderLadder.parseDays(''), isEmpty);
      expect(ReminderLadder.parseDays('0,8,9'), isEmpty);
      expect(ReminderLadder.parseDays('1,x,3'), [1, 3]);
    });
  });

  group('next occurrence', () {
    // Sunday 7 September 2025, 09:30.
    final from = DateTime(2025, 9, 7, 9, 30);

    test('finds the coming weekday at the dose time', () {
      // Monday 08:20.
      final next = ReminderLadder.nextOccurrence(
        dayOfWeek: DateTime.monday,
        minutesFromMidnight: 500,
        from: from,
      );
      expect(next, DateTime(2025, 9, 8, 8, 20));
    });

    test('later today still counts as today', () {
      final next = ReminderLadder.nextOccurrence(
        dayOfWeek: DateTime.sunday,
        minutesFromMidnight: 20 * 60,
        from: from,
      );
      expect(next, DateTime(2025, 9, 7, 20, 0));
    });

    test('a dose time already past today rolls to next week', () {
      // 08:00 on a Sunday, when it is already 09:30 - must not fire instantly.
      final next = ReminderLadder.nextOccurrence(
        dayOfWeek: DateTime.sunday,
        minutesFromMidnight: 8 * 60,
        from: from,
      );
      expect(next, DateTime(2025, 9, 14, 8, 0));
      expect(next.isAfter(from), isTrue);
    });

    test('is always in the future, for every day and time', () {
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
        for (final minutes in [0, 500, 1439]) {
          final next = ReminderLadder.nextOccurrence(
            dayOfWeek: day,
            minutesFromMidnight: minutes,
            from: from,
          );
          expect(next.isAfter(from), isTrue,
              reason: 'day $day at $minutes was not in the future');
          expect(next.weekday, day);
        }
      }
    });
  });
}
