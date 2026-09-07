import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../cognitive_game.dart';
import 'sounds_home_game.dart';

/// Playable Sounds of Home widget.
///
/// 90-second continuous performance test. Village sounds play at irregular
/// intervals. Elder taps the drum when they hear the target (bird).
/// Fully usable with significant visual impairment.
class SoundsHomeWidget extends StatefulWidget {
  const SoundsHomeWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final SoundsHomeGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<SoundsHomeWidget> createState() => _SoundsHomeWidgetState();
}

class _SoundsHomeWidgetState extends State<SoundsHomeWidget>
    with TickerProviderStateMixin {
  late final List<Map<String, Object>> _stimuli;
  late final int _durationSeconds;

  String _currentSound = '';
  bool _isTarget = false;

  int _hits = 0;
  int _misses = 0;
  int _falseAlarms = 0;
  final List<int> _reactionTimes = [];
  final List<List<int>> _blockHits = [[], [], []];
  final List<List<int>> _blockRts = [[], [], []];

  DateTime? _stimulusShownAt;
  bool _respondedToCurrentStimulus = false;
  bool _taskComplete = false;

  Timer? _timer;
  Timer? _stimulusTimer;
  int _elapsedSeconds = 0;

  late AnimationController _pulseController;
  late AnimationController _drumController;

  @override
  void initState() {
    super.initState();
    _stimuli = (widget.item.payload['stimuli'] as List<Object?>)
        .cast<Map<String, Object>>();
    _durationSeconds =
        widget.item.payload['durationSeconds'] as int? ?? 90;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _drumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Start the task
    _startTask();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stimulusTimer?.cancel();
    _pulseController.dispose();
    _drumController.dispose();
    super.dispose();
  }

  void _startTask() {
    // Main timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _durationSeconds) {
        timer.cancel();
        _finishTask();
      }
    });

    // Schedule stimuli
    for (final stimulus in _stimuli) {
      final timeMs = stimulus['timeMs'] as int;
      _stimulusTimer = Timer(Duration(milliseconds: timeMs), () {
        if (!mounted || _taskComplete) return;
        _showStimulus(stimulus);
      });
    }
  }

  void _showStimulus(Map<String, Object> stimulus) {
    final isTarget = stimulus['isTarget'] as bool;
    final sound = stimulus['sound'] as String;

    // If previous target was not responded to, count as miss
    if (_isTarget && !_respondedToCurrentStimulus) {
      _misses++;
    }

    setState(() {
      _currentSound = sound;
      _isTarget = isTarget;
      _respondedToCurrentStimulus = false;
      _stimulusShownAt = DateTime.now();
    });

    _pulseController.forward(from: 0);

    // Clear stimulus after 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _currentSound == sound) {
        setState(() => _currentSound = '');
      }
    });
  }

  void _onDrumTap() {
    if (_taskComplete) return;

    _drumController.forward(from: 0);

    if (_isTarget && !_respondedToCurrentStimulus) {
      // Hit!
      _respondedToCurrentStimulus = true;
      _hits++;
      final rt = _stimulusShownAt != null
          ? DateTime.now().difference(_stimulusShownAt!).inMilliseconds
          : 500;
      _reactionTimes.add(rt);

      // Block tracking
      final block = _elapsedSeconds < 30
          ? 0
          : (_elapsedSeconds < 60 ? 1 : 2);
      _blockHits[block].add(1);
      _blockRts[block].add(rt);
    } else if (!_isTarget) {
      // False alarm
      _falseAlarms++;
    }
  }

  void _finishTask() {
    if (_taskComplete) return;
    setState(() => _taskComplete = true);

    // Calculate RT standard deviation
    double rtSd = 0;
    if (_reactionTimes.length > 1) {
      final mean = _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
      final variance = _reactionTimes
              .map((rt) => pow(rt - mean, 2))
              .reduce((a, b) => a + b) /
          _reactionTimes.length;
      rtSd = sqrt(variance);
    }

    widget.game.submit(
      item: widget.item,
      hits: _hits,
      misses: _misses,
      falseAlarms: _falseAlarms,
      rtStdDev: rtSd,
      blockHits: _blockHits.map((b) => b.length).toList(),
      blockRt: _blockRts.map((b) {
        if (b.isEmpty) return 0.0;
        return b.reduce((a, c) => a + c) / b.length;
      }).toList(),
      initiationMs: 0,
      movementMs: _durationSeconds * 1000,
    );

    Future.delayed(const Duration(milliseconds: 800), widget.onComplete);
  }

  String _emojiForSound(String sound) {
    const map = {
      'bird': '🐦',
      'rain': '🌧️',
      'wind': '💨',
      'cow': '🐄',
      'dog': '🐕',
      'river': '🌊',
      'thunder': '⛈️',
      'cricket': '🦗',
      'bell': '🔔',
      'rooster': '🐓',
      'temple_bell': '🛕',
    };
    return map[sound] ?? '🔊';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _durationSeconds - _elapsedSeconds;
    final progress = _elapsedSeconds / _durationSeconds;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C5F2D), // Forest green
            Color(0xFF1B3A1D),
            Color(0xFF0D1F0E),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.green.shade200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.green.shade900,
                valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),

            // Instruction
            Text(
              'Tap the drum when you hear the bird 🐦',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade100,
              ),
            ),
            const SizedBox(height: 20),

            // Current sound display
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: _currentSound.isNotEmpty
                      ? 1.0 - _pulseController.value * 0.3
                      : 0.3,
                  child: Text(
                    _currentSound.isNotEmpty
                        ? _emojiForSound(_currentSound)
                        : '...',
                    style: const TextStyle(fontSize: 60),
                  ),
                );
              },
            ),

            const Spacer(),

            // Drum button
            if (!_taskComplete)
              GestureDetector(
                onTap: _onDrumTap,
                child: AnimatedBuilder(
                  animation: _drumController,
                  builder: (context, child) {
                    final scale = 1.0 - _drumController.value * 0.1;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.brown.shade400,
                              Colors.brown.shade700,
                              Colors.brown.shade900,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.amber.shade600,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.music_note,
                                size: 40, color: Colors.amber.shade200),
                            const SizedBox(height: 4),
                            Text(
                              'TAP',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Column(
                children: [
                  const Icon(Icons.check_circle,
                      size: 60, color: AppColors.leafGreen),
                  const SizedBox(height: 12),
                  Text(
                    'Hits: $_hits  Misses: $_misses',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green.shade200,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
