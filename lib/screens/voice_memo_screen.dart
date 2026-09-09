import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/files/file_paths.dart';
import '../core/repo/memo_repo.dart';

/// Screen allowing the elder to record voice memos and listen to previous recordings.
///
/// Large accessible record/stop button with warm audio playback list.
/// Adheres strictly to AGENTS.md rule #9 (no sync/upload/diagnostic indicators).
class VoiceMemoScreen extends StatefulWidget {
  const VoiceMemoScreen({super.key});

  @override
  State<VoiceMemoScreen> createState() => _VoiceMemoScreenState();
}

class _VoiceMemoScreenState extends State<VoiceMemoScreen> {
  final MemoRepo _memoRepo = MemoRepo(appDatabase);
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  DateTime? _recordStartTime;

  String? _currentlyPlayingId;
  PlayerState? _playerState;
  StreamSubscription? _playerStateSub;

  List<VoiceMemo> _memos = [];
  bool _loadingMemos = true;

  @override
  void initState() {
    super.initState();
    _loadMemos();
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state.processingState == ProcessingState.completed) {
            _currentlyPlayingId = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playerStateSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMemos() async {
    final memos = await _memoRepo.getMemos(limit: 20);
    if (mounted) {
      setState(() {
        _memos = memos;
        _loadingMemos = false;
      });
    }
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission needed')),
          );
        }
        return;
      }

      // Stop any audio playback first
      await _audioPlayer.stop();
      _currentlyPlayingId = null;

      final memoDir = await FilePaths.memos();
      final memoId = const Uuid().v4();
      final filePath = p.join(memoDir, '$memoId.m4a');

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      _recordStartTime = DateTime.now();
      _recordSeconds = 0;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordSeconds = timer.tick;
          });
        }
      });

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    final elapsedMs = _recordStartTime != null
        ? DateTime.now().difference(_recordStartTime!).inMilliseconds
        : _recordSeconds * 1000;

    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    if (path != null && File(path).existsSync()) {
      final fileName = p.basenameWithoutExtension(path);
      final memoCompanion = VoiceMemosCompanion.insert(
        id: fileName,
        localPath: path,
        durationMs: elapsedMs,
        recordedAt: DateTime.now().millisecondsSinceEpoch,
        contextTag: const drift.Value('elder_note'),
      );

      await _memoRepo.insertMemo(memoCompanion);
      await _loadMemos();
    }
  }

  Future<void> _playMemo(VoiceMemo memo) async {
    try {
      if (_currentlyPlayingId == memo.id && _audioPlayer.playing) {
        await _audioPlayer.pause();
        setState(() {});
        return;
      }

      final file = File(memo.localPath);
      if (!file.existsSync()) {
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(memo.localPath);
      setState(() {
        _currentlyPlayingId = memo.id;
      });
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Playback error: $e');
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatMemoDate(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$h:${dt.minute.toString().padLeft(2, '0')} $period';
    if (isToday) {
      return 'Today at $timeStr';
    }
    return '${dt.day}/${dt.month} at $timeStr';
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
              child: Row(
                children: [
                  // Left panel: Record action
                  Expanded(
                    flex: 4,
                    child: _buildRecordPanel(),
                  ),
                  Container(
                    width: 1.5,
                    color: AppColors.border,
                  ),
                  // Right panel: Memo list
                  Expanded(
                    flex: 5,
                    child: _buildMemosList(),
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
            onTap: () async {
              if (_isRecording) {
                await _stopRecording();
              }
              await _audioPlayer.stop();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.terracotta.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.terracotta, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '🎙️  Voice Notes',
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

  Widget _buildRecordPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _toggleRecord,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isRecording ? 140 : 120,
              height: _isRecording ? 140 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? AppColors.recordingDot : AppColors.terracotta,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? AppColors.recordingDot : AppColors.terracotta)
                        .withValues(alpha: 0.4),
                    blurRadius: _isRecording ? 30 : 16,
                    spreadRadius: _isRecording ? 6 : 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: _isRecording ? 64 : 54,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isRecording ? 'Recording...' : 'Tap to Record',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _isRecording ? AppColors.recordingDot : AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRecording
                ? _formatDuration(_recordSeconds)
                : 'Leave a message or thought',
            style: TextStyle(
              fontSize: _isRecording ? 28 : 16,
              fontWeight: _isRecording ? FontWeight.w800 : FontWeight.w500,
              color: _isRecording ? AppColors.recordingDot : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemosList() {
    if (_loadingMemos) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.terracotta),
      );
    }

    if (_memos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none_rounded, size: 64, color: AppColors.border),
            SizedBox(height: 12),
            Text(
              'No voice notes yet.',
              style: TextStyle(fontSize: 18, color: AppColors.secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _memos.length,
      itemBuilder: (context, index) {
        final memo = _memos[index];
        final isPlayingThis =
            _currentlyPlayingId == memo.id && (_playerState?.playing ?? false);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isPlayingThis
                ? AppColors.terracotta.withValues(alpha: 0.1)
                : AppColors.raisedSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPlayingThis ? AppColors.terracotta : AppColors.border,
              width: isPlayingThis ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _playMemo(memo),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlayingThis ? AppColors.terracotta : AppColors.terracotta.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isPlayingThis ? Colors.white : AppColors.terracotta,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatMemoDate(memo.recordedAt),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration((memo.durationMs / 1000).round()),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
