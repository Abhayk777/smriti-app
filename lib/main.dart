import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import 'app_colors.dart';
import 'core/auth/supabase_bootstrap.dart';
import 'core/reminders/native_reminder_bridge.dart';
import 'core/sync/sync_engine.dart';
import 'screens/full_screen_reminder_screen.dart';
import 'screens/main_screen.dart';

/// Global navigator key to allow opening the FullScreenReminderScreen from
/// notification callbacks or background events.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Opens the full-screen medication reminder screen from a notification payload.
void openReminderScreen(String payload) {
  debugPrint('[main] Opening reminder screen with payload: $payload');
  if (!payload.startsWith('medication_reminder:')) return;

  final parts = payload.split(':');
  // Format: medication_reminder:medicationId:reminderEventId
  // Fallback: medication_reminder:reminderEventId
  String medicationId = '';
  String reminderEventId = '';

  if (parts.length >= 3) {
    medicationId = parts[1];
    reminderEventId = parts[2];
  } else if (parts.length == 2) {
    reminderEventId = parts[1];
    medicationId = parts[1];
  }

  if (medicationId.isEmpty) return;

  // Wake up the screen via native bridge
  NativeReminderBridge.wakeUpScreen();

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => FullScreenReminderScreen(
        medicationId: medicationId,
        reminderEventId: reminderEventId,
      ),
    ),
  );
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

  String? initialPayload;

  // Initialize local notifications with alarm-category channel and response handlers
  try {
    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          openReminderScreen(payload);
        }
      },
    );

    final androidImplementation = localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      // Create high-importance channel with alarm audio usage
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'medication_reminder',
          'Medication Reminder',
          description: 'Full-screen medication reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidImplementation.requestNotificationsPermission();
    }

    // Check if the app was launched by tapping a notification (or fullScreenIntent cold-start)
    final launchDetails =
        await localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      initialPayload = launchDetails.notificationResponse?.payload;
    }
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  // Request Android runtime permissions
  try {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
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

  // Initialize Sync Engine & Supabase Realtime for instant medication updates
  try {
    await SyncEngine.defaultInstance.init();
    // Run initial sync in background to pull any new medications and reschedule alarms
    SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual);
  } catch (e) {
    debugPrint('Error initializing SyncEngine: $e');
  }

  // Set preferred landscape orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(MyApp(initialReminderPayload: initialPayload));
}

/// Callback dispatcher for Workmanager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return Future.value(true);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialReminderPayload});

  final String? initialReminderPayload;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if (widget.initialReminderPayload != null &&
        widget.initialReminderPayload!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openReminderScreen(widget.initialReminderPayload!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Smriti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.terracotta),
      ),
      home: const MainScreen(),
    );
  }
}
