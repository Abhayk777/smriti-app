import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../core/speech/speech_input.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import '../hint/game_hint.dart';
import '../ui/game_chrome.dart';
import 'name_harvest_game.dart';

/// Playable Name the Harvest widget.
///
/// A category fluency task: "tell me all the fruits you can think of". The
/// elder **speaks**, which is how the task is meant to be given; every word
/// heard becomes a card on the screen. Typing is kept as a quiet second way in
/// for a caregiver, or for a phone whose microphone is unavailable, but it is
/// never the first thing the elder is asked to do.
class NameHarvestWidget extends StatefulWidget {
  const NameHarvestWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
    this.speech,
  });

  final NameHarvestGame game;
  final GameItem item;
  final VoidCallback onComplete;

  /// Overridden in tests so nothing reaches the microphone.
  final SpeechInput? speech;

  @override
  State<NameHarvestWidget> createState() => _NameHarvestWidgetState();
}

class _NameHarvestWidgetState extends State<NameHarvestWidget>
    with TickerProviderStateMixin {
  final List<String> _namedItems = [];
  final TextEditingController _textController = TextEditingController();
  late final SpeechInput _speech = widget.speech ?? SpeechInput();

  int _remainingSeconds = 60;
  bool _taskComplete = false;
  bool _started = false;
  bool _listening = false;
  bool _typing = false;
  bool _micUnavailable = false;

  /// What is being said right now, shown greyed until it settles.
  String _partial = '';

  /// Set for a moment when a word was already given, so the screen can say so
  /// kindly instead of silently dropping it.
  String? _repeatedWord;
  Timer? _repeatTimer;

  Timer? _timer;
  DateTime? _startedAt;

  late final AnimationController _ringController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void dispose() {
    _timer?.cancel();
    _repeatTimer?.cancel();
    _textController.dispose();
    _ringController.dispose();
    _pulse.dispose();
    unawaited(_speech.cancel());
    super.dispose();
  }

  // ── The round ────────────────────────────────────────────────────────────

  void _start() {
    if (_started) return;
    setState(() {
      _started = true;
      _startedAt = DateTime.now();
    });
    _ringController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _finishTask();
      }
    });
    unawaited(_toggleListening());
  }

  Future<void> _toggleListening() async {
    if (_taskComplete) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
        _pulse.stop();
      }
      return;
    }

    final ok = await _speech.listen(
      onWords: _onWordsHeard,
      localeId: _localeForSpeech(LocaleController.instance.currentLanguage),
    );
    if (!mounted) return;
    setState(() {
      _listening = ok;
      _micUnavailable = !ok;
      if (!ok) _typing = true;
    });
    if (ok) {
      _pulse.repeat(reverse: true);
    }
  }

  /// A phrase from the recogniser. Everything before the last word has
  /// settled, so those words are banked and the last one is left showing as
  /// the one still being said.
  void _onWordsHeard(String words, bool isFinal) {
    if (!mounted || _taskComplete) return;
    final parts = words.split(RegExp(r'[,\s]+')).where((w) => w.trim().isNotEmpty).toList();
    if (parts.isEmpty) return;

    final settled = isFinal ? parts : parts.sublist(0, parts.length - 1);
    for (final word in settled) {
      _record(word);
    }
    setState(() => _partial = isFinal ? '' : parts.last);

    if (isFinal && _listening && !_taskComplete) {
      // The recogniser stops itself after a pause; pick it back up so the
      // elder can keep going without touching anything.
      unawaited(_restartListening());
    }
  }

  Future<void> _restartListening() async {
    final ok = await _speech.listen(
      onWords: _onWordsHeard,
      localeId: _localeForSpeech(LocaleController.instance.currentLanguage),
    );
    if (mounted && !ok) {
      setState(() => _listening = false);
      _pulse.stop();
    }
  }

  /// Banks one answer, unless it is one already given.
  void _record(String word) {
    final clean = word.trim();
    if (clean.isEmpty || _taskComplete) return;
    if (NameHarvestGame.isRepeatOf(clean, _namedItems)) {
      setState(() => _repeatedWord = clean);
      _repeatTimer?.cancel();
      _repeatTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _repeatedWord = null);
      });
      return;
    }
    setState(() => _namedItems.add(clean));
  }

  void _addTyped() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _record(text);
    _textController.clear();
  }

  void _finishTask() {
    if (_taskComplete) return;
    setState(() {
      _taskComplete = true;
      _listening = false;
      _partial = '';
    });
    _pulse.stop();
    unawaited(_speech.stop());

    final totalMs = DateTime.now().difference(_startedAt ?? DateTime.now()).inMilliseconds;
    widget.game.submit(
      item: widget.item,
      itemsNamed: _namedItems,
      initiationMs: 0,
      movementMs: totalMs,
    );

    Future.delayed(const Duration(milliseconds: 900), widget.onComplete);
  }

  static String _localeForSpeech(String lang) {
    switch (lang) {
      case 'hi':
        return 'hi_IN';
      case 'bn':
        return 'bn_IN';
      case 'as':
        return 'as_IN';
      case 'ne':
        return 'ne_NP';
      default:
        return 'en_IN';
    }
  }

  // ── Screen ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;
    final category = widget.item.payload['category'] as String;
    final isCompact = MediaQuery.of(context).size.height < 500;
    final categoryName = AppStrings.harvestCategory(lang, category);
    final promptText = AppStrings.nameAllCategoryPrompt(lang, categoryName);

    return Padding(
      padding: EdgeInsets.fromLTRB(18, isCompact ? 6 : 12, 18, isCompact ? 8 : 16),
      child: Column(
        children: [
          GamePrompt(
            promptText,
            icon: Icons.record_voice_over_rounded,
            color: AppColors.orchid,
          ),
          SizedBox(height: isCompact ? 10 : 18),

          if (!_started)
            Expanded(child: _buildOpening(isCompact, lang))
          else ...[
            _buildStatusRow(isCompact, lang),
            SizedBox(height: isCompact ? 8 : 14),
            Expanded(child: _buildAnswers(isCompact, lang)),
            SizedBox(height: isCompact ? 6 : 12),
            if (!_taskComplete) _buildControls(isCompact, lang),
          ],
        ],
      ),
    );
  }

  /// Before the clock starts: one large button, and nothing else to decide.
  Widget _buildOpening(bool isCompact, String lang) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconMedallion(
              icon: Icons.mic_rounded,
              color: AppColors.orchid,
              size: isCompact ? 96 : 140,
              background: AppColors.orchid.withValues(alpha: 0.14),
            ),
            SizedBox(height: isCompact ? 16 : 26),
            HintGlow(
              isAnswer: true,
              radius: 24,
              child: SizedBox(
                width: double.infinity,
                height: isCompact ? 60 : 72,
                child: ElevatedButton.icon(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orchid,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 34),
                  label: Text(
                    AppStrings.start(lang),
                    style: TextStyle(
                      fontSize: isCompact ? 20 : 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The clock, how many answers are in, and what is being heard right now.
  Widget _buildStatusRow(bool isCompact, String lang) {
    final ring = SizedBox(
      width: isCompact ? 52 : 66,
      height: isCompact ? 52 : 66,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, _) => CircularProgressIndicator(
              value: 1.0 - _ringController.value,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.orchid.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation(
                _remainingSeconds > 10 ? AppColors.orchid : AppColors.terracotta,
              ),
            ),
          ),
          Text(
            '$_remainingSeconds',
            style: TextStyle(
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: _remainingSeconds > 10 ? AppColors.primaryText : AppColors.terracottaDark,
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        ring,
        const SizedBox(width: Insets.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.itemsNamed(lang, _namedItems.length),
                style: TextStyle(
                  fontSize: isCompact ? 17 : 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              if (_partial.isNotEmpty)
                Text(
                  _partial,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 15 : 18,
                    fontStyle: FontStyle.italic,
                    color: AppColors.secondaryText,
                  ),
                )
              else if (_listening)
                _SoundBars(animation: _pulse, color: AppColors.orchid),
            ],
          ),
        ),
      ],
    );
  }

  /// Every answer given, newest first, with the just-repeated one called out
  /// gently rather than dropped in silence.
  Widget _buildAnswers(bool isCompact, String lang) {
    if (_namedItems.isEmpty) {
      return Center(
        child: Text(
          _listening
              ? AppStrings.nameHarvestListening(lang)
              : AppStrings.typeAnItem(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 17 : 20,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    final reversed = _namedItems.reversed.toList();
    return SingleChildScrollView(
      reverse: true,
      child: Column(
        children: [
          if (_repeatedWord != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Text(
                AppStrings.nameHarvestAlreadySaid(lang, _repeatedWord!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < reversed.length; i++)
                PopIn(
                  key: ValueKey('${reversed[i]}_$i'),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 16,
                      vertical: isCompact ? 8 : 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.leafGreen,
                      borderRadius: BorderRadius.circular(Radii.md),
                      boxShadow: Shadows.card(AppColors.leafGreen),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          reversed[i],
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The microphone, and the quiet way to type instead.
  Widget _buildControls(bool isCompact, String lang) {
    return Column(
      children: [
        if (_typing) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: isCompact ? 17 : 20,
                    color: AppColors.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.typeAnItem(lang),
                    filled: true,
                    fillColor: AppColors.raisedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: BorderSide(
                        color: AppColors.orchid.withValues(alpha: 0.65),
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _addTyped(),
                ),
              ),
              const SizedBox(width: Insets.sm),
              SizedBox(
                width: isCompact ? 52 : 60,
                height: isCompact ? 52 : 60,
                child: ElevatedButton(
                  onPressed: _addTyped,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orchid,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.add_rounded, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
        ],
        Row(
          children: [
            if (!_micUnavailable)
              Expanded(
                child: SizedBox(
                  height: isCompact ? 58 : 70,
                  child: ElevatedButton.icon(
                    onPressed: _toggleListening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _listening ? AppColors.terracotta : AppColors.orchid,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.lg),
                      ),
                    ),
                    icon: Icon(
                      _listening ? Icons.pause_rounded : Icons.mic_rounded,
                      size: 30,
                    ),
                    label: Text(
                      _listening
                          ? AppStrings.nameHarvestPause(lang)
                          : AppStrings.nameHarvestSpeak(lang),
                      style: TextStyle(
                        fontSize: isCompact ? 18 : 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            if (!_micUnavailable && !_typing) const SizedBox(width: Insets.sm),
            if (!_typing)
              SizedBox(
                height: isCompact ? 58 : 70,
                child: OutlinedButton(
                  onPressed: () => setState(() => _typing = true),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 22),
                  ),
                  child: const Icon(Icons.keyboard_rounded, size: 28),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Three bars that rise and fall while the microphone is open, so the elder
/// can see they are being heard.
class _SoundBars extends StatelessWidget {
  const _SoundBars({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final phase in const [0.0, 0.35, 0.7])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 5,
                    height: 6 + 12 * (0.5 + 0.5 * ((t + phase) % 1.0 - 0.5).abs() * 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
