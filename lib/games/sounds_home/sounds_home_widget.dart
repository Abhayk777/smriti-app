import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import 'sounds_home_game.dart';

/// Playable Sounds of Home widget.
///
/// 90-second continuous performance test. Real recordings of village sounds
/// (bundled in `assets/sounds/`, credits in `CREDITS.md` there) play at
/// irregular intervals. The elder taps the drum when they hear the bird.
///
/// Before the timed part starts, the elder can listen to the bird as often as
/// they like; the 90 seconds only begin when they tap Start.
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

/// How each sound looks on screen while it plays.
class _SoundLook {
  const _SoundLook(this.label, this.icon, this.color);

  final String label;

  /// Null draws the bird silhouette.
  final IconData? icon;
  final Color color;
}

const _looks = <String, _SoundLook>{
  'bird': _SoundLook('Bird', null, AppColors.marigold),
  'rain': _SoundLook('Rain', Icons.water_drop_rounded, Color(0xFF8FB3D9)),
  'wind': _SoundLook('Wind', Icons.air_rounded, Color(0xFFB8C7C9)),
  'cow': _SoundLook('Cow', Icons.graphic_eq_rounded, Color(0xFFD9B38C)),
  'dog': _SoundLook('Dog', Icons.pets_rounded, Color(0xFFD9A68C)),
  'river': _SoundLook('River', Icons.waves_rounded, Color(0xFF7FB7B9)),
  'thunder': _SoundLook('Thunder', Icons.thunderstorm_rounded, Color(0xFFB9A6D1)),
  'cricket': _SoundLook('Cricket', Icons.grass_rounded, Color(0xFFA9C78F)),
  'bell': _SoundLook('Bell', Icons.notifications_rounded, Color(0xFFE3C07A)),
  'rooster': _SoundLook('Rooster', Icons.graphic_eq_rounded, Color(0xFFE39A7A)),
  'temple_bell': _SoundLook('Temple bell', Icons.temple_hindu_rounded, Color(0xFFE3B36F)),
};

