import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
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
                    children: [
                      // Decoys sit behind the real stones and never respond
                      // to a tap (docs/PROGRESSION_PLAN.md §5.3).
                      for (final decoy in _decoys)
                        Positioned(
                          left: (decoy['x'] as double) * constraints.maxWidth - 24,
                          top: (decoy['y'] as double) * constraints.maxHeight - 24,
                          child: IgnorePointer(child: _buildDecoy()),
                        ),
                      for (final entry in _nodes.asMap().entries)
                        Positioned(
                          left: (entry.value['x'] as double) * constraints.maxWidth - 28,
                          top: (entry.value['y'] as double) * constraints.maxHeight - 28,
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
          ),
        ],
      ),
    );
  }

  /// A plain, unlabelled stone that does nothing when tapped
  /// (docs/PROGRESSION_PLAN.md §5.3).
  Widget _buildDecoy() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.wovenMat,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 2),
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
