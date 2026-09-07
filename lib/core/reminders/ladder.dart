/// The reminder ladder, as pure logic.
///
/// APP-BUILD-SPEC.md §10:
///
/// | Step | When  | Owner                                              |
/// |------|-------|----------------------------------------------------|
/// | 0    | T+0   | Device — full-screen, caregiver's voice             |
/// | 1    | T+15m | Device — repeat, louder                             |
/// | 2    | T+30m | Device writes `escalations`, server places the call |
/// | 3–5  | later | Server only                                         |
///
/// Steps 0 and 1 work with no network at all. Step 2 is a fire-and-forget row
/// write; the device never dials anything.
///
/// Everything here is deliberately free of plugins and I/O so it can be tested
/// directly — the parts that cannot be tested are the ones that talk to
/// AndroidAlarmManager.
class ReminderLadder {
  const ReminderLadder._();

  static const int stepInitial = 0;
  static const int stepRepeat = 1;
  static const int stepEscalate = 2;

  /// Last step the device owns. Anything above this belongs to the server.
  static const int lastDeviceStep = stepEscalate;

  static const Duration step1Delay = Duration(minutes: 15);
  static const Duration step2Delay = Duration(minutes: 30);

  /// Delay from the original dose time for a given step.
  static Duration delayFor(int step) => switch (step) {
        stepInitial => Duration.zero,
        stepRepeat => step1Delay,
        stepEscalate => step2Delay,
        _ => throw ArgumentError('no device ladder step $step'),
      };

  /// Steps 0 and 1 need nothing but the tablet.
  static bool isLocalStep(int step) => step <= stepRepeat;

  /// Step 1 repeats the reminder louder than step 0.
  static bool isLouder(int step) => step >= stepRepeat;

  /// Escalation ids are deterministic (AGENTS.md non-negotiable #2), so a
  /// retry after a crash can never produce a second phone call.
  static String escalationId(String reminderEventId, int step) =>
      '${reminderEventId}_$step';

  /// Alarm id for a medication's regular daily dose.
  ///
  /// Shape is APP-BUILD-SPEC.md §10's `(hash & 0x00FFFFFF) * 10 + dayOfWeek`,
  /// but over [stableHash] rather than `String.hashCode`: these ids must match
  /// across process restarts and reboots, otherwise a later `cancel` computes a
  /// different id, misses, and leaves a duplicate alarm firing forever.
  static int doseAlarmId(String medicationId, int dayOfWeek) =>
      (stableHash(medicationId) & 0x00FFFFFF) * 10 + dayOfWeek;

  /// Alarm id for a pending ladder step of one specific dose.
  ///
  /// Keyed on the reminder event rather than the medication, so cancelling one
  /// dose's ladder cannot cancel tomorrow's.
  static int ladderAlarmId(String reminderEventId, int step) =>
      (stableHash('$reminderEventId#ladder') & 0x00FFFFFF) * 10 + step;

  /// FNV-1a. Deterministic for the same input in every process, unlike
  /// `String.hashCode`, which Dart does not guarantee across runs.
  static int stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Parses `Medications.daysOfWeek` ("1,2,3,4,5,6,7"). 1 = Monday, matching
  /// `DateTime.weekday`.
  static List<int> parseDays(String daysOfWeek) {
    final days = <int>[];
    for (final part in daysOfWeek.split(',')) {
      final day = int.tryParse(part.trim());
      if (day != null && day >= DateTime.monday && day <= DateTime.sunday) {
        days.add(day);
      }
    }
    return days;
  }

  /// The next time [dayOfWeek] falls at [minutesFromMidnight], strictly after
  /// [from].
  ///
  /// Always in the future: a dose time that has already passed today rolls to
  /// next week rather than firing immediately on reschedule.
  static DateTime nextOccurrence({
    required int dayOfWeek,
    required int minutesFromMidnight,
    required DateTime from,
  }) {
    final daysAhead = (dayOfWeek - from.weekday + 7) % 7;
    var candidate = DateTime(
      from.year,
      from.month,
      from.day + daysAhead,
      minutesFromMidnight ~/ 60,
      minutesFromMidnight % 60,
    );
    if (!candidate.isAfter(from)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }
}