class _SoundsHomeWidgetState extends State<SoundsHomeWidget>
    with TickerProviderStateMixin {
  late final List<Map<String, Object>> _stimuli;
  late final int _durationSeconds;

  bool _started = false;
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
  final List<Timer> _stimulusTimers = [];
  int _elapsedSeconds = 0;

  /// One preloaded player per sound, so a sound starts the moment it is due.
  final Map<String, AudioPlayer> _players = {};

  late AnimationController _pulseController;
  late AnimationController _drumController;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _stimuli = (widget.item.payload['stimuli'] as List<Object?>)
        .cast<Map<String, Object>>();
    _durationSeconds =
        widget.item.payload['durationSeconds'] as int? ?? 90;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _drumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _preloadSounds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final t in _stimulusTimers) {
      t.cancel();
    }
    for (final player in _players.values) {
      player.dispose();
    }
    _pulseController.dispose();
    _drumController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _preloadSounds() async {
    final names = {
      SoundsHomeGame.targetSound,
      for (final s in _stimuli) s['sound'] as String,
    };
    for (final name in names) {
      try {
        final player = AudioPlayer();
        _players[name] = player;
        await player.setAsset('assets/sounds/$name.mp3');
      } catch (e) {
        debugPrint('Sounds of Home: could not load $name: $e');
      }
    }
  }

  Future<void> _playSound(String name) async {
    final player = _players[name];
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      debugPrint('Sounds of Home: could not play $name: $e');
    }
  }

  Future<void> _previewBird() async {
    setState(() => _currentSound = SoundsHomeGame.targetSound);
    _pulseController.forward(from: 0);
    await _playSound(SoundsHomeGame.targetSound);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && !_started) setState(() => _currentSound = '');
    });
  }

  void _start() {
    if (_started) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _started = true;
      _currentSound = '';
    });
    _startTask();
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
      _stimulusTimers.add(Timer(Duration(milliseconds: timeMs), () {
        if (!mounted || _taskComplete) return;
        _showStimulus(stimulus);
      }));
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

    _playSound(sound);
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

    HapticFeedback.lightImpact();
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

  static const _ground = Color(0xFF24422D);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ground,
      child: _started ? _buildTask(context) : _buildIntro(context),
    );
  }

  // ── Intro ──────────────────────────────────────────────────────────────────

  Widget _buildIntro(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;
    final playing = _currentSound.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.listenForBird(lang),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.soundsHomeIntro(lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  color: AppColors.onColor.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 28),
              _buildSoundBubble(
                SoundsHomeGame.targetSound,
                _looks[SoundsHomeGame.targetSound]!,
                active: playing,
                size: 150,
                lang: lang,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 68,
                child: OutlinedButton.icon(
                  onPressed: _previewBird,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onColor,
                    side: const BorderSide(color: AppColors.marigold, width: 2.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(Icons.volume_up_rounded, size: 32),
                  label: Text(
                    AppStrings.hearTheBird(lang),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 76,
                child: ElevatedButton.icon(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.marigold,
                    foregroundColor: AppColors.primaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 40),
                  label: Text(
                    AppStrings.start(lang),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Timed task ─────────────────────────────────────────────────────────────

  Widget _buildTask(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;
    final isCompact = MediaQuery.of(context).size.height < 500;
    final remaining = _durationSeconds - _elapsedSeconds;
    final progress = _elapsedSeconds / _durationSeconds;
    final drumSize = isCompact ? 120.0 : 190.0;
    final look = _looks[_currentSound];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isCompact ? 8 : 20),
      child: Column(
        children: [
          // Timer
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.onColor, size: 26),
              const SizedBox(width: 8),
              Text(
                '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: isCompact ? 22 : 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.marigold),
                    minHeight: 10,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 18),

          // Instruction
          Text(
            AppStrings.tapDrumWhenHearBird(lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 19 : 23,
              fontWeight: FontWeight.w700,
              color: AppColors.onColor.withValues(alpha: 0.92),
            ),
          ),
          const Spacer(),

          // Current sound display
          SizedBox(
            height: isCompact ? 110 : 170,
            child: Center(
              child: look == null
                  ? Icon(
                      Icons.hearing_rounded,
                      size: isCompact ? 44 : 64,
                      color: AppColors.onColor.withValues(alpha: 0.35),
                    )
                  : _buildSoundBubble(_currentSound, look, active: true, size: isCompact ? 96 : 140, lang: lang),
            ),
          ),

          const Spacer(),

          // Drum button
          if (!_taskComplete)
            Semantics(
              button: true,
              label: 'Drum',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _onDrumTap(),
                child: AnimatedBuilder(
                  animation: _drumController,
                  builder: (context, child) {
                    final t = _drumController.value;
                    final scale = 1.0 - sin(t * pi) * 0.08;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: _buildDrum(drumSize, lang),
                ),
              ),
            )
          else
            const PopIn(
              child: Icon(Icons.check_circle_rounded,
                  size: 72, color: AppColors.onColor),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDrum(double size, String lang) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.marigold,
      ),
      padding: EdgeInsets.all(size * 0.06),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.terracottaDark,
        ),
        padding: EdgeInsets.all(size * 0.08),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.terracotta,
            border: Border.all(color: AppColors.onColor.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: size * 0.24, color: AppColors.onColor),
              Text(
                AppStrings.drumTap(lang),
                style: TextStyle(
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A round badge for a sound, with rings rippling out while it plays.
  Widget _buildSoundBubble(String soundId, _SoundLook look, {required bool active, required double size, required String lang}) {
    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, _) {
                final t = _ringController.value;
                return Container(
                  width: size * (1 + t * 0.5),
                  height: size * (1 + t * 0.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: look.color.withValues(alpha: (1 - t) * 0.8),
                      width: 4,
                    ),
                  ),
                );
              },
            ),
          ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: _pulseController, curve: Curves.easeOutBack),
            ),
            child: look.icon == null
                ? Container(
                    width: size,
                    height: size,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: look.color,
                      boxShadow: [
                        BoxShadow(
                          color: look.color.withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ItemPhoto(id: 'game_sounds', emoji: '🐦'),
                        const PhotoScrim(strength: 0.6),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: size * 0.12,
                          child: Text(
                            AppStrings.soundLabel(lang, soundId),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: (size * 0.14).clamp(14.0, 22.0),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: look.color),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(look.icon, size: size * 0.42, color: _ground),
                  Text(
                    AppStrings.soundLabel(lang, soundId),
                    style: TextStyle(
                      fontSize: (size * 0.14).clamp(14.0, 22.0),
                      fontWeight: FontWeight.w800,
                      color: _ground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

