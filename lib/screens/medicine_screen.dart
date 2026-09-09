import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/repo/content_repo.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  List<Medication> _medications = [];
  bool _loading = true;
  final Set<String> _visuallyTakenIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final meds = await _repo.getMedications(activeOnly: true);
    if (mounted) {
      setState(() {
        _medications = meds;
        _loading = false;
      });
    }
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

  Future<void> _playInstruction(Medication med) async {
    if (med.voicePath != null && med.voicePath!.isNotEmpty) {
      final file = File(med.voicePath!);
      if (file.existsSync()) {
        await _audioPlayer.stop();
        await _audioPlayer.setFilePath(file.path);
        await _audioPlayer.play();
        return;
      }
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
        final hasPhoto = med.pillPhotoPath != null &&
            med.pillPhotoPath!.isNotEmpty &&
            File(med.pillPhotoPath!).existsSync();

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
                child: hasPhoto
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(med.pillPhotoPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Text('💊', style: TextStyle(fontSize: 36)),
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
                  setState(() {
                    if (isTaken) {
                      _visuallyTakenIds.remove(med.id);
                    } else {
                      _visuallyTakenIds.add(med.id);
                    }
                  });
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
