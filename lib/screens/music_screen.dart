import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_colors.dart';

class _Track {
  final String title;
  final String category;
  final String icon;
  final String? localFilePath;
  final String? narration;

  const _Track({
    required this.title,
    required this.category,
    required this.icon,
    this.localFilePath,
    this.narration,
  });
}

/// Calming music and peaceful soundscapes screen for elder relaxation.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  late AnimationController _pulseController;
  int _selectedTrackIndex = 0;
  bool _isPlaying = false;
  List<_Track> _tracks = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
        });
      }
    });

    _loadTracks();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadTracks() async {
    final List<_Track> found = [];

    // Check custom documents/music folder if caregiver added files
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(docDir.path, 'music'));
      if (await musicDir.exists()) {
        final files = musicDir.listSync();
        for (final f in files) {
          if (f is File &&
              (f.path.endsWith('.mp3') ||
                  f.path.endsWith('.m4a') ||
                  f.path.endsWith('.wav'))) {
            found.add(
              _Track(
                title: p.basenameWithoutExtension(f.path),
                category: 'Family Audio',
                icon: '🎵',
                localFilePath: f.path,
              ),
            );
          }
        }
      }
    } catch (_) {}

    // Built-in soothing sound meditation & relaxation presets
    found.addAll([
      const _Track(
        title: 'Morning Serenity',
        category: 'Peaceful Raga',
        icon: '🌅',
        narration: 'Take a deep breath and listen to the gentle morning silence.',
      ),
      const _Track(
        title: 'Sacred Temple Bells',
        category: 'Chimes & Harmony',
        icon: '🔔',
        narration: 'Gentle temple chimes ringing softly in the morning breeze.',
      ),
      const _Track(
        title: 'Flute by the River',
        category: 'Bansuri Meditation',
        icon: '🪈',
        narration: 'Soft bamboo flute music flowing like a quiet river.',
      ),
      const _Track(
        title: 'Evening Birds & Rain',
        category: 'Nature Melody',
        icon: '🌧️',
        narration: 'Cool evening rain falling gently on green tree leaves.',
      ),
    ]);

    if (mounted) {
      setState(() {
        _tracks = found;
      });
    }
  }

  Future<void> _playTrack(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    setState(() {
      _selectedTrackIndex = index;
    });

    final track = _tracks[index];

    if (track.localFilePath != null && File(track.localFilePath!).existsSync()) {
      try {
        await _tts.stop();
        await _player.stop();
        await _player.setFilePath(track.localFilePath!);
        await _player.play();
        return;
      } catch (e) {
        debugPrint('Music play error: $e');
      }
    }

    // Fallback narration / meditation guidance with TTS
    await _player.stop();
    await _tts.stop();
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(0.95);
    setState(() => _isPlaying = true);
    await _tts.speak(track.narration ?? track.title);
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      await _tts.stop();
      setState(() => _isPlaying = false);
    } else {
      await _playTrack(_selectedTrackIndex);
    }
  }

  void _nextTrack() {
    final next = (_selectedTrackIndex + 1) % _tracks.length;
    _playTrack(next);
  }

  void _prevTrack() {
    final prev = (_selectedTrackIndex - 1 + _tracks.length) % _tracks.length;
    _playTrack(prev);
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack =
        _tracks.isNotEmpty ? _tracks[_selectedTrackIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                children: [
                  // Player main panel (Left)
                  Expanded(
                    flex: 5,
                    child: _buildPlayerPanel(currentTrack),
                  ),
                  Container(width: 1.5, color: AppColors.border),
                  // Playlist panel (Right)
                  Expanded(
                    flex: 4,
                    child: _buildPlaylistPanel(),
                  ),
                ],
              ),
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
            onTap: () {
              _player.stop();
              _tts.stop();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.marigold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.marigold, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '🎵  Music & Peace',
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

  Widget _buildPlayerPanel(_Track? track) {
    if (track == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.marigold));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated vinyl / lotus disc
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _isPlaying ? 1.0 + _pulseController.value * 0.06 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.raisedSurface,
                    border: Border.all(color: AppColors.marigold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.marigold.withValues(
                          alpha: _isPlaying ? 0.35 : 0.15,
                        ),
                        blurRadius: _isPlaying ? 35 : 15,
                        spreadRadius: _isPlaying ? 5 : 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(track.icon, style: const TextStyle(fontSize: 80)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Track Title
          Text(
            track.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            track.category,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 44,
                icon: const Icon(Icons.skip_previous_rounded, color: AppColors.marigoldDark),
                onPressed: _prevTrack,
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.marigold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.marigold.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                iconSize: 44,
                icon: const Icon(Icons.skip_next_rounded, color: AppColors.marigoldDark),
                onPressed: _nextTrack,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistPanel() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final t = _tracks[index];
        final isCurrent = index == _selectedTrackIndex;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.marigold.withValues(alpha: 0.12)
                : AppColors.raisedSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? AppColors.marigold : AppColors.border,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Text(t.icon, style: const TextStyle(fontSize: 28)),
            title: Text(
              t.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            subtitle: Text(
              t.category,
              style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            trailing: isCurrent && _isPlaying
                ? const Icon(Icons.equalizer_rounded, color: AppColors.marigold)
                : null,
            onTap: () => _playTrack(index),
          ),
        );
      },
    );
  }
}
