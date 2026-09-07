import 'package:flutter/material.dart';

import '../core/db/app_database.dart';
import '../core/repo/content_repo.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// The main screen that decides whether to show the login screen or home screen.
///
/// If the device is paired (patientId exists in AppConfigs), shows HomeScreen.
/// Otherwise, shows LoginScreen.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: appDatabase.appConfigsDao.getValue('patientId'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final patientId = snapshot.data;
        
        if (patientId != null && patientId.isNotEmpty) {
          // Device is paired - show home screen
          return const HomeScreen();
        } else {
          // Device is not paired - show login screen
          return const LoginScreen();
        }
      },
    );
  }
}
