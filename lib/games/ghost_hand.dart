import 'package:flutter/widgets.dart';

/// Stub for the ghost-hand demo: a translucent hand that traces the correct
/// gesture so the elder learns by watching rather than by reading instructions.
///
/// The actual animation is a design-layer concern (see A13). This holds only
/// the state the session runner needs — whether a demo is running, and the
/// steps it would trace — so that `playDemo` has something real to await and
/// `demoReplays` has something real to count.
class GhostHandController extends ChangeNotifier {
  GhostHandController({this.stepDuration = const Duration(milliseconds: 600)});

  final Duration stepDuration;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Normalised (0–1) points the hand moves between, in order.
  List<Offset> _path = const [];
  List<Offset> get path => _path;

  int _completedRuns = 0;
  int get completedRuns => _completedRuns;

  Future<void> play(List<Offset> path) async {
    _path = path;
    _isPlaying = true;
    notifyListeners();

    // Animate through each step
    for (var i = 0; i < path.length; i++) {
      await Future<void>.delayed(stepDuration);
    }

    _isPlaying = false;
    _completedRuns++;
    notifyListeners();
  }
}

/// Ghost hand overlay: shows a translucent finger tracing the demo path.
class GhostHandOverlay extends StatelessWidget {
  const GhostHandOverlay({super.key, required this.controller});

  final GhostHandController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isPlaying || controller.path.isEmpty) {
          return const SizedBox.expand();
        }

        return IgnorePointer(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _GhostHandPainter(
                path: controller.path,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints the ghost-hand trail: a translucent path between demonstration points.
class _GhostHandPainter extends CustomPainter {
  _GhostHandPainter({required this.path});

  final List<Offset> path;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final paint = Paint()
      ..color = const Color(0x408C8078) // ghostHand with alpha
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final drawPath = Path();
    drawPath.moveTo(path.first.dx * size.width, path.first.dy * size.height);
    for (var i = 1; i < path.length; i++) {
      drawPath.lineTo(path[i].dx * size.width, path[i].dy * size.height);
    }
    canvas.drawPath(drawPath, paint);

    // Draw hand at last point
    final lastPoint = path.last;
    final handPaint = Paint()
      ..color = const Color(0x508C8078)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(lastPoint.dx * size.width, lastPoint.dy * size.height),
      20,
      handPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GhostHandPainter oldDelegate) =>
      oldDelegate.path != path;
}
