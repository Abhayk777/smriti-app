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

class _MedicineScreenState extends State<MedicineScreen> {
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
    _load();
    // Auto-refresh medications from Supabase in the background
    SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual).then((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
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
            _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.raisedSurface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.leafGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.leafGreen, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '💊  My Medicines',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💊', style: TextStyle(fontSize: 72)),
          SizedBox(height: 16),
          Text(
            'No medicines scheduled.',
            style: TextStyle(fontSize: 22, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        final isTaken = _visuallyTakenIds.contains(med.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isTaken
                ? AppColors.leafGreen.withValues(alpha: 0.08)
                : AppColors.raisedSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTaken ? AppColors.leafGreen : AppColors.border,
              width: isTaken ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.leafGreen.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pill photo or icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.medicineBlush,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FutureBuilder<File?>(
                  future: _resolveMedPhoto(med.pillPhotoPath, med.id),
                  builder: (context, snapshot) {
                    final file = snapshot.data;
                    if (file != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const Center(
                      child: Text('💊', style: TextStyle(fontSize: 36)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),

              // Med details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isTaken ? AppColors.secondaryText : AppColors.primaryText,
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_timeOfDayLabel(med.chosenTimeMin)} • ${_formatTime(med.chosenTimeMin)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.leafGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dose: ${med.dose}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // Listen voice button
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.leafGreen),
                tooltip: 'Listen instructions',
                onPressed: () => _playInstruction(med),
              ),
              const SizedBox(width: 12),

              // Taken check button
              GestureDetector(
                onTap: () {
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
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isTaken ? AppColors.leafGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.leafGreen,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTaken ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: isTaken ? Colors.white : AppColors.leafGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isTaken ? 'Taken' : 'Take',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isTaken ? Colors.white : AppColors.leafGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
