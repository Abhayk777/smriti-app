import 'package:flutter/material.dart';

import '../core/db/app_database.dart';
import '../core/reminders/reminder_permissions.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'reminder_setup_screen.dart';

/// The main screen that decides what to show on launch.
///
/// - Not paired (no patientId in AppConfigs): LoginScreen.
/// - Paired but a reminder permission is off: ReminderSetupScreen, until the
///   caregiver taps Done / Continue (once per app launch).
/// - Otherwise: HomeScreen.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Per process, so "Continue for now" doesn't nag until the next launch.
  static bool _setupDismissed = false;

  late Future<({bool paired, bool needsSetup})> _start = _load();

  Future<({bool paired, bool needsSetup})> _load() async {
    final patientId = await appDatabase.appConfigsDao.getValue('patientId');
    final paired = patientId != null && patientId.isNotEmpty;
    final needsSetup =
        paired && !_setupDismissed && !await ReminderPermissions.allGranted();
    return (paired: paired, needsSetup: needsSetup);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({bool paired, bool needsSetup})>(
      future: _start,
      builder: (context, snapshot) {
        final start = snapshot.data;
        if (start == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!start.paired) {
          // Device is not paired - show login screen
          return const LoginScreen();
        }

        if (start.needsSetup) {
          return ReminderSetupScreen(
            onDone: () => setState(() {
              _setupDismissed = true;
              _start = _load();
            }),
          );
        }

        // Device is paired - show home screen
        return const HomeScreen();
      },
    );
  }
}
