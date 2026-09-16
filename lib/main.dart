import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import 'core/auth/supabase_bootstrap.dart';
import 'core/reminders/native_reminder_bridge.dart';
import 'core/sync/sync_engine.dart';
import 'screens/main_screen.dart';
import 'screens/reminder_app.dart';
import 'ui/smriti_ui.dart';

/// Entrypoint of the native `ReminderActivity` (its own FlutterEngine, shown
/// over the lock screen). Renders only the reminder, nothing else in the app.
/// Must live in this library: FlutterActivity looks custom entrypoints up in
/// the main library by default.
@pragma('vm:entry-point')
Future<void> reminderMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Needed for "Remind in 10 Mins", which schedules a snooze alarm.
  try {
    await AndroidAlarmManager.initialize();
  } catch (e) {
    debugPrint('Error initializing AndroidAlarmManager: $e');
  }
  runApp(const ReminderApp());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await initSupabase();

  // Initialize Android Alarm Manager for medication reminders
  try {
    await AndroidAlarmManager.initialize();
  } catch (e) {
    debugPrint('Error initializing AndroidAlarmManager: $e');
  }

  // Reminder permissions (notifications, display over other apps, full-screen,
  // exact alarms, battery) are requested with explanations on
  // ReminderSetupScreen, which MainScreen shows after pairing.
  try {
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
  } catch (_) {}

  // Initialize Workmanager for periodic sync
  try {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    await SyncEngine.registerPeriodicSync();
  } catch (e) {
    debugPrint('Error initializing Workmanager: $e');
  }

  // Initialize Sync Engine & Supabase Realtime for instant medication updates
  try {
    await SyncEngine.defaultInstance.init();
    // The reminder screen hands its sync to this engine, which owns the
    // Supabase session.
    NativeReminderBridge.onSyncRequested(() async {
      await SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual);
    });
    // Run initial sync in background to pull any new medications and reschedule alarms
    SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual);
  } catch (e) {
    debugPrint('Error initializing SyncEngine: $e');
  }

  // Phones in portrait, tablets in landscape. On Android MainActivity sets
  // this natively before the first frame; other platforms are set here.
  if (!Platform.isAndroid) await _applyDeviceOrientation();

  runApp(const MyApp());
}

/// Tablet (shortest side 600dp or more) keeps landscape, anything smaller
/// keeps portrait.
Future<void> _applyDeviceOrientation() async {
  final displays = PlatformDispatcher.instance.displays;
  if (displays.isEmpty) return;
  final display = displays.first;
  if (display.size.isEmpty || display.devicePixelRatio <= 0) return;
  final shortest = display.size.shortestSide / display.devicePixelRatio;
  await SystemChrome.setPreferredOrientations(
    shortest >= 600
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [DeviceOrientation.portraitUp],
  );
}

/// Callback dispatcher for Workmanager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smriti',
      theme: SmritiTheme.light(),
      home: const MainScreen(),
    );
  }
}
