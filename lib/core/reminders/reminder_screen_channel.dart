import 'dart:async';

import 'package:flutter/services.dart';

/// A reminder the full-screen `ReminderActivity` has been asked to show.
class ReminderRequest {
  const ReminderRequest({
    required this.medicationId,
    required this.reminderEventId,
  });

  final String medicationId;
  final String reminderEventId;

  /// Test reminders come from the setup screen / diagnostics. They must not
  /// write ReminderEvents or schedule ladder steps, or they'd reach the
  /// caregiver as real missed doses.
  bool get isTest => reminderEventId.startsWith(testEventPrefix);

  static const String testEventPrefix = 'test-';

  static ReminderRequest? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final medicationId = raw['medicationId'];
    final reminderEventId = raw['reminderEventId'];
    if (medicationId is! String || reminderEventId is! String) return null;
    return ReminderRequest(
      medicationId: medicationId,
      reminderEventId: reminderEventId,
    );
  }
}

/// Dart side of `ReminderActivity`'s MethodChannel. Only exists inside the
/// `reminderMain` engine; every call fails with MissingPluginException
/// anywhere else, which callers treat as "not running in ReminderActivity".
class ReminderScreenChannel {
  ReminderScreenChannel._() {
    _channel.setMethodCallHandler(_handle);
  }

  static final ReminderScreenChannel instance = ReminderScreenChannel._();

  static const MethodChannel _channel =
      MethodChannel('com.example.smriti/reminder_screen');

  final _newReminders = StreamController<ReminderRequest>.broadcast();
  final _voicePlaying = StreamController<bool>.broadcast();

  /// Reminders that fire while the screen is already showing.
  Stream<ReminderRequest> get newReminders => _newReminders.stream;

  /// Native voice player state.
  Stream<bool> get voicePlaying => _voicePlaying.stream;

  Future<void> _handle(MethodCall call) async {
    switch (call.method) {
      case 'newReminder':
        final request = ReminderRequest.fromMap(call.arguments);
        if (request != null) _newReminders.add(request);
      case 'voiceState':
        _voicePlaying.add(call.arguments == true);
    }
  }

  /// Returns the reminders that launched the activity.
  Future<List<ReminderRequest>> ready() async {
    final raw = await _channel.invokeMethod<List<Object?>>('ready');
    return (raw ?? const [])
        .map(ReminderRequest.fromMap)
        .whereType<ReminderRequest>()
        .toList();
  }

  /// Plays [path] on the alarm stream. Returns false if not in
  /// ReminderActivity or the file can't be played.
  Future<bool> playVoice(String path) async {
    try {
      return await _channel.invokeMethod<bool>('playVoice', {'path': path}) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> stopVoice() async {
    try {
      await _channel.invokeMethod<void>('stopVoice');
    } on MissingPluginException {
      // Not in ReminderActivity.
    }
  }

  Future<void> dismissNotification(String reminderEventId) async {
    try {
      await _channel.invokeMethod<void>(
        'dismissNotification',
        {'reminderEventId': reminderEventId},
      );
    } on MissingPluginException {
      // Not in ReminderActivity.
    }
  }

  /// Finishes ReminderActivity; the lock screen (or previous app) returns.
  Future<void> close() async {
    try {
      await _channel.invokeMethod<void>('close');
    } on MissingPluginException {
      // Not in ReminderActivity.
    }
  }
}
