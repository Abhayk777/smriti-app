import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

import '../app_colors.dart';
import '../core/auth/supabase_bootstrap.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/reminders/reminder_isolate.dart';
import '../core/reminders/reminder_screen_channel.dart';
import '../core/repo/content_repo.dart';
import '../core/repo/event_repo.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/locale_controller.dart';
import '../core/sync/sync_engine.dart';
import '../ui/smriti_ui.dart';

/// Full-screen, high-contrast, elder-friendly medication reminder screen.
///
/// Runs inside the native `ReminderActivity` (see `reminderMain`), which is
/// shown over the lock screen without asking for the PIN:
/// - Prominently displays the medicine pill photo, name, and dose
/// - Automatically plays the caregiver's voice recording on the alarm stream
/// - Provides large, unmistakable action buttons: "I Have Taken It", "Remind in 10 Mins", "Hear Voice Again"
/// - One calm column on phones; photo beside the buttons on landscape tablets
class FullScreenReminderScreen extends StatefulWidget {
  const FullScreenReminderScreen({
    super.key,
    required this.medicationId,
    required this.reminderEventId,
    this.onFinished,
    this.syncAfterResponse = true,
  });

  final String medicationId;
  final String reminderEventId;

  /// Called once the elder has responded. Defaults to popping the route.
  final VoidCallback? onFinished;

  /// Push the response to Supabase right away so the caregiver sees it.
  final bool syncAfterResponse;

  @override
  State<FullScreenReminderScreen> createState() =>
      _FullScreenReminderScreenState();
}

