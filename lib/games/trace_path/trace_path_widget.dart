import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../cognitive_game.dart';
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

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _nodes = (widget.item.payload['nodes'] as List<Object?>)
        .cast<Map<String, Object>>();
    _variant = widget.item.payload['variant'] as String;
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            _variant == 'A'
                ? 'Tap the stones in order: 1, 2, 3...'
                : 'Tap alternating: 1, A, 2, B, 3, C...',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  painter: _ConnectionPainter(
                    nodes: _nodes,
                    tappedOrder: _tappedOrder,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                  child: Stack(
                    children: _nodes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final node = entry.value;
                      final x = (node['x'] as double) * constraints.maxWidth;
                      final y = (node['y'] as double) * constraints.maxHeight;
                      final isTapped = _tappedOrder.contains(idx);
                      final isNext = idx == _nextExpected;

                      return Positioned(
                        left: x - 28,
                        top: y - 28,
                        child: GestureDetector(
                          onTap: () => _onNodeTap(idx),
                          child: _buildNode(
                            node['label'] as String,
                            node['type'] as String,
                            isTapped,
                            isNext,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(
      String label, String type, bool isTapped, bool isNext) {
    Color bgColor;
    Color borderColor;
    if (isTapped) {
      bgColor = AppColors.leafGreen;
      borderColor = AppColors.leafGreenDark;
    } else if (isNext) {
      bgColor = AppColors.marigold;
      borderColor = AppColors.marigoldDark;
    } else {
      bgColor = type == 'number'
          ? AppColors.raisedSurface
          : AppColors.medicineBlush;
      borderColor = AppColors.border;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.marigold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isTapped ? AppColors.onColor : AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

/// Draws connection lines between tapped nodes.
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

    final paint = Paint()
      ..color = AppColors.leafGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < tappedOrder.length - 1; i++) {
      final from = nodes[tappedOrder[i]];
      final to = nodes[tappedOrder[i + 1]];

      canvas.drawLine(
        Offset((from['x'] as double) * width, (from['y'] as double) * height),
        Offset((to['x'] as double) * width, (to['y'] as double) * height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) =>
      oldDelegate.tappedOrder.length != tappedOrder.length;
}
