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

    // The real implementation drives an AnimationController here.
    await Future<void>.delayed(stepDuration);

    _isPlaying = false;
    _completedRuns++;
    notifyListeners();
  }
}

/// Placeholder visual. Renders nothing until the design layer replaces it.
class GhostHandOverlay extends StatelessWidget {
  const GhostHandOverlay({super.key, required this.controller});

  final GhostHandController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) =>
          IgnorePointer(child: SizedBox.expand(child: const SizedBox())),
    );
  }
}
