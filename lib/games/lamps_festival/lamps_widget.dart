import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import '../hint/game_hint.dart';
import 'diya_lamp.dart';
import 'lamps_game.dart';

/// Playable Lamps of the Festival widget.
///
/// Oil lamps arranged in irregular pattern on dark screen. They light in
/// sequence with a warm glow; elder taps them in the same (or reverse) order.
/// Language-free, literacy-independent.
class LampsWidget extends StatefulWidget {
  const LampsWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final LampsGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<LampsWidget> createState() => _LampsWidgetState();
}

class _LampsWidgetState extends State<LampsWidget> {
  // Phases: watching → tapping → done
  String _phase = 'watching';
  int _sequenceIndex = 0;
  int _currentLit = -1;
  final List<int> _tappedSequence = [];
  DateTime? _tappingStartAt;
  DateTime? _firstTapAt;

  late final List<Map<String, Object>> _lamps;
  late final List<int> _sequence;
  late final String _direction;

  /// How long each lamp stays lit while the sequence plays
  /// (docs/PROGRESSION_PLAN.md §5.3); 600ms for items generated before this
  /// existed, matching the old fixed behaviour.
  late final int _litMs;

  Timer? _sequenceTimer;

  @override
  void initState() {
    super.initState();
    _lamps = (widget.item.payload['lamps'] as List<Object?>)
        .cast<Map<String, Object>>();
    _sequence =
        (widget.item.payload['sequence'] as List<Object?>).cast<int>();
    _direction = widget.item.payload['direction'] as String;
    _litMs = widget.item.payload['litMs'] as int? ?? 600;

    // Start showing sequence after a brief delay
    Future.delayed(const Duration(milliseconds: 800), _playSequence);
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    super.dispose();
  }

  void _playSequence() {
    if (_sequenceIndex >= _sequence.length) {
      // Sequence complete, switch to tapping
      setState(() {
        _currentLit = -1;
        _phase = 'tapping';
        _tappingStartAt = DateTime.now();
      });
      return;
    }

    setState(() {
      _currentLit = _sequence[_sequenceIndex];
    });

    // Light for _litMs, dark for 300ms, then next
    _sequenceTimer = Timer(Duration(milliseconds: _litMs), () {
      if (!mounted) return;
      setState(() => _currentLit = -1);
      _sequenceTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _sequenceIndex++;
        _playSequence();
      });
    });
  }

  void _onLampTap(int index) {
    if (_phase != 'tapping') return;
    _firstTapAt ??= DateTime.now();

    setState(() {
      _tappedSequence.add(index);
      _currentLit = index;
    });

    // Brief flash
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _currentLit = -1);
    });

    // Check if enough lamps tapped
    if (_tappedSequence.length >= _sequence.length) {
      _submit();
    }
  }

  void _submit() {
    if (_phase == 'done') return;
    setState(() => _phase = 'done');

    final now = DateTime.now();
    final initiationMs = _firstTapAt != null && _tappingStartAt != null
        ? _firstTapAt!.difference(_tappingStartAt!).inMilliseconds
        : 2000;
    final movementMs = _firstTapAt != null
        ? now.difference(_firstTapAt!).inMilliseconds
        : 1000;

    widget.game.submit(
      item: widget.item,
      tappedSequence: _tappedSequence,
      initiationMs: initiationMs,
      movementMs: movementMs,
    );

    Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;
    return Stack(
      fit: StackFit.expand,
      children: [
      const FestivalNightBackdrop(),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status text
            Text(
              _phase == 'watching'
                  ? AppStrings.watchLampsLightUp(lang)
                  : _phase == 'tapping'
                      ? _direction == 'backward'
                          ? AppStrings.tapLampsReverseOrder(lang)
                          : AppStrings.tapLampsSameOrder(lang)
                      : AppStrings.wellDone(lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: Colors.amber.shade200,
              ),
            ),
            const SizedBox(height: 12),
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_sequence.length, (i) {
                final filled = _phase == 'watching'
                    ? i < _sequenceIndex
                    : i < _tappedSequence.length;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? Colors.amber
                        : Colors.amber.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Lamp field
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: _lamps.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final lamp = entry.value;
                      final x =
                          (lamp['x'] as double) * constraints.maxWidth;
                      final y =
                          (lamp['y'] as double) * constraints.maxHeight;
                      final isLit = _currentLit == idx;
                      final isTapped = _tappedSequence.contains(idx);
                      final isTarget = _phase == 'tapping' &&
                          _tappedSequence.length < _sequence.length &&
                          (_direction == 'backward'
                              ? _sequence[_sequence.length - 1 - _tappedSequence.length] == idx
                              : _sequence[_tappedSequence.length] == idx);

                      return Positioned(
                        left: x - 46,
                        top: y - 46,
                        child: BouncyTap(
                          pressedScale: 0.85,
                          onTap: () => _onLampTap(idx),
                          child: _buildLamp(isLit, isTapped, isTarget),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ],
    );
  }

  Widget _buildLamp(bool isLit, bool isTapped, bool isTarget) {
    return HintGlow(
      isAnswer: isTarget,
      radius: 46,
      child: DiyaLamp(lit: isLit, tapped: isTapped, size: 92),
    );
  }
}