class _FullScreenReminderScreenState extends State<FullScreenReminderScreen>
    with SingleTickerProviderStateMixin {
  final ContentRepo _contentRepo = ContentRepo(appDatabase);

  // Only created when the native alarm-stream player isn't available.
  AudioPlayer? _fallbackPlayer;
  StreamSubscription<PlayerState>? _fallbackSub;
  StreamSubscription<bool>? _nativeVoiceSub;
  bool _usingNativeVoice = false;

  Medication? _medication;
  bool _isLoading = true;
  bool _isPlayingAudio = false;
  bool _actionCompleted = false;
  String? _doneMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _isTest =>
      widget.reminderEventId.startsWith(ReminderRequest.testEventPrefix);

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

    _nativeVoiceSub =
        ReminderScreenChannel.instance.voicePlaying.listen((playing) {
      if (mounted && _usingNativeVoice && playing != _isPlayingAudio) {
        setState(() => _isPlayingAudio = playing);
      }
    });

    _loadAndPlay();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nativeVoiceSub?.cancel();
    _fallbackSub?.cancel();
    _stopVoice();
    _fallbackPlayer?.dispose();
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
      if (!await File(voicePath).exists()) {
        debugPrint(
            '[FullScreenReminderScreen] Voice file does not exist: $voicePath');
        return;
      }

      // Preferred: native MediaPlayer on the alarm stream (audible at media
      // volume 0, allowed by Android 17's background-audio rules).
      if (await ReminderScreenChannel.instance.playVoice(voicePath)) {
        _usingNativeVoice = true;
        return;
      }

      // Fallback: not running in ReminderActivity, or MediaPlayer can't
      // decode this file.
      _usingNativeVoice = false;
      final player = _fallbackPlayer ??= AudioPlayer();
      _fallbackSub ??= player.playerStateStream.listen((state) {
        if (!mounted) return;
        final playing = state.playing &&
            state.processingState != ProcessingState.completed;
        if (playing != _isPlayingAudio) {
          setState(() => _isPlayingAudio = playing);
        }
      });
      await player.setFilePath(voicePath);
      unawaited(player.play());
    } catch (e) {
      debugPrint('[FullScreenReminderScreen] Error playing voice note: $e');
      if (mounted) {
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  Future<void> _stopVoice() async {
    if (_usingNativeVoice) {
      await ReminderScreenChannel.instance.stopVoice();
    }
    try {
      await _fallbackPlayer?.stop();
    } catch (_) {}
  }

  Future<void> _replayVoice() async {
    final voicePath = _medication?.voicePath;
    if (voicePath != null && voicePath.isNotEmpty) {
      await _playVoiceNote(voicePath);
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

  /// Records the elder's response as a NEW ReminderEvents row.
  ///
  /// ReminderEvents are insert-only (AGENTS.md #3): the fired row may already
  /// be on the server, and the device can only insert there, so editing it
  /// would never reach the caregiver (and its re-upload would fail as a
  /// duplicate). The response row copies the fired row's schedule details.
  Future<void> _recordOutcome(String outcome) async {
    final eventRepo = EventRepo(appDatabase);
    final fired = await eventRepo.getReminderEvent(widget.reminderEventId);
    final now = DateTime.now().millisecondsSinceEpoch;
    await eventRepo.insertReminderEvent(
      ReminderEventsCompanion.insert(
        id: const Uuid().v4(),
        medicationId: widget.medicationId,
        scheduledAt: fired?.scheduledAt ?? now,
        firedAt: drift.Value(fired?.firedAt ?? now),
        respondedAt: drift.Value(now),
        outcome: drift.Value(outcome),
        channel: fired?.channel ?? reminderChannelInApp,
        ladderStep: fired?.ladderStep ?? 0,
        synced: const drift.Value(false),
      ),
    );
  }

  /// Handles "I Have Taken It" action.
  Future<void> _onTaken() async {
    if (_actionCompleted) return;
    setState(() => _actionCompleted = true);

    await _stopVoice();

    if (!_isTest) {
      try {
        // 1. Update Drift ReminderEvents table with outcome = 'confirmed'
        await _recordOutcome('confirmed');

        // 2. Cancel ladder escalation steps
        await _cancelLadderAlarms();
      } catch (e) {
        debugPrint('[FullScreenReminderScreen] Error recording taken status: $e');
      }
    }

    final lang = LocaleController.instance.currentLanguage;
    await _showDoneAndFinish(AppStrings.medicineRecordedWellDone(lang));
  }

  /// Handles "Remind in 10 Mins" (Snooze) action.
  Future<void> _onSnooze() async {
    if (_actionCompleted) return;
    setState(() => _actionCompleted = true);

    await _stopVoice();

    if (!_isTest) {
      try {
        // 1. Update Drift ReminderEvents table with outcome = 'snoozed'
        await _recordOutcome('snoozed');

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
          alarmClock: true,
          rescheduleOnReboot: true,
          params: {
            'medicationId': widget.medicationId,
            'dayOfWeek': DateTime.now().weekday,
          },
        );
      } catch (e) {
        debugPrint('[FullScreenReminderScreen] Error handling snooze: $e');
      }
    }

    final lang = LocaleController.instance.currentLanguage;
    await _showDoneAndFinish(AppStrings.willRemindIn10Minutes(lang));
  }

  Future<void> _showDoneAndFinish(String message) async {
    await ReminderScreenChannel.instance
        .dismissNotification(widget.reminderEventId);
    if (mounted) setState(() => _doneMessage = message);

    await Future.wait([
      Future<void>.delayed(const Duration(seconds: 2)),
      if (widget.syncAfterResponse && !_isTest) _syncResponse(),
    ]);

    if (!mounted) return;
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Best-effort push so the caregiver's web app updates. Offline or slow is
  /// fine: the event stays unsynced and the main app's sync picks it up.
  ///
  /// If the main app's engine is running it owns the Supabase session, so it
  /// does the sync; starting Supabase here as well could get the device
  /// signed out (two engines rotating one refresh token).
  Future<void> _syncResponse() async {
    try {
      if (await ReminderScreenChannel.instance.requestMainAppSync()) return;
      await initSupabase();
      await SyncEngine.defaultInstance
          .run(trigger: SyncTrigger.manual)
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('[FullScreenReminderScreen] Sync after response failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final lang = LocaleController.instance.currentLanguage;
        return PopScope(
          // The elder answers with a button; back must not silently dismiss.
          canPop: false,
          child: Scaffold(
            backgroundColor: AppColors.pageBackground,
            body: SafeArea(child: _buildBody(lang)),
          ),
        );
      },
    );
  }

  Widget _buildBody(String lang) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.terracotta),
      );
    }

    if (_doneMessage != null) {
      return _buildDoneMessage(_doneMessage!);
    }

    final med = _medication;
    final hasPhoto = med?.pillPhotoPath != null &&
        med!.pillPhotoPath!.isNotEmpty &&
        File(med.pillPhotoPath!).existsSync();
    final hasVoice = med?.voicePath != null && med!.voicePath!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > constraints.maxHeight &&
            constraints.maxWidth >= 640;
        final pad = wide ? 32.0 : 20.0;

        if (wide) {
          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              children: [
                _buildHeading(med, large: true, lang: lang),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMedicine(med, hasPhoto, hasVoice, lang),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_buildActions(lang)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeading(med, large: false, lang: lang),
              const SizedBox(height: 12),
              Expanded(child: _buildMedicine(med, hasPhoto, hasVoice, lang)),
              const SizedBox(height: 16),
              _buildActions(lang),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoneMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopIn(
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  color: AppColors.leafGreen.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 120,
                  color: AppColors.leafGreen,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Time for Your Medicine" with the scheduled time underneath.
  Widget _buildHeading(Medication? med, {required bool large, required String lang}) {
    return Row(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: IconMedallion(
            icon: Icons.alarm_rounded,
            color: AppColors.onColor,
            background: AppColors.terracotta,
            size: large ? 64 : 56,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.timeForYourMedicine(lang),
                style: TextStyle(
                  fontSize: large ? 32 : 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  height: 1.15,
                ),
              ),
              if (med != null)
                Text(
                  formatClock(med.chosenTimeMin ~/ 60, med.chosenTimeMin % 60),
                  style: TextStyle(
                    fontSize: large ? 22 : 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.terracottaDark,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Photo, name, dose and the single "hear again" control, centred.
  Widget _buildMedicine(Medication? med, bool hasPhoto, bool hasVoice, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Room left for the photo after name, dose and voice button.
        final textBlock = hasVoice ? 190.0 : 120.0;
        final photoSize = (constraints.maxHeight - textBlock)
            .clamp(0.0, constraints.maxWidth * 0.75)
            .clamp(0.0, 300.0);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (photoSize >= 72) ...[
                  Container(
                    width: photoSize,
                    height: photoSize,
                    decoration: BoxDecoration(
                      color: AppColors.medicineBlush,
                      borderRadius: BorderRadius.circular(photoSize * 0.16),
                      border: Border.all(color: AppColors.raisedSurface, width: 6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasPhoto
                        ? Image.file(File(med!.pillPhotoPath!), fit: BoxFit.cover)
                        : Icon(
                            Icons.medication_rounded,
                            size: photoSize * 0.45,
                            color: AppColors.terracotta,
                          ),
                  ),
                  const SizedBox(height: 18),
                ],
                Text(
                  med?.name ?? 'Scheduled Medication',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.doseLabel(lang, med?.dose ?? "As directed"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
                if (hasVoice) ...[
                  const SizedBox(height: 16),
                  _buildVoiceButton(lang),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// One control for the caregiver's voice: shows when it is playing and
  /// replays it on tap.
  Widget _buildVoiceButton(String lang) {
    final playing = _isPlayingAudio;
    return BouncyTap(
      onTap: _actionCompleted ? null : _replayVoice,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(10, 10, 22, 10),
        decoration: BoxDecoration(
          color: playing ? AppColors.indigo : AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.indigo, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: playing
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: IconMedallion(
                icon: playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                color: playing ? AppColors.indigo : AppColors.onColor,
                background: playing ? AppColors.onColor : AppColors.indigo,
                size: 44,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              playing ? AppStrings.listening(lang) : AppStrings.hearVoiceAgain(lang),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: playing ? AppColors.onColor : AppColors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Large "I Have Taken It" & "Remind in 10 Mins" buttons
  Widget _buildActions(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 84,
          child: ElevatedButton.icon(
            onPressed: _actionCompleted ? null : _onTaken,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leafGreen,
              foregroundColor: AppColors.onColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.check_circle_rounded,
                size: 40, color: AppColors.onColor),
            label: Text(
              AppStrings.iHaveTakenIt(lang),
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: TextButton.icon(
            onPressed: _actionCompleted ? null : _onSnooze,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.marigoldDark,
              backgroundColor: AppColors.marigold.withValues(alpha: 0.14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.snooze_rounded, size: 30),
            label: Text(
              AppStrings.remindIn10Mins(lang),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
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
