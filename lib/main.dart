import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import 'app_colors.dart';
import 'core/auth/supabase_bootstrap.dart';
import 'core/sync/sync_engine.dart';
import 'screens/main_screen.dart';

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

  // Initialize local notifications
  try {
    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await localNotifications.initialize(initSettings);

    final androidImplementation = localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'medication_reminder',
          'Medication Reminder',
          description: 'Full-screen medication reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidImplementation.requestNotificationsPermission();
    }
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  // Request permissions
  try {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
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
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

/// Callback dispatcher for Workmanager.
///
/// This is required by Workmanager to handle background tasks.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // For now, we'll trigger sync from the main app
    // In a full implementation, we would run sync here directly
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.terracotta),
      ),
      home: const MainScreen(),
    );
  }
}
