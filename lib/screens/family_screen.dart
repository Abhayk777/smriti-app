import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/files/file_paths.dart';
import '../core/files/local_media.dart';
import '../core/repo/content_repo.dart';
import '../core/sync/sync_engine.dart';
import '../ui/smriti_ui.dart';

Future<File?> _resolveFile(String rawPath, Future<String> Function() getDir, String id, [List<String> exts = photoExtensions]) =>
    resolveLocalMedia(rawPath, getDir, id, exts);

/// Calm placeholder colours for people without a photo.
Color _placeholderColor(String name) {
  const colors = [
    AppColors.indigo,
    AppColors.terracotta,
    AppColors.leafGreen,
    AppColors.riverTeal,
    AppColors.marigoldDark,
    AppColors.indigoDark,
  ];
  if (name.isEmpty) return colors.first;
  return colors[name.codeUnitAt(0) % colors.length];
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Shows the elder's family as a warm photo grid.
///
/// Reads from the local `People` Drift table, never from the network.
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
            const ScreenHeader(
              title: 'My Family',
              subtitle: 'The people who love you',
              icon: Icons.people_alt_rounded,
              color: AppColors.indigo,
            ),
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

  Widget _buildEmpty() {
    return const EmptyState(
      icon: Icons.people_alt_rounded,
      color: AppColors.indigo,
      title: 'Your family will appear here',
      message: 'Photos show up once your caregiver adds them.',
    );
  }

  Widget _buildGrid() {
    final gutter = Screen.gutter(context);
    final compact = MediaQuery.sizeOf(context).width < 520;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 240 : 280,
        crossAxisSpacing: compact ? 12 : 18,
        mainAxisSpacing: compact ? 12 : 18,
        childAspectRatio: 0.78,
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
    return PressableCard(
      onTap: onTap,
      borderColor: AppColors.border,
      semanticLabel: person.name,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: FutureBuilder<File?>(
                future: _resolveFile(person.photoPath, FilePaths.peoplePhotos, person.id),
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  if (file != null) {
                    return Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  }
                  return _buildPlaceholder();
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
            child: Column(
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 19,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final color = _placeholderColor(person.name);
    return Container(
      color: color.withValues(alpha: 0.14),
      width: double.infinity,
      child: Center(
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
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
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > constraints.maxHeight &&
                constraints.maxWidth >= 640;
            final photo = _buildPhoto(person);
            final details = _buildDetails(person, hasAudio);

            final gutter = constraints.maxWidth >= 600 ? 32.0 : 18.0;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 14),
                  child: const Row(children: [RoundBackButton()]),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: photo),
                              const SizedBox(width: 28),
                              Expanded(
                                flex: 5,
                                child: Center(
                                  child: SingleChildScrollView(child: details),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: photo),
                              const SizedBox(height: 20),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.45,
                                ),
                                child: SingleChildScrollView(child: details),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhoto(PeopleData person) {
    final color = _placeholderColor(person.name);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: _photoFile != null
          ? Image.file(_photoFile!, fit: BoxFit.cover)
          : Container(
              color: color.withValues(alpha: 0.14),
              child: Center(
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 140,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDetails(PeopleData person, bool hasAudio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          person.name,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _capitalize(person.relationship),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.indigo,
          ),
        ),
        if (person.memoryPrompt != null && person.memoryPrompt!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            person.memoryPrompt!,
            style: const TextStyle(
              fontSize: 21,
              color: AppColors.secondaryText,
              height: 1.45,
            ),
          ),
        ],
        if (hasAudio) ...[
          const SizedBox(height: 22),
          SizedBox(
            height: 64,
            child: ElevatedButton.icon(
              onPressed: _toggleAudio,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _playing ? AppColors.terracotta : AppColors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              icon: Icon(
                _playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: 30,
              ),
              label: Text(
                _playing
                    ? 'Stop'
                    : (_voiceFile != null ? 'Hear Voice Message' : 'Hear Prompt'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
