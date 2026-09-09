import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/files/file_paths.dart';
import '../core/repo/content_repo.dart';
import '../core/sync/sync_engine.dart';

/// Resolves a local file checking rawPath, then fallback directory.
Future<File?> _resolveFile(String rawPath, Future<String> Function() getDir, String id, [List<String> exts = const ['.jpg', '.jpeg', '.png']]) async {
  if (rawPath.isNotEmpty) {
    final direct = File(rawPath);
    if (direct.existsSync() && direct.lengthSync() > 0) return direct;
  }
  final dir = await getDir();
  if (rawPath.isNotEmpty) {
    final byBase = File(p.join(dir, p.basename(rawPath)));
    if (byBase.existsSync() && byBase.lengthSync() > 0) return byBase;
  }
  for (final ext in exts) {
    final byId = File(p.join(dir, '$id$ext'));
    if (byId.existsSync() && byId.lengthSync() > 0) return byId;
  }
  return null;
}

/// Shows the elder's family as a warm photo grid.
///
/// Reads from the local `People` Drift table — never from the network.
/// Tapping a card opens a full-screen portrait with the memory prompt
/// read aloud via TTS or caregiver voice.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final ContentRepo _repo = ContentRepo(appDatabase);
  List<PeopleData> _people = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-refresh content from Supabase in the background
    SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual).then((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final people = await _repo.getPeople();
    if (mounted) {
      setState(() {
        _people = people;
        _loading = false;
      });
    }
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
                      child: CircularProgressIndicator(color: AppColors.indigo),
                    )
                  : _people.isEmpty
                      ? _buildEmpty()
                      : _buildGrid(),
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
                color: AppColors.indigo.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.indigo, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '👨‍👩‍👧‍👦  My Family',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          const Text(
            'Your family photos will appear here\nonce your caregiver sets them up.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _people.length,
      itemBuilder: (context, index) {
        final person = _people[index];
        return _PersonCard(
          person: person,
          onTap: () => _openDetail(context, person),
        );
      },
    );
  }

  void _openDetail(BuildContext context, PeopleData person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PersonDetailScreen(person: person),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.onTap});

  final PeopleData person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.indigo.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: FutureBuilder<File?>(
                  future: _resolveFile(person.photoPath, FilePaths.peoplePhotos, person.id),
                  builder: (context, snapshot) {
                    final file = snapshot.data;
                    if (file != null) {
                      return Image.file(file, fit: BoxFit.cover, width: double.infinity);
                    }
                    return _buildPlaceholder();
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _capitalize(person.relationship),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _placeholderColor(),
      width: double.infinity,
      child: Center(
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _placeholderColor() {
    final colors = [
      AppColors.indigo,
      AppColors.terracotta,
      AppColors.marigold,
      AppColors.leafGreen,
      const Color(0xFF7B5EA7),
      const Color(0xFF3D7A8A),
    ];
    return colors[person.name.codeUnitAt(0) % colors.length];
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Full-screen person detail ─────────────────────────────────────────────────

class _PersonDetailScreen extends StatefulWidget {
  const _PersonDetailScreen({required this.person});

  final PeopleData person;

  @override
  State<_PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<_PersonDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  AudioPlayer? _player;
  bool _playing = false;
  File? _voiceFile;
  File? _photoFile;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  Future<void> _initMedia() async {
    final photo = await _resolveFile(widget.person.photoPath, FilePaths.peoplePhotos, widget.person.id);
    final voice = await _resolveFile(widget.person.voicePath ?? '', FilePaths.peopleVoice, widget.person.id, ['.m4a', '.mp3', '.aac', '.wav']);
    if (mounted) {
      setState(() {
        _photoFile = photo;
        _voiceFile = voice;
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_playing) {
      await _stopAudio();
    } else {
      await _playAudio();
    }
  }

  Future<void> _playAudio() async {
    // 1. If caregiver voice recording is present on disk, play it!
    if (_voiceFile != null && _voiceFile!.existsSync()) {
      setState(() => _playing = true);
      _player ??= AudioPlayer();
      try {
        await _player!.setFilePath(_voiceFile!.path);
        await _player!.play();
      } catch (e) {
        debugPrint('Error playing voice recording: $e');
      } finally {
        if (mounted) setState(() => _playing = false);
      }
      return;
    }

    // 2. Otherwise fall back to TTS for memoryPrompt
    final prompt = widget.person.memoryPrompt;
    if (prompt == null || prompt.isEmpty) return;
    setState(() => _playing = true);
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(prompt);
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _stopAudio() async {
    await _player?.stop();
    await _tts.stop();
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final hasAudio = (_voiceFile != null && _voiceFile!.existsSync()) ||
        (person.memoryPrompt != null && person.memoryPrompt!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.primaryText,
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen photo or placeholder
            Positioned.fill(
              child: _photoFile != null
                  ? Image.file(_photoFile!, fit: BoxFit.cover)
                  : Container(
                      color: _placeholderColor(person),
                      child: Center(
                        child: Text(
                          person.name.isNotEmpty
                              ? person.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 160,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),

            // Gradient overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 280,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Name + relationship + prompt + Audio button
            Positioned(
              left: 32,
              right: 32,
              bottom: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _capitalize(person.relationship),
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (person.memoryPrompt != null &&
                      person.memoryPrompt!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      person.memoryPrompt!,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (hasAudio) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _toggleAudio,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _playing
                              ? AppColors.terracotta
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _playing ? Icons.stop : Icons.volume_up,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _playing
                                  ? 'Stop'
                                  : (_voiceFile != null ? 'Hear Voice Message' : 'Hear Prompt'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _placeholderColor(PeopleData p) {
    final colors = [
      AppColors.indigo,
      AppColors.terracotta,
      AppColors.marigold,
      AppColors.leafGreen,
    ];
    return colors[p.name.codeUnitAt(0) % colors.length];
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
