import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app_colors.dart';
import '../core/app_services.dart';
import '../core/db/database.dart';
import '../core/voice/voice_player.dart';

/// The dose reminder the elder actually responds to.
///
/// A11 makes this the target of the full-screen intent fired by
/// `fireReminderCallback`; today it is reached from the hidden test trigger on
/// the home screen. Either way it owns the same job: play the caregiver's
/// voice, show the pill, and record what the elder did.
///
/// Recording the outcome is what stops the ladder — without a `respondedAt`,
/// step 2 escalates to a real phone call.
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({
    super.key,
    required this.services,
    required this.medication,
    this.reminderEventId,
    this.voicePlayer,
    this.now,
  });

  final AppServices services;
  final Medication medication;

  /// Supplied by the alarm isolate at A11, which has already written the
  /// `ReminderEvents` row. When absent — the test trigger — this screen
  /// creates one so the outcome has somewhere to live.
  final String? reminderEventId;

  final VoicePlayer? voicePlayer;
  final DateTime Function()? now;

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late final VoicePlayer _voice = widget.voicePlayer ?? JustAudioVoicePlayer();
  late final DateTime Function() _now = widget.now ?? DateTime.now;

  String? _eventId;
  String? _photoPath;
  bool _responding = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final services = widget.services;
    final medication = widget.medication;

    var eventId = widget.reminderEventId;
    if (eventId == null) {
      // Test-fired reminder: create the row this screen will resolve.
      eventId = const Uuid().v4();
      final firedAt = _now().millisecondsSinceEpoch;
      await services.eventRepo.insertReminderEvent(
        ReminderEventsCompanion.insert(
          id: eventId,
          medicationId: medication.id,
          scheduledAt: firedAt,
          firedAt: Value(firedAt),
          channel: 'in_app',
          ladderStep: 0,
        ),
      );
    }

    final photo = medication.pillPhotoPath;
    final photoPath =
        photo == null ? null : await services.resolveMediaPath(photo);

    if (!mounted) return;
    setState(() {
      _eventId = eventId;
      _photoPath = photoPath;
    });

    // The caregiver's own voice is the point; a missing file plays nothing.
    final voice = medication.voicePath;
    if (voice != null) {
      await _voice.play(await services.resolveMediaPath(voice));
    }
  }

  /// Writes the outcome and leaves. `outcome` values match the ladder's
  /// vocabulary: the elder either took it or deferred.
  Future<void> _respond(String outcome) async {
    if (_responding) return;
    setState(() => _responding = true);

    await _voice.stop();

    final eventId = _eventId;
    if (eventId != null) {
      // Records the outcome AND tears down the rest of the ladder, so a
      // "taken" dose can never escalate to a phone call.
      await widget.services.respondToReminder(
        reminderEventId: eventId,
        outcome: outcome,
        now: _now(),
      );
    }

    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photoPath;
    final file = photo == null ? null : File(photo);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A missing photo is skipped silently, never a broken-image box.
              if (file != null && file.existsSync())
                Image.file(file, height: 200, fit: BoxFit.contain),
              const SizedBox(height: 20),
              Text(
                widget.medication.name,
                key: const Key('reminder_medication_name'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                widget.medication.dose,
                key: const Key('reminder_medication_dose'),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  key: const Key('reminder_taken'),
                  onPressed: _responding ? null : () => _respond('taken'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.onColor,
                  ),
                  child: const Text('Taken', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: OutlinedButton(
                  key: const Key('reminder_not_now'),
                  onPressed: _responding ? null : () => _respond('snoozed'),
                  child: const Text('Not now', style: TextStyle(fontSize: 24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
