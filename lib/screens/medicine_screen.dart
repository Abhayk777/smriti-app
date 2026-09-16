import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/files/file_paths.dart';
import '../core/repo/content_repo.dart';
import '../core/repo/event_repo.dart';
import '../core/sync/sync_engine.dart';
import '../ui/smriti_ui.dart';

/// Screen displaying the elder's daily medications.
///
/// Reads directly from local SQLite `Medications` table.
/// High contrast, large pill icons/photos, voice reminder playback,
/// and simple tap-to-confirm visual feedback.
class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen>
    with WidgetsBindingObserver {
  final ContentRepo _repo = ContentRepo(appDatabase);
  final EventRepo _eventRepo = EventRepo(appDatabase);
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  List<Medication> _medications = [];
  bool _loading = true;
  final Set<String> _visuallyTakenIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    // Auto-refresh medications from Supabase in the background
    SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual).then((_) {
      if (mounted) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A dose confirmed on the full-screen reminder (a separate activity) is
    // written to the database while this screen sits in the background.
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final meds = await _repo.getMedications(activeOnly: true);
    final todayStart = DateTime.now()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)
        .millisecondsSinceEpoch;
    final confirmedEvents = await (appDatabase.select(appDatabase.reminderEvents)
          ..where((t) =>
              t.respondedAt.isBiggerOrEqualValue(todayStart) &
              t.outcome.equals('confirmed')))
        .get();
    final takenIds = confirmedEvents.map((e) => e.medicationId).toSet();

    if (mounted) {
      setState(() {
        _medications = meds;
        _visuallyTakenIds.addAll(takenIds);
        _loading = false;
      });
    }
  }

  Future<void> _recordTaken(Medication med) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = const Uuid().v4();

    final event = ReminderEventsCompanion.insert(
      id: id,
      medicationId: med.id,
      scheduledAt: now,
      firedAt: drift.Value(now),
      respondedAt: drift.Value(now),
      outcome: const drift.Value('confirmed'),
      channel: 'in_app',
      ladderStep: 0,
      synced: const drift.Value(false),
    );

    await _eventRepo.insertReminderEvent(event);

    setState(() {
      _visuallyTakenIds.add(med.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recorded dose: ${med.name}'),
          backgroundColor: AppColors.leafGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Automatically push to Supabase in background
    unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual));
  }

  String _formatTime(int min) {
    final h = min ~/ 60;
    final m = min % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:${m.toString().padLeft(2, '0')} $period';
  }

  String _timeOfDayLabel(int min) {
    if (min < 720) return 'Morning';
    if (min < 1020) return 'Afternoon';
    return 'Evening';
  }

  Future<File?> _resolveMedPhoto(String? rawPath, String medId) async {
    if (rawPath != null && rawPath.isNotEmpty) {
      final direct = File(rawPath);
      if (direct.existsSync() && direct.lengthSync() > 0) return direct;
    }
    final dir = await FilePaths.medicationPhotos();
    if (rawPath != null && rawPath.isNotEmpty) {
      final byBase = File('$dir/${rawPath.split('/').last}');
      if (byBase.existsSync() && byBase.lengthSync() > 0) return byBase;
    }
    for (final ext in ['.jpg', '.jpeg', '.png']) {
      final byId = File('$dir/$medId$ext');
      if (byId.existsSync() && byId.lengthSync() > 0) return byId;
    }
    return null;
  }

  Future<File?> _resolveMedVoice(String? rawPath, String medId) async {
    if (rawPath != null && rawPath.isNotEmpty) {
      final direct = File(rawPath);
      if (direct.existsSync() && direct.lengthSync() > 0) return direct;
    }
    final dir = await FilePaths.medicationVoice();
    if (rawPath != null && rawPath.isNotEmpty) {
      final byBase = File('$dir/${rawPath.split('/').last}');
      if (byBase.existsSync() && byBase.lengthSync() > 0) return byBase;
    }
    for (final ext in ['.m4a', '.mp3', '.aac', '.wav']) {
      final byId = File('$dir/$medId$ext');
      if (byId.existsSync() && byId.lengthSync() > 0) return byId;
    }
    return null;
  }

  Future<void> _playInstruction(Medication med) async {
    final voiceFile = await _resolveMedVoice(med.voicePath, med.id);
    if (voiceFile != null && voiceFile.existsSync()) {
      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(voiceFile.path);
      await _audioPlayer.play();
      return;
    }

    // TTS fallback for voice instruction
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.speak('Please take ${med.name}, dose ${med.dose}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(
              title: 'My Medicines',
              subtitle: 'Tap Take once you have had it',
              icon: Icons.medication_rounded,
              color: AppColors.leafGreen,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.leafGreen),
                    )
                  : _medications.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const EmptyState(
      icon: Icons.medication_rounded,
      color: AppColors.leafGreen,
      title: 'No medicines scheduled.',
    );
  }

  void _onTakeTap(Medication med, bool isTaken) {
    if (!isTaken) {
      _recordTaken(med);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med.name} is already marked as taken today.'),
          backgroundColor: AppColors.leafGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildList() {
    final gutter = Screen.gutter(context);
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        final isTaken = _visuallyTakenIds.contains(med.id);
        return MaxWidth(
          maxWidth: 900,
          child: _buildMedicineCard(med, isTaken),
        );
      },
    );
  }

  Widget _buildMedicineCard(Medication med, bool isTaken) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 600;
        final photoSize = stacked ? 84.0 : 96.0;

        final photo = Container(
          width: photoSize,
          height: photoSize,
          decoration: BoxDecoration(
            color: AppColors.medicineBlush,
            borderRadius: BorderRadius.circular(20),
          ),
          child: FutureBuilder<File?>(
            future: _resolveMedPhoto(med.pillPhotoPath, med.id),
            builder: (context, snapshot) {
              final file = snapshot.data;
              if (file != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                  ),
                );
              }
              return Icon(
                Icons.medication_rounded,
                size: photoSize * 0.5,
                color: AppColors.terracotta,
              );
            },
          ),
        );

        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              med.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isTaken ? AppColors.secondaryText : AppColors.primaryText,
                decoration: isTaken ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 22, color: AppColors.leafGreenDark),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${_timeOfDayLabel(med.chosenTimeMin)}, ${_formatTime(med.chosenTimeMin)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.leafGreenDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Dose: ${med.dose}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ],
        );

        final listen = SizedBox(
          height: 60,
          child: OutlinedButton.icon(
            onPressed: () => _playInstruction(med),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.leafGreenDark,
              side: const BorderSide(color: AppColors.leafGreen, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            icon: const Icon(Icons.volume_up_rounded, size: 28),
            label: const Text(
              'Listen',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
        );

        final take = SizedBox(
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () => _onTakeTap(med, isTaken),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isTaken ? AppColors.leafGreenDark : AppColors.leafGreen,
              foregroundColor: AppColors.onColor,
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            icon: Icon(
              isTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 28,
            ),
            label: Text(
              isTaken ? 'Taken' : 'Take',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isTaken
                ? AppColors.leafGreen.withValues(alpha: 0.10)
                : AppColors.raisedSurface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isTaken ? AppColors.leafGreen : AppColors.border,
              width: isTaken ? 2 : 1.5,
            ),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        photo,
                        const SizedBox(width: 16),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: listen),
                        const SizedBox(width: 12),
                        Expanded(child: take),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    photo,
                    const SizedBox(width: 20),
                    Expanded(child: details),
                    const SizedBox(width: 12),
                    listen,
                    const SizedBox(width: 12),
                    take,
                  ],
                ),
        );
      },
    );
  }
}
