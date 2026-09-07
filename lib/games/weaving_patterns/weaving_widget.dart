import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../cognitive_game.dart';
import 'weaving_game.dart';

/// Playable Weaving Patterns widget.
///
/// Shows a Manipuri textile pattern at top and four options below.
/// Elder picks the matching one. Patterns are procedurally generated
/// using colored blocks in various arrangements.
class WeavingWidget extends StatefulWidget {
  const WeavingWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final WeavingGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<WeavingWidget> createState() => _WeavingWidgetState();
}

class _WeavingWidgetState extends State<WeavingWidget> {
  DateTime? _shownAt;
  DateTime? _firstTapAt;
  bool _answered = false;

  late final List<int> _targetPattern;
  late final String _patternType;
  late final List<Map<String, Object>> _options;
  late final List<int> _colors;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _targetPattern =
        (widget.item.payload['targetPattern'] as List<Object?>).cast<int>();
    _patternType = widget.item.payload['patternType'] as String;
    _options = (widget.item.payload['options'] as List<Object?>)
        .cast<Map<String, Object>>();
    _colors = (widget.item.payload['colors'] as List<Object?>).cast<int>();
  }

  void _onOptionTap(String optionId) {
    if (_answered) return;
    _firstTapAt ??= DateTime.now();
    setState(() => _answered = true);

    final now = DateTime.now();
    widget.game.submit(
      item: widget.item,
      chosenId: optionId,
      initiationMs: _firstTapAt!.difference(_shownAt!).inMilliseconds,
      movementMs: now.difference(_firstTapAt!).inMilliseconds,
    );

    Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Which pattern matches?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 24),

          // Target pattern (large)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.marigold, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.marigold.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: _buildPattern(_targetPattern, size: 36),
          ),
          const SizedBox(height: 30),

          // Options
          if (!_answered)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _options.map((option) {
                  final optionPattern =
                      (option['pattern'] as List<Object?>).cast<int>();
                  final optionId = option['id'] as String;
                  return GestureDetector(
                    onTap: () => _onOptionTap(optionId),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.raisedSurface,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildPattern(optionPattern, size: 24),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Icon(Icons.check_circle,
                    size: 60, color: AppColors.leafGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPattern(List<int> pattern, {double size = 30}) {
    // Render pattern as a row of colored blocks with textile-like styling
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pattern.asMap().entries.map((entry) {
        final colorIdx = entry.value;
        final color = Color(_colors[colorIdx % _colors.length]);
        final isEven = entry.key.isEven;

        Widget block;
        switch (_patternType) {
          case 'diamonds':
            block = Transform.rotate(
              angle: 0.785, // 45 degrees
              child: Container(
                width: size * 0.7,
                height: size * 0.7,
                color: color,
              ),
            );
          case 'zigzag':
            block = CustomPaint(
              size: Size(size, size),
              painter: _ZigzagPainter(color: color, goUp: isEven),
            );
          case 'dots':
            block = Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            );
          case 'crosses':
            block = SizedBox(
              width: size,
              height: size,
              child: Icon(Icons.close, color: color, size: size * 0.8),
            );
          case 'chevron':
            block = CustomPaint(
              size: Size(size, size),
              painter: _ChevronPainter(color: color),
            );
          default: // stripes
            block = Container(
              width: size,
              height: size,
              color: color,
            );
        }

        return Padding(
          padding: const EdgeInsets.all(2),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: block),
          ),
        );
      }).toList(),
    );
  }
}

class _ZigzagPainter extends CustomPainter {
  _ZigzagPainter({required this.color, required this.goUp});
  final Color color;
  final bool goUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (goUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height * 0.4)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.6)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height * 0.6)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
