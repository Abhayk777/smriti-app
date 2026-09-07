import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'core/auth/supabase_bootstrap.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSupabase();

  runApp(const MyApp());
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
      home: const LoginScreen(),
    );
  }
}
