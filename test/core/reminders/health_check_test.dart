import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/reminders/alarm_scheduler.dart';
import 'package:smriti/core/reminders/health_check.dart';
import 'package:smriti/core/repo/content_repo.dart';

import '../repo/_test_db.dart';
import '_fake_alarm_api.dart';

class FakePermissions implements PermissionGateway {
  FakePermissions({
    this.exactAlarm = CheckOutcome.granted,
    this.notifications = CheckOutcome.granted,
    this.battery = CheckOutcome.granted,
    this.microphone = CheckOutcome.granted,
  });

  CheckOutcome exactAlarm;
  CheckOutcome notifications;
  CheckOutcome battery;
  CheckOutcome microphone;

  final List<String> requested = [];

  @override
  Future<CheckOutcome> requestExactAlarm() async {
    requested.add('exactAlarm');
    return exactAlarm;
  }

  @override
  Future<CheckOutcome> requestNotifications() async {
    requested.add('notifications');
    return notifications;
  }

  @override
  Future<CheckOutcome> requestBatteryExemption() async {
    requested.add('battery');
    return battery;
  }

  @override
  Future<CheckOutcome> requestMicrophone() async {
    requested.add('microphone');
    return microphone;
  }
}

class FakeOem implements OemGateway {
  FakeOem({this.name = 'xiaomi', this.opens = true, this.throwOnOpen = false});

  final String name;
  final bool opens;
  final bool throwOnOpen;

  final List<String> openedFor = [];

  @override
  Future<String> manufacturer() async => name;

  @override
  Future<bool> openAutostartSettings(String manufacturer) async {
    openedFor.add(manufacturer);
    if (throwOnOpen) throw Exception('activity not found on this ROM');
    return opens;
  }
}

void main() {
  late SmritiDatabase db;
  late FakeAlarmApi alarms;
  late AlarmScheduler scheduler;
  var clock = DateTime(2025, 9, 8, 8, 0);

  setUp(() {
    db = newTestDb();
    alarms = FakeAlarmApi();
    clock = DateTime(2025, 9, 8, 8, 0);
    scheduler = AlarmScheduler(
      contentRepo: ContentRepo(db),
      alarmApi: alarms,
      now: () => clock,
    );
  });

  tearDown(() async => db.close());

  SetupHealthCheck newCheck({
    FakePermissions? permissions,
    FakeOem? oem,
  }) =>
      SetupHealthCheck(
        configs: db.appConfigsDao,
        scheduler: scheduler,
        permissions: permissions ?? FakePermissions(),
        oem: oem ?? FakeOem(),
        now: () => clock,
      );

  group('permissions', () {
    test('requests all four the reminders need', () async {
      final permissions = FakePermissions();
      await newCheck(permissions: permissions).run();

      expect(permissions.requested,
          ['exactAlarm', 'notifications', 'battery', 'microphone']);
    });

    test('names what is missing', () async {
      final report = await newCheck(
        permissions: FakePermissions(
          exactAlarm: CheckOutcome.denied,
          battery: CheckOutcome.denied,
        ),
      ).run();

      expect(report.isReady, isFalse);
      expect(report.problems, contains('Exact alarms not permitted'));
      expect(report.problems, contains('Battery optimisation still on'));
      expect(report.problems, isNot(contains('Notifications not permitted')));
    });
  });

  group('OEM handling', () {
    test('opens the autostart screen for a known manufacturer', () async {
      final oem = FakeOem(name: 'xiaomi');
      final report = await newCheck(oem: oem).run();

      expect(oem.openedFor, ['xiaomi']);
      expect(report.manufacturer, 'xiaomi');
      expect(report.autostartOpened, isTrue);
    });

    test('an unknown manufacturer is not a failure', () async {
      final report =
          await newCheck(oem: FakeOem(name: 'pixel', opens: false)).run();

      expect(report.autostartOpened, isFalse);
      expect(report.problems, isNot(contains('autostart')));
    });

    test('a ROM with a different activity name does not break setup',
        () async {
      // Component names vary per ROM; a wrong one throws.
      final report =
          await newCheck(oem: FakeOem(name: 'oppo', throwOnOpen: true)).run();

      expect(report.autostartOpened, isFalse);
      expect(report.manufacturer, 'oppo');
    });

    test('every OEM in the spec has autostart components mapped', () {
      for (final manufacturer in ['xiaomi', 'oppo', 'vivo', 'huawei', 'samsung']) {
        expect(
          AndroidOemGateway.autostartComponents[manufacturer],
          isNotNull,
          reason: '$manufacturer is named in spec section 10',
        );
        expect(
          AndroidOemGateway.autostartComponents[manufacturer],
          isNotEmpty,
        );
      }
    });
  });

  group('the live test alarm', () {
    test('is never assumed to have fired', () async {
      final report = await newCheck().run();

      // Permissions all granted, and still not ready.
      expect(report.exactAlarm, CheckOutcome.granted);
      expect(report.notifications, CheckOutcome.granted);
      expect(report.testAlarmFired, isNull);
      expect(report.isReady, isFalse,
          reason: 'granted permissions do not mean alarms fire');
      expect(report.problems, contains('Test alarm not confirmed yet'));
    });

    test('is scheduled 60 seconds out through the real alarm path', () async {
      await newCheck().scheduleTestAlarm();

      expect(alarms.scheduled, hasLength(1));
      expect(alarms.scheduled.single.time,
          clock.add(const Duration(seconds: 60)));
    });

    test('reports ready only once it has actually fired', () async {
      final check = newCheck();
      await check.scheduleTestAlarm();
      expect(await check.testAlarmFired(), isNull);

      // The alarm isolate writes this when it runs.
      clock = clock.add(const Duration(seconds: 61));
      await db.appConfigsDao.setValue(
        SetupHealthCheck.testAlarmFiredKey,
        '${clock.millisecondsSinceEpoch}',
      );

      expect(await check.testAlarmFired(), isTrue);
      final report = await check.run();
      expect(report.isReady, isTrue);
      expect(report.problems, isEmpty);
    });

    test('a stale result from a previous run does not count', () async {
      // An old success sitting in config from yesterday.
      await db.appConfigsDao.setValue(
        SetupHealthCheck.testAlarmFiredKey,
        '${clock.subtract(const Duration(days: 1)).millisecondsSinceEpoch}',
      );

      final check = newCheck();
      await check.scheduleTestAlarm();

      expect(await check.testAlarmFired(), isNull,
          reason: 'scheduling clears the previous result');
    });

    test('an overdue alarm that never fired is detectable', () async {
      final check = newCheck();
      await check.scheduleTestAlarm();

      expect(await check.testAlarmOverdue(), isFalse);

      // Well past the 60s window.
      clock = clock.add(const Duration(minutes: 5));
      expect(await check.testAlarmOverdue(), isTrue,
          reason: 'this is what an OEM battery manager looks like');

      final report = await check.run();
      expect(report.isReady, isFalse);
    });

    test('is not overdue before it was ever scheduled', () async {
      expect(await newCheck().testAlarmOverdue(), isFalse);
    });
  });
}
