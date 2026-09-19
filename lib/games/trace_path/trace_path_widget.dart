import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import '../hint/game_hint.dart';
import 'trace_path_game.dart';

/// Playable Trace the Path widget.
///
/// Shows numbered nodes (stones) scattered on a village-map background.
/// Elder taps nodes in order (TMT-A) or alternating number-letter (TMT-B).
/// Tracks errors, completion time, and connection lines.
class TracePathWidget extends StatefulWidget {
  const TracePathWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final TracePathGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<TracePathWidget> createState() => _TracePathWidgetState();
}

class _TracePathWidgetState extends State<TracePathWidget> {
  DateTime? _shownAt;
  DateTime? _firstTapAt;
  final List<int> _tappedOrder = [];
  int _errors = 0;
  bool _completed = false;

  late final List<Map<String, Object>> _nodes;
  late final String _variant;

  /// Unlabelled decoy stones (docs/PROGRESSION_PLAN.md §5.3): tapping one
  /// does nothing and is never counted as an error. Empty for items
  /// generated before this existed.
  late final List<Map<String, Object>> _decoys;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _nodes = (widget.item.payload['nodes'] as List<Object?>)
        .cast<Map<String, Object>>();
    _variant = widget.item.payload['variant'] as String;
    _decoys = (widget.item.payload['decoys'] as List<Object?>? ?? const [])
        .cast<Map<String, Object>>();
  }

  int get _nextExpected => _tappedOrder.length;

  void _onNodeTap(int index) {
    if (_completed) return;
    _firstTapAt ??= DateTime.now();

    if (index == _nextExpected) {
      setState(() {
        _tappedOrder.add(index);
      });

      // Check if all nodes tapped
      if (_tappedOrder.length >= _nodes.length) {
        _finish();
      }
    } else {
      // Wrong node — count error but don't penalise visually
      _errors++;
    }
  }

  void _finish() {
    if (_completed) return;
    setState(() => _completed = true);

    final now = DateTime.now();
    final initiationMs =
        _firstTapAt!.difference(_shownAt!).inMilliseconds;
    final movementMs = now.difference(_firstTapAt!).inMilliseconds;
    final completionMs = now.difference(_shownAt!).inMilliseconds;

    widget.game.submit(
      item: widget.item,
      completed: true,
      completionMs: completionMs,
      strokeVelocity: _nodes.length / (completionMs / 1000.0),
      lifts: 0, // Tap-based, not continuous stroke
      jitter: 0.0,
      initiationMs: initiationMs,
      movementMs: movementMs,
      errorsCount: _errors,
    );

    Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            _variant == 'A'
                ? AppStrings.tracePathSequential(lang)
                : AppStrings.tracePathAlternating(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const RepaintBoundary(child: CustomPaint(painter: _ScenePainter())),
                  LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  painter: _ConnectionPainter(
                    nodes: _nodes,
                    tappedOrder: _tappedOrder,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                  child: Stack(
                    children: [
                      // Decoys sit behind the real stones and never respond
                      // to a tap (docs/PROGRESSION_PLAN.md §5.3).
                      for (final decoy in _decoys)
                        Positioned(
                          left: (decoy['x'] as double) * constraints.maxWidth - 30,
                          top: (decoy['y'] as double) * constraints.maxHeight - 30,
                          child: IgnorePointer(child: _buildDecoy()),
                        ),
                      for (final entry in _nodes.asMap().entries)
                        Positioned(
                          left: (entry.value['x'] as double) * constraints.maxWidth - 38,
                          top: (entry.value['y'] as double) * constraints.maxHeight - 38,
                          child: BouncyTap(
                            pressedScale: 0.85,
                            onTap: () => _onNodeTap(entry.key),
                            child: _buildNode(
                              entry.value['label'] as String,
                              entry.value['type'] as String,
                              _tappedOrder.contains(entry.key),
                              entry.key == _nextExpected,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// A plain, unlabelled stone that does nothing when tapped
  /// (docs/PROGRESSION_PLAN.md §5.3).
  Widget _buildDecoy() {
    return const SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(painter: _StonePainter(seed: 7, tone: _StoneTone.plain)),
    );
  }

  Widget _buildNode(String label, String type, bool isTapped, bool isNext) {
    final tone = isTapped
        ? _StoneTone.done
        : (isNext ? _StoneTone.next : _StoneTone.plain);
    return HintGlow(
      isAnswer: isNext,
      radius: 38,
      child: SizedBox(
        width: 76,
        height: 76,
        child: CustomPaint(
          painter: _StonePainter(seed: label.hashCode, tone: tone),
          child: Center(
            child: isTapped
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 34)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isNext ? AppColors.primaryText : const Color(0xFF3B3128),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Meadow with a winding stream, pebbles and grass tufts.
class _ScenePainter extends CustomPainter {
  const _ScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCE9C4), Color(0xFFB7D19A), Color(0xFF9DBB80)],
        ).createShader(Offset.zero & size),
    );

    final stream = Path()
      ..moveTo(-20, h * 0.30)
      ..cubicTo(w * 0.30, h * 0.14, w * 0.55, h * 0.50, w * 0.80, h * 0.36)
      ..cubicTo(w * 0.95, h * 0.28, w * 1.05, h * 0.40, w * 1.10, h * 0.42);
    canvas.drawPath(
      stream,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.13
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE6D8B5),
    );
    canvas.drawPath(
      stream,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.10
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF8CC4E0), Color(0xFF5FA6CC)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      stream,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.45),
    );

    final rnd = math.Random(11);
    for (var i = 0; i < 34; i++) {
      final c = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 6 + rnd.nextDouble() * 7, height: 4 + rnd.nextDouble() * 4),
        Paint()..color = const Color(0xFF8C7F6A).withValues(alpha: 0.35),
      );
    }
    final blade = Paint()
      ..color = const Color(0xFF6E9A55).withValues(alpha: 0.65)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 30; i++) {
      final b = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      for (final dx in [-4.0, 0.0, 4.0]) {
        canvas.drawLine(b, b + Offset(dx, -9 - rnd.nextDouble() * 5), blade);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

enum _StoneTone { plain, next, done }

/// An irregular, smooth river stone with a highlight and a soft shadow.
class _StonePainter extends CustomPainter {
  const _StonePainter({required this.seed, required this.tone});

  final int seed;
  final _StoneTone tone;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final c = size.center(Offset.zero);
    final r = size.width * 0.40;
    const n = 9;
    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        c +
            Offset(math.cos(i * 2 * math.pi / n), math.sin(i * 2 * math.pi / n) * 0.84) *
                (r * (0.90 + rnd.nextDouble() * 0.16)),
    ];
    final path = Path()
      ..moveTo((pts.last.dx + pts.first.dx) / 2, (pts.last.dy + pts.first.dy) / 2);
    for (var i = 0; i < n; i++) {
      final next = pts[(i + 1) % n];
      path.quadraticBezierTo(
          pts[i].dx, pts[i].dy, (pts[i].dx + next.dx) / 2, (pts[i].dy + next.dy) / 2);
    }
    path.close();

    Color light;
    Color dark;
    switch (tone) {
      case _StoneTone.done:
        light = const Color(0xFF7DB783);
        dark = const Color(0xFF3F7A4C);
      case _StoneTone.next:
        light = const Color(0xFFFFD667);
        dark = const Color(0xFFD79E34);
        canvas.drawCircle(
          c,
          size.width * 0.52,
          Paint()
            ..color = const Color(0xFFFFC21A).withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      case _StoneTone.plain:
        light = const Color(0xFFF0E8DA);
        dark = const Color(0xFFB9AC96);
    }

    canvas.drawPath(
      path.shift(const Offset(0, 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.5),
          radius: 1.0,
          colors: [light, dark],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.3)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.35, -r * 0.42), width: r * 0.7, height: r * 0.32),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _StonePainter old) => old.tone != tone || old.seed != seed;
}

/// The trail walked so far: a dashed golden path between the stones tapped.
class _ConnectionPainter extends CustomPainter {
  _ConnectionPainter({
    required this.nodes,
    required this.tappedOrder,
    required this.width,
    required this.height,
  });

  final List<Map<String, Object>> nodes;
  final List<int> tappedOrder;
  final double width;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    if (tappedOrder.length < 2) return;
    final path = Path();
    for (var i = 0; i < tappedOrder.length; i++) {
      final n = nodes[tappedOrder[i]];
      final o = Offset((n['x'] as double) * width, (n['y'] as double) * height);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB4741A).withValues(alpha: 0.85);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 12, metric.length)), paint);
        d += 22;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) =>
      oldDelegate.tappedOrder.length != tappedOrder.length;
}
