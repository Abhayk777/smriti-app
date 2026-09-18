import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/files/file_paths.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/locale_controller.dart';
import '../core/repo/memo_repo.dart';
import '../core/sync/sync_engine.dart';
import '../ui/smriti_ui.dart';

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
  String? _currentRecordingMemoId;

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
      var hasPerm = await _audioRecorder.hasPermission();
      if (!hasPerm) {
        final status = await Permission.microphone.request();
        hasPerm = status.isGranted;
      }
      if (!hasPerm) {
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
      _currentRecordingMemoId = memoId;
      final filePath = p.join(memoDir, '$memoId.wav');

      await _audioRecorder.start(
        // WAV/PCM, not an AAC encoder: AAC recording goes through the
        // device's native MediaCodec, and which codec implementation gets
        // picked (and whether it can honor the requested stereo/sample-rate
        // config) varies by chipset — cheaper/mid-range SoCs (e.g. the
        // MediaTek chips in many Redmi phones) can silently fall onto a
        // device-specific path that produces a file that "loads" (container
        // and duration are readable) but won't actually decode elsewhere,
        // even after recording in mono. WAV is raw PCM with a plain header —
        // no codec negotiation at all, so it plays back identically on every
        // device and in every browser. Voice messages are short, so the
        // larger file size doesn't matter.
        const RecordConfig(
          encoder: AudioEncoder.wav,
          numChannels: 1,
          sampleRate: 16000,
        ),
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
      final memoId = _currentRecordingMemoId ?? p.basenameWithoutExtension(path);
      final memoCompanion = VoiceMemosCompanion.insert(
        id: memoId,
        localPath: path,
        durationMs: elapsedMs,
        recordedAt: DateTime.now().millisecondsSinceEpoch,
        contextTag: const drift.Value('message'),
      );

      await _memoRepo.insertMemo(memoCompanion);
      await _loadMemos();
      // Automatically upload memo to Supabase in background
      unawaited(() async {
        final res = await SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual);
        if (!res.ok && res.errorSummary.contains('already running')) {
          await Future.delayed(const Duration(seconds: 3));
          await SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual);
        }
      }());
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

  String _formatMemoDate(int millis, String lang) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$h:${dt.minute.toString().padLeft(2, '0')} $period';
    if (isToday) {
      return AppStrings.todayAtTime(lang, timeStr);
    }
    return '${dt.day}/${dt.month} at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final lang = LocaleController.instance.currentLanguage;
        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, lang),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 720 &&
                          constraints.maxWidth > constraints.maxHeight;
                      if (wide) {
                        return Row(
                          children: [
                            // Left panel: Record action
                            Expanded(flex: 4, child: _buildRecordPanel(lang)),
                            Container(width: 1.5, color: AppColors.border),
                            // Right panel: Memo list
                            Expanded(flex: 5, child: _buildMemosList(lang)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          SizedBox(
                            height: (constraints.maxHeight * 0.46).clamp(260.0, 380.0),
                            child: _buildRecordPanel(lang),
                          ),
                          Container(height: 1.5, color: AppColors.border),
                          Expanded(child: _buildMemosList(lang)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    return ScreenHeader(
      title: AppStrings.message(lang),
      subtitle: AppStrings.sendVoiceMessageToFamily(lang),
      icon: Icons.mic_rounded,
      color: AppColors.riverTeal,
      onBack: () async {
        if (_isRecording) {
          await _stopRecording();
        }
        await _audioPlayer.stop();
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }

  Widget _buildRecordPanel(String lang) {
    final color = _isRecording ? AppColors.recordingDot : AppColors.riverTeal;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: _isRecording ? AppStrings.tapToStop(lang) : AppStrings.tapToRecord(lang),
              child: GestureDetector(
                onTap: _toggleRecord,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 168,
                  height: 168,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 68,
                      color: AppColors.onColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? AppStrings.recording(lang) : AppStrings.tapToRecord(lang),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _isRecording ? AppColors.recordingDot : AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isRecording
                  ? _formatDuration(_recordSeconds)
                  : AppStrings.sendAVoiceMessage(lang),
              style: TextStyle(
                fontSize: _isRecording ? 30 : 18,
                fontWeight: _isRecording ? FontWeight.w800 : FontWeight.w500,
                color: _isRecording ? AppColors.recordingDot : AppColors.secondaryText,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemosList(String lang) {
    if (_loadingMemos) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.riverTeal),
      );
    }

    if (_memos.isEmpty) {
      return EmptyState(
        icon: Icons.mic_none_rounded,
        color: AppColors.riverTeal,
        title: AppStrings.noMessagesYet(lang),
      );
    }

    final gutter = Screen.gutter(context);
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 24),
      itemCount: _memos.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              AppStrings.yourVoiceMessages(lang),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          );
        }
        final memo = _memos[index - 1];
        final isPlayingThis =
            _currentlyPlayingId == memo.id && (_playerState?.playing ?? false);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: PressableCard(
            onTap: () => _playMemo(memo),
            color: isPlayingThis
                ? AppColors.riverTeal.withValues(alpha: 0.10)
                : AppColors.raisedSurface,
            borderColor: isPlayingThis ? AppColors.riverTeal : AppColors.border,
            radius: 20,
            semanticLabel: isPlayingThis ? 'Pause message' : 'Play message',
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlayingThis
                        ? AppColors.riverTeal
                        : AppColors.riverTeal.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isPlayingThis ? AppColors.onColor : AppColors.riverTeal,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatMemoDate(memo.recordedAt, lang),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration((memo.durationMs / 1000).round()),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
