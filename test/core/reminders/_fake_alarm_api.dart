import 'package:smriti/core/reminders/alarm_scheduler.dart';

/// Records what would have been scheduled or cancelled.
///
/// Nothing here proves an alarm fires — that is only observable on a real
/// device. What it does prove is the bookkeeping: that ids match between
/// schedule and cancel, that cancel runs before reschedule, and that a
/// cancelled ladder step is really gone.
class FakeAlarmApi implements AlarmApi {
  final List<ScheduledAlarm> scheduled = [];
  final List<int> cancelled = [];

  /// Ordered log of both kinds of call.
  final List<String> calls = [];

  bool initialized = false;

  /// Ids currently armed: scheduled and not since cancelled.
  Set<int> get pendingIds {
    final ids = <int>{};
    for (final call in calls) {
      final parts = call.split(':');
      if (parts.first == 'schedule') {
        ids.add(int.parse(parts[1]));
      } else {
        ids.remove(int.parse(parts[1]));
      }
    }
    return ids;
  }

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<bool> oneShotAt(
    DateTime time,
    int id,
    Function callback, {
    required Map<String, dynamic> params,
  }) async {
    calls.add('schedule:$id');
    scheduled.add(ScheduledAlarm(time: time, id: id, params: params));
    return true;
  }

  @override
  Future<bool> cancel(int id) async {
    calls.add('cancel:$id');
    cancelled.add(id);
    return true;
  }
}

class ScheduledAlarm {
  const ScheduledAlarm({
    required this.time,
    required this.id,
    required this.params,
  });

  final DateTime time;
  final int id;
  final Map<String, dynamic> params;

  int get step => params['step'] as int;
  String? get medicationId => params['medicationId'] as String?;
  String? get reminderEventId => params['reminderEventId'] as String?;
}
