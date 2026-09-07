import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'core/app_services.dart';
import 'core/auth/supabase_bootstrap.dart';
import 'screens/startup_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSupabase();

  final services = AppServices();

  // AndroidAlarmManager must be initialised before any alarm can be scheduled,
  // and the notification channels before any can be shown. Neither is fatal on
  // a platform that has no alarm manager, so failures do not block startup.
  try {
    await services.alarmScheduler.initialize();
    await services.reminderNotifier.initialize();
  } catch (_) {}

  runApp(MyApp(services: services));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smriti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.terracotta),
      ),
      home: StartupGate(services: services),
    );
  }
}
