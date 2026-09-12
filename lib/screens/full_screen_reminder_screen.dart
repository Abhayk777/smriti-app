import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/reminders/native_reminder_bridge.dart';
import '../core/reminders/reminder_isolate.dart';
import '../core/repo/content_repo.dart';
import '../core/sync/sync_engine.dart';

/// Full-screen, high-contrast, elder-friendly medication reminder screen.
///
/// Designed specifically for landscape tablet display:
/// - Appears immediately over the lock screen on Android 10-14+
/// - Prominently displays the medicine pill photo, name, dose, and instructions
/// - Automatically plays the caregiver's voice recording through the alarm audio stream
/// - Provides large, unmistakable action buttons: "I Have Taken It", "Snooze 10 Mins", "Hear Again"
class FullScreenReminderScreen extends StatefulWidget {
  const FullScreenReminderScreen({
    super.key,
    required this.medicationId,
    required this.reminderEventId,
  });

  final String medicationId;
  final String reminderEventId;

  @override
  State<FullScreenReminderScreen> createState() =>
      _FullScreenReminderScreenState();
}

class _FullScreenReminderScreenState extends State<FullScreenReminderScreen>
    with SingleTickerProviderStateMixin {
  final ContentRepo _contentRepo = ContentRepo(appDatabase);
  final AudioPlayer _audioPlayer = AudioPlayer();

  Medication? _medication;
  bool _isLoading = true;
  bool _isPlayingAudio = false;
  bool _actionCompleted = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Keep screen awake while reminder is displayed
    WakelockPlus.enable();
    NativeReminderBridge.wakeUpScreen();

    _loadAndPlay();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _loadAndPlay() async {
    final med = await _contentRepo.getMedication(widget.medicationId);

    if (!mounted) return;

    setState(() {
      _medication = med;
      _isLoading = false;
    });

    if (med != null && med.voicePath != null && med.voicePath!.isNotEmpty) {
      await _playVoiceNote(med.voicePath!);
    }
  }

  Future<void> _playVoiceNote(String voicePath) async {
    try {
      final file = File(voicePath);
      if (!await file.exists()) {
        debugPrint(
            '[FullScreenReminderScreen] Voice file does not exist: $voicePath');
        return;
      }

      await _audioPlayer.setFilePath(voicePath);

      _audioPlayer.playerStateStream.listen((state) {
        if (!mounted) return;
        final playing = state.playing &&
            state.processingState != ProcessingState.completed;
        if (playing != _isPlayingAudio) {
          setState(() {
            _isPlayingAudio = playing;
          });
        }
      });

      setState(() => _isPlayingAudio = true);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[FullScreenReminderScreen] Error playing voice note: $e');
      if (mounted) {
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  Future<void> _replayVoice() async {
    if (_medication?.voicePath != null) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      setState(() => _isPlayingAudio = true);
    }
  }

  /// Cancels scheduled ladder steps 1 (15m) and 2 (30m) deterministic alarms.
  Future<void> _cancelLadderAlarms() async {
    try {
      final alarmId1 = (widget.reminderEventId.hashCode & 0x00FFFFFF) * 10 + 1;
      final alarmId2 = (widget.reminderEventId.hashCode & 0x00FFFFFF) * 10 + 2;
      await AndroidAlarmManager.cancel(alarmId1);
      await AndroidAlarmManager.cancel(alarmId2);
    } catch (e) {
      debugPrint('[FullScreenReminderScreen] Error cancelling ladder alarms: $e');
    }
  }

  /// Handles "I Have Taken It" action.
  Future<void> _onTaken() async {
    if (_actionCompleted) return;
    setState(() => _actionCompleted = true);

    await _audioPlayer.stop();

    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      // 1. Update Drift ReminderEvents table with outcome = 'confirmed'
      await (appDatabase.update(appDatabase.reminderEvents)
            ..where((t) => t.id.equals(widget.reminderEventId)))
          .write(
        ReminderEventsCompanion(
          respondedAt: drift.Value(now),
          outcome: const drift.Value('confirmed'),
          synced: const drift.Value(false),
        ),
      );

      // 2. Cancel ladder escalation steps
      await _cancelLadderAlarms();

      // 3. Trigger non-blocking background sync so caregiver's web app updates
      SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual);
    } catch (e) {
      debugPrint('[FullScreenReminderScreen] Error recording taken status: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Handles "Remind in 10 Mins" (Snooze) action.
  Future<void> _onSnooze() async {
    if (_actionCompleted) return;
    setState(() => _actionCompleted = true);

    await _audioPlayer.stop();

    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      // 1. Update Drift ReminderEvents table with outcome = 'snoozed'
      await (appDatabase.update(appDatabase.reminderEvents)
            ..where((t) => t.id.equals(widget.reminderEventId)))
          .write(
        ReminderEventsCompanion(
          respondedAt: drift.Value(now),
          outcome: const drift.Value('snoozed'),
          synced: const drift.Value(false),
        ),
      );

      // 2. Cancel ladder escalation steps for this event
      await _cancelLadderAlarms();

      // 3. Reschedule one-shot snooze alarm 10 minutes out
      final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
      final snoozeAlarmId =
          (widget.medicationId.hashCode & 0x00FFFFFF) * 10 + 9; // 9 = snooze tag

      await AndroidAlarmManager.oneShotAt(
        snoozeTime,
        snoozeAlarmId,
        fireSnoozeCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: {
          'medicationId': widget.medicationId,
          'dayOfWeek': DateTime.now().weekday,
        },
      );
    } catch (e) {
      debugPrint('[FullScreenReminderScreen] Error handling snooze: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
      );
    }

    final med = _medication;
    final hasPhoto = med?.pillPhotoPath != null &&
        med!.pillPhotoPath!.isNotEmpty &&
        File(med.pillPhotoPath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            children: [
              // Top alert banner with warm, comforting elder styling
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alarm_on_rounded,
                      color: AppColors.onColor,
                      size: 34,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Time for Your Medicine',
                        style: const TextStyle(
                          color: AppColors.onColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Voice status pill
                    if (med?.voicePath != null && med!.voicePath!.isNotEmpty)
                      ScaleTransition(
                        scale: _isPlayingAudio
                            ? _pulseAnimation
                            : const AlwaysStoppedAnimation(1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isPlayingAudio
                                ? AppColors.leafGreen
                                : AppColors.terracottaDark,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPlayingAudio
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_mute_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isPlayingAudio
                                    ? "Caregiver Speaking..."
                                    : "Voice Note Ready",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Main content: Left = Pill Image & Voice Replay, Right = Medicine Details & Instructions
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Pill photo card & Hear Voice Again button
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.raisedSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Pill photo
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: hasPhoto
                                    ? Image.file(
                                        File(med.pillPhotoPath!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Container(
                                        color: AppColors.medicineBlush,
                                        width: double.infinity,
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.medication_rounded,
                                              size: 80,
                                              color: AppColors.terracotta,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Pill Image',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Replay voice note button
                            if (med?.voicePath != null &&
                                med!.voicePath!.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _replayVoice,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.indigo,
                                    foregroundColor: AppColors.onColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.replay_rounded,
                                      size: 24),
                                  label: const Text(
                                    'Hear Voice Again',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right Column: Details & Instructions
                    Expanded(
                      flex: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.raisedSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Medicine name
                            Text(
                              med?.name ?? 'Scheduled Medication',
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Dose badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.medicineBlush,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.terracotta
                                        .withAlpha(60)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      size: 22, color: AppColors.terracotta),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dose: ${med?.dose ?? "As directed"}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.terracottaDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Instructions text
                            const Text(
                              'Instructions:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  'Please take your medicine now with a full glass of water. Your caregiver has recorded a reminder for you.',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    height: 1.4,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Actions: Large "I Have Taken It" & "Remind in 10 Mins" buttons
              Row(
                children: [
                  // Remind in 10 mins (Snooze) button
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 68,
                      child: OutlinedButton.icon(
                        onPressed: _onSnooze,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.marigold, width: 3),
                          backgroundColor: AppColors.raisedSurface,
                          foregroundColor: AppColors.marigoldDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.snooze_rounded, size: 28),
                        label: const Text(
                          'Remind in 10 Mins',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Large green "I Have Taken It" button
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 68,
                      child: ElevatedButton.icon(
                        onPressed: _onTaken,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.leafGreen,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_rounded,
                            size: 36, color: Colors.white),
                        label: const Text(
                          'I Have Taken It',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-level callback for Snooze alarms.
@pragma('vm:entry-point')
Future<void> fireSnoozeCallback(int id, Map<String, dynamic> params) async {
  // Directly delegate to the main fireReminderCallback
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    try {
      DartPluginRegistrant.ensureInitialized();
    } catch (_) {}
  }

  // Import and fire reminder callback
  await fireReminderCallback(id, params);
}
