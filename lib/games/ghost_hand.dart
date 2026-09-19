import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Controller for demonstrating game gestures with a realistic animated hand.
///
/// Holds whether a demo is running, the normalized path it traces, and
/// broadcasts live animation updates to [GhostHandOverlay].
class GhostHandController extends ChangeNotifier {
  GhostHandController({
    this.stepDuration = const Duration(milliseconds: 900),
  });

  final Duration stepDuration;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  List<Offset> _path = const [];
  List<Offset> get path => _path;

  int _completedRuns = 0;
  int get completedRuns => _completedRuns;

  // Live animation state
  Offset _currentPoint = const Offset(0.5, 0.5);
  Offset get currentPoint => _currentPoint;

  bool _isPressing = false;
  bool get isPressing => _isPressing;

  double _tapRipple = 0.0;
  double get tapRipple => _tapRipple;

  bool _disposed = false;

  void updateState({
    required Offset point,
    required bool isPressing,
    required double tapRipple,
  }) {
    if (_disposed) return;
    _currentPoint = point;
    _isPressing = isPressing;
    _tapRipple = tapRipple;
    notifyListeners();
  }

  Future<void> play(List<Offset> path) async {
    if (_disposed || path.isEmpty) return;
    _path = path;
    _isPlaying = true;
    _currentPoint = path.first;
    notifyListeners();

    // Step through the points with realistic movement and tapping
    for (var i = 0; i < path.length; i++) {
      if (!_isPlaying || _disposed) break;

      // Move to target
      final target = path[i];
      _currentPoint = target;
      _isPressing = false;
      _tapRipple = 0.0;
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!_isPlaying || _disposed) break;

      // Tap down
      _isPressing = true;
      _tapRipple = 1.0;
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!_isPlaying || _disposed) break;

      // Release tap
      _isPressing = false;
      _tapRipple = 0.0;
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    _isPlaying = false;
    _completedRuns++;
    if (!_disposed) notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _isPressing = false;
    _tapRipple = 0.0;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Overlay that renders the realistic animated ghost hand tracing the demo path.
class GhostHandOverlay extends StatefulWidget {
  const GhostHandOverlay({
    super.key,
    required this.controller,
    this.onTapAnywhereToDismiss,
  });

  final GhostHandController controller;
  final VoidCallback? onTapAnywhereToDismiss;

  @override
  State<GhostHandOverlay> createState() => _GhostHandOverlayState();
}

class _GhostHandOverlayState extends State<GhostHandOverlay>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _rippleController;

  Offset _startOffset = const Offset(0.5, 0.5);
  Offset _endOffset = const Offset(0.5, 0.5);
  bool _isTapping = false;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final current = widget.controller.currentPoint;
    if (current != _endOffset) {
      _startOffset = _endOffset;
      _endOffset = current;
      _moveController.forward(from: 0.0);
    }

