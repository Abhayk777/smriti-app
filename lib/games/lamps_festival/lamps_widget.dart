import 'dart:async';

import 'package:flutter/material.dart';

import '../cognitive_game.dart';
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

  Timer? _sequenceTimer;

  @override
  void initState() {
    super.initState();
    _lamps = (widget.item.payload['lamps'] as List<Object?>)
        .cast<Map<String, Object>>();
    _sequence =
        (widget.item.payload['sequence'] as List<Object?>).cast<int>();
    _direction = widget.item.payload['direction'] as String;

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

    // Light for 600ms, dark for 200ms, then next
    _sequenceTimer = Timer(const Duration(milliseconds: 600), () {
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status text
            Text(
              _phase == 'watching'
                  ? 'Watch the lamps light up...'
                  : _phase == 'tapping'
                      ? _direction == 'backward'
                          ? 'Now tap them in REVERSE order'
                          : 'Now tap them in the same order'
                      : 'Well done!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
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

                      return Positioned(
                        left: x - 30,
                        top: y - 30,
                        child: GestureDetector(
                          onTap: () => _onLampTap(idx),
                          child: _buildLamp(isLit, isTapped),
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
    );
  }

  Widget _buildLamp(bool isLit, bool isTapped) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isLit
              ? [
                  Colors.amber.shade300,
                  Colors.orange.shade600,
                  Colors.orange.shade900,
                ]
              : [
                  Colors.amber.shade900.withValues(alpha: 0.4),
                  Colors.brown.shade900.withValues(alpha: 0.3),
                ],
        ),
        boxShadow: isLit
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.6),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
              ]
            : [],
        border: Border.all(
          color: isTapped
              ? Colors.amber.shade300
              : Colors.amber.shade800.withValues(alpha: 0.5),
          width: isTapped ? 2.5 : 1.5,
        ),
      ),
      child: isLit
          ? const Icon(Icons.local_fire_department,
              color: Colors.white, size: 28)
          : Icon(Icons.circle,
              color: Colors.amber.shade800.withValues(alpha: 0.3), size: 12),
    );
  }
}
