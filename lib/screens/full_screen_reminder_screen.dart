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
import '../core/sync/sync_engine.dart';

/// Full-screen, high-contrast, elder-friendly medication reminder screen.
///
/// Runs inside the native `ReminderActivity` (see `reminderMain`), which is
/// shown over the lock screen without asking for the PIN:
/// - Prominently displays the medicine pill photo, name, and dose
/// - Automatically plays the caregiver's voice recording on the alarm stream
/// - Provides large, unmistakable action buttons: "I Have Taken It", "Remind in 10 Mins", "Hear Voice Again"
/// - Lays out as a row on landscape tablets and a column on portrait phones
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
        channel: fired?.channel ?? 'fullscreen',
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

    await _showDoneAndFinish('Thank you!');
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

    await _showDoneAndFinish('I will remind you again in 10 minutes');
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
    return PopScope(
      // The elder answers with a button; back must not silently dismiss.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
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
        final portrait = constraints.maxHeight > constraints.maxWidth;
        return Padding(
          padding: portrait
              ? const EdgeInsets.all(16)
              : const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            children: [
              _buildBanner(hasVoice: hasVoice, compact: portrait),
              SizedBox(height: portrait ? 14 : 20),
              Expanded(
                child: portrait
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildPhotoCard(med, hasPhoto, hasVoice),
                          ),
                          const SizedBox(height: 14),
                          _buildDetailsCard(med),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _buildPhotoCard(med, hasPhoto, hasVoice),
                          ),
                          const SizedBox(width: 24),
                          Expanded(flex: 6, child: _buildDetailsCard(med)),
                        ],
                      ),
              ),
              SizedBox(height: portrait ? 14 : 20),
              _buildActions(portrait: portrait),
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
            const Icon(
              Icons.check_circle_rounded,
              size: 120,
              color: AppColors.leafGreen,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top alert banner with warm, comforting elder styling
  Widget _buildBanner({required bool hasVoice, required bool compact}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: 14),
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
          SizedBox(width: compact ? 10 : 16),
          Expanded(
            child: Text(
              'Time for Your Medicine',
              style: TextStyle(
                color: AppColors.onColor,
                fontSize: compact ? 22 : 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Voice status pill
          if (hasVoice)
            ScaleTransition(
              scale: _isPlayingAudio
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    if (!compact) ...[
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );

  // Pill photo card & Hear Voice Again button
  Widget _buildPhotoCard(Medication? med, bool hasPhoto, bool hasVoice) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: hasPhoto
                  ? Image.file(
                      File(med!.pillPhotoPath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: AppColors.medicineBlush,
                      width: double.infinity,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
          if (hasVoice) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _actionCompleted ? null : _replayVoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: AppColors.onColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.replay_rounded, size: 24),
                label: const Text(
                  'Hear Voice Again',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Medicine name and dose
  Widget _buildDetailsCard(Medication? med) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            med?.name ?? 'Scheduled Medication',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.medicineBlush,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.terracotta.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 24, color: AppColors.terracotta),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Dose: ${med?.dose ?? "As directed"}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracottaDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Large "I Have Taken It" & "Remind in 10 Mins" buttons
  Widget _buildActions({required bool portrait}) {
    final snooze = SizedBox(
      height: 68,
      child: OutlinedButton.icon(
        onPressed: _actionCompleted ? null : _onSnooze,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.marigold, width: 3),
          backgroundColor: AppColors.raisedSurface,
          foregroundColor: AppColors.marigoldDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.snooze_rounded, size: 28),
        label: const Text(
          'Remind in 10 Mins',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );

    final taken = SizedBox(
      height: 68,
      child: ElevatedButton.icon(
        onPressed: _actionCompleted ? null : _onTaken,
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
    );

    if (portrait) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [taken, const SizedBox(height: 12), snooze],
      );
    }
    return Row(
      children: [
        Expanded(flex: 4, child: snooze),
        const SizedBox(width: 20),
        Expanded(flex: 6, child: taken),
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