    if (widget.controller.isPressing && !_isTapping) {
      _isTapping = true;
      _rippleController.forward(from: 0.0);
    } else if (!widget.controller.isPressing) {
      _isTapping = false;
    }

    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _moveController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isPlaying || widget.controller.path.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTapAnywhereToDismiss,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: Listenable.merge([_moveController, _rippleController]),
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_moveController.value);
            final currentPos = Offset.lerp(_startOffset, _endOffset, t) ?? _endOffset;

            return CustomPaint(
              painter: RealisticHandPainter(
                position: currentPos,
                isPressing: _isTapping,
                rippleProgress: _rippleController.value,
                pathPoints: widget.controller.path,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for a realistic illustrated pointing finger with 3D shading,
/// contact shadow, and expanding tap ripples.
class RealisticHandPainter extends CustomPainter {
  RealisticHandPainter({
    required this.position,
    required this.isPressing,
    required this.rippleProgress,
    required this.pathPoints,
  });

  final Offset position;
  final bool isPressing;
  final double rippleProgress;
  final List<Offset> pathPoints;

  @override
  void paint(Canvas canvas, Size size) {
    final px = position.dx * size.width;
    final py = position.dy * size.height;

    // 1. Draw connecting guide dots/path if multi-point
    if (pathPoints.length > 1) {
      _drawGuidePath(canvas, size);
    }

    // 2. Draw expanding tap ripple rings if touching
    if (rippleProgress > 0 && rippleProgress < 1.0) {
      _drawTapRipples(canvas, Offset(px, py));
    }

    // 3. Draw realistic contact shadow underneath fingertip
    _drawContactShadow(canvas, Offset(px, py));

    // 4. Draw realistic 3D finger
    _drawRealisticFinger(canvas, Offset(px, py));
  }

  void _drawGuidePath(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = AppColors.marigold.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashPath = Path();
    for (var i = 0; i < pathPoints.length; i++) {
      final p = Offset(pathPoints[i].dx * size.width, pathPoints[i].dy * size.height);
      if (i == 0) {
        dashPath.moveTo(p.dx, p.dy);
      } else {
        dashPath.lineTo(p.dx, p.dy);
      }

      // Indicator ring at each waypoint
      final dotPaint = Paint()
        ..color = AppColors.terracotta.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 6, dotPaint);

      final outerDot = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(p, 6, outerDot);
    }

    canvas.drawPath(dashPath, pathPaint);
  }

  void _drawTapRipples(Canvas canvas, Offset center) {
    final p = rippleProgress;

    // Inner primary ripple
    final radius1 = 12.0 + p * 38.0;
    final alpha1 = (1.0 - p).clamp(0.0, 1.0);
    final ringPaint1 = Paint()
      ..color = Colors.white.withValues(alpha: alpha1 * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * (1.0 - p * 0.5);
    canvas.drawCircle(center, radius1, ringPaint1);

    // Inner soft glow disk
    final glowDisk = Paint()
      ..color = AppColors.marigold.withValues(alpha: alpha1 * 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius1 * 0.7, glowDisk);

    // Outer delayed gold ripple
    if (p > 0.15) {
      final p2 = (p - 0.15) / 0.85;
      final radius2 = 8.0 + p2 * 54.0;
      final alpha2 = (1.0 - p2).clamp(0.0, 1.0);
      final ringPaint2 = Paint()
        ..color = AppColors.marigold.withValues(alpha: alpha2 * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - p2 * 0.5);
      canvas.drawCircle(center, radius2, ringPaint2);
    }
  }

  void _drawContactShadow(Canvas canvas, Offset touchPoint) {
    final shadowScale = isPressing ? 0.9 : 1.15;
    final shadowAlpha = isPressing ? 0.32 : 0.18;
    final shadowOffset = isPressing ? const Offset(2, 4) : const Offset(6, 12);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isPressing ? 5 : 10);

    canvas.drawOval(
      Rect.fromCenter(
        center: touchPoint + shadowOffset,
        width: 32 * shadowScale,
        height: 18 * shadowScale,
      ),
      shadowPaint,
    );
  }

  void _drawRealisticFinger(Canvas canvas, Offset touchPoint) {
    canvas.save();

    // Subtle press-down translation & scale
    final pressOffset = isPressing ? const Offset(0, 3) : Offset.zero;
    final target = touchPoint + pressOffset;

    // Angle of finger: coming in from top/top-right at ~25 degrees
    const angle = -0.38; // radians
    canvas.translate(target.dx, target.dy);
    canvas.rotate(angle);

    final fingerWidth = 34.0;
    final fingerLength = 110.0;

    // Skin tones
    const fleshLight = Color(0xFFF1C8AC);
    const fleshBase = Color(0xFFE4AC8C);
    const fleshDark = Color(0xFFC78462);
    const fleshShadow = Color(0xFF9E5C3B);
    const nailBase = Color(0xFFFCE6DA);
    const nailShine = Color(0xFFFFFFFF);

    // 1. Draw Finger Body with apex exactly at (0, 0)
    final fingerPath = Path();
    fingerPath.moveTo(-fingerWidth * 0.45, 12);
    fingerPath.quadraticBezierTo(
      0, 0, // fingertip apex at (0, 0)
      fingerWidth * 0.45, 12,
    );
    // Shaft widening downward
    fingerPath.lineTo(fingerWidth * 0.65, fingerLength + 12);
    fingerPath.lineTo(-fingerWidth * 0.65, fingerLength + 12);
    fingerPath.close();

    // Shaded skin gradient
    final skinGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [fleshDark, fleshLight, fleshBase, fleshShadow],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(Rect.fromLTWH(-fingerWidth, -5, fingerWidth * 2, fingerLength + 25));

    final skinPaint = Paint()
      ..shader = skinGradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(fingerPath, skinPaint);

    // Finger outline for cartoon-realism definition
    final outlinePaint = Paint()
      ..color = fleshShadow.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(fingerPath, outlinePaint);

    // 2. Fingernail
    final nailRect = Rect.fromCenter(
      center: const Offset(0, 24),
      width: fingerWidth * 0.58,
      height: 24,
    );
    final nailRRect = RRect.fromRectAndRadius(nailRect, const Radius.circular(10));

    final nailGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [nailShine, nailBase, fleshDark.withValues(alpha: 0.5)],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(nailRect);

    final nailPaint = Paint()
      ..shader = nailGradient
      ..style = PaintingStyle.fill;
    canvas.drawRRect(nailRRect, nailPaint);

    // Nail outline & cuticle curve
    final nailBorderPaint = Paint()
      ..color = fleshDark.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(nailRRect, nailBorderPaint);

    // 3. Knuckle crease lines for realism
    final creasePaint = Paint()
      ..color = fleshDark.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // First joint crease
    final crease1 = Path();
    crease1.moveTo(-fingerWidth * 0.35, 54);
    crease1.quadraticBezierTo(0, 58, fingerWidth * 0.35, 54);
    canvas.drawPath(crease1, creasePaint);

    // Second joint crease
    final crease2 = Path();
    crease2.moveTo(-fingerWidth * 0.45, 90);
    crease2.quadraticBezierTo(0, 95, fingerWidth * 0.45, 90);
    canvas.drawPath(crease2, creasePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RealisticHandPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.isPressing != isPressing ||
        oldDelegate.rippleProgress != rippleProgress ||
        oldDelegate.pathPoints != pathPoints;
  }
}
