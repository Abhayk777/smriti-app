import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'app_colors.dart';
import 'core/auth/supabase_bootstrap.dart';
import 'core/sync/sync_engine.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await initSupabase();
  
  // Initialize Workmanager for periodic sync
  await Workmanager().initialize(
    callbackDispatcher,
  );
  
  // Register periodic sync task
  await SyncEngine.registerPeriodicSync();
  
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
