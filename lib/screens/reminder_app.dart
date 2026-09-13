import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/reminders/reminder_screen_channel.dart';
import 'full_screen_reminder_screen.dart';

/// Root widget of the `reminderMain` engine that runs inside the native
/// `ReminderActivity` (shown over the lock screen).
///
/// Shows one [FullScreenReminderScreen] at a time. Reminders that fire while
/// one is showing queue behind it; a repeat of the current one (ladder
/// step 1) reloads it so the voice plays again. When the queue is empty the
/// activity closes and the lock screen or previous app returns.
class ReminderApp extends StatefulWidget {
  const ReminderApp({super.key});

  @override
  State<ReminderApp> createState() => _ReminderAppState();
}

class _ReminderAppState extends State<ReminderApp> {
  final _channel = ReminderScreenChannel.instance;
  final List<ReminderRequest> _queue = [];
  StreamSubscription<ReminderRequest>? _newReminderSub;

  // Bumped to rebuild the current screen when its reminder fires again.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _newReminderSub = _channel.newReminders.listen(_enqueue);
    _loadInitial();
  }

  @override
  void dispose() {
    _newReminderSub?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final initial = await _channel.ready();
    if (!mounted) return;
    if (initial.isEmpty && _queue.isEmpty) {
      await _channel.close();
      return;
    }
    initial.forEach(_enqueue);
  }

  void _enqueue(ReminderRequest request) {
    setState(() {
      final existing = _queue.indexWhere(
        (r) => r.reminderEventId == request.reminderEventId,
      );
      if (existing == 0) {
        _generation++;
      } else if (existing < 0) {
        _queue.add(request);
      }
    });
  }

  void _onCurrentFinished() {
    if (_queue.isEmpty) return;
    setState(() {
      _queue.removeAt(0);
      _generation++;
    });
    if (_queue.isEmpty) _channel.close();
  }

  @override
  Widget build(BuildContext context) {
    final current = _queue.isEmpty ? null : _queue.first;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smriti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.terracotta),
      ),
      home: current == null
          ? const Scaffold(backgroundColor: AppColors.pageBackground)
          : FullScreenReminderScreen(
              key: ValueKey('${current.reminderEventId}#$_generation'),
              medicationId: current.medicationId,
              reminderEventId: current.reminderEventId,
              onFinished: _onCurrentFinished,
            ),
    );
  }
}
