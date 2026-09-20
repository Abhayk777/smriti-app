import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

/// Motion for Smriti.
///
/// Everything here is deliberately slow and soft. Quick, snapping or flashing
/// movement is disorienting for someone with dementia, so the app moves the
/// way cloth does: it settles rather than snaps. Nothing loops faster than
/// about once a second, nothing flashes, and every animation here stops
/// dead when the phone asks for reduced motion.
abstract final class Motion {
  /// A touch responding under the finger.
  static const fast = Duration(milliseconds: 180);

  /// Something appearing or changing on screen.
  static const medium = Duration(milliseconds: 420);

  /// A whole screen arriving.
  static const slow = Duration(milliseconds: 560);

  /// Settles into place without overshooting hard.
  static const settle = Curves.easeOutCubic;

  /// A little life on arrival, used sparingly.
  static const gentleBack = Cubic(0.34, 1.32, 0.64, 1);

  static bool stillness(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

// ---------------------------------------------------------------------------
// Screen transitions
// ---------------------------------------------------------------------------

/// How one screen gives way to the next: the old screen sinks back and fades,
/// the new one rises into its place. It reads as moving forward without the
/// sideways lurch of the default transition.
class SmritiPageRoute<T> extends PageRouteBuilder<T> {
  SmritiPageRoute({required this.child, this.settings2})
      : super(
          settings: settings2,
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.medium,
          opaque: true,
          pageBuilder: (context, animation, secondary) => child,
          transitionsBuilder: (context, animation, secondary, page) {
            if (Motion.stillness(context)) return page;

            final incoming = CurvedAnimation(parent: animation, curve: Motion.settle);
            final outgoing = CurvedAnimation(parent: secondary, curve: Motion.settle);

            return FadeTransition(
              opacity: incoming,
              child: AnimatedBuilder(
                animation: outgoing,
                child: page,
                builder: (context, inner) {
                  final sink = 1 - outgoing.value * 0.04;
                  return Transform.scale(
                    scale: sink,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.035),
                        end: Offset.zero,
                      ).animate(incoming),
                      child: inner,
                    ),
                  );
                },
              ),
            );
          },
        );

  final Widget child;
  final RouteSettings? settings2;
}

/// Pushes [screen] with the app's own transition.
Future<T?> pushSmriti<T>(BuildContext context, Widget screen) {
  return Navigator.of(context).push<T>(SmritiPageRoute<T>(child: screen));
}

// ---------------------------------------------------------------------------
// Entrances
// ---------------------------------------------------------------------------

/// Brings children in one after another, each drifting up as it fades in.
/// A list arriving all at once feels abrupt; arriving in sequence lets the
/// eye follow it down the page.
class Stagger extends StatelessWidget {
  const Stagger({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 90),
    this.start = Duration.zero,
    this.offset = 26,
  });

  final List<Widget> children;
  final Duration step;
  final Duration start;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          RiseIn(
            delay: start + step * i,
            offset: offset,
            child: children[i],
          ),
      ],
    );
  }
}

/// One element drifting up into place, once.
class RiseIn extends StatefulWidget {
  const RiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 26,
    this.duration = Motion.slow,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration + widget.delay,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      (widget.delay.inMilliseconds / (widget.duration + widget.delay).inMilliseconds)
          .clamp(0.0, 0.95),
      1,
      curve: Motion.settle,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.stillness(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Touch
// ---------------------------------------------------------------------------

/// A press that gives under the finger and comes back with a little spring,
/// with a haptic tick. Used on anything the elder taps.
class SpringTap extends StatefulWidget {
  const SpringTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.955,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.fast,
    reverseDuration: const Duration(milliseconds: 420),
    value: 0,
  );

  late final Animation<double> _press = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
    reverseCurve: Motion.gentleBack,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) => _c.forward();
  void _up([_]) => _c.reverse();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? _down : null,
        onTapUp: _up,
        onTapCancel: _up,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedBuilder(
          animation: _press,
          child: widget.child,
          builder: (context, child) => Transform.scale(
            scale: 1 - (1 - widget.scale) * _press.value,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Life on the page
// ---------------------------------------------------------------------------

/// A very slow swell, for something waiting to be touched. One breath takes
/// about three seconds, close to a resting breath.
class Breathing extends StatefulWidget {
  const Breathing({
    super.key,
    required this.child,
    this.amount = 0.03,
    this.period = const Duration(milliseconds: 3200),
  });

  final Widget child;
  final double amount;
  final Duration period;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.stillness(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scale: 1 + widget.amount * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
    );
  }
}

/// A soft band of light passing over a placeholder while real content loads.
/// Calmer than a spinner, and it shows the shape of what is coming.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 18,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.stillness(context)) {
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2 - 0.5;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t, 0),
              colors: [
                AppColors.wovenMat.withValues(alpha: 0.35),
                AppColors.wovenMat.withValues(alpha: 0.7),
                AppColors.wovenMat.withValues(alpha: 0.35),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A number that counts up to its new value instead of jumping.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(this.value, {super.key, this.style, this.suffix = ''});

  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Motion.slow,
      curve: Motion.settle,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

// ---------------------------------------------------------------------------
// Praise
// ---------------------------------------------------------------------------

/// Marigold petals drifting up and outward, for a moment worth marking.
///
/// Marigold garlands are what a celebration looks like here, so success is
/// shown with petals rather than a burst of confetti. They fall slowly, fade
/// out, and never cover what the elder is looking at.
class PetalBurst extends StatefulWidget {
  const PetalBurst({super.key, required this.play, this.count = 14});

  /// Flipped to a new value each time praise is earned.
  final int play;
  final int count;

  @override
  State<PetalBurst> createState() => _PetalBurstState();
}

class _PetalBurstState extends State<PetalBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late List<_Petal> _petals = _make(widget.play);

  List<_Petal> _make(int seed) {
    final rnd = math.Random(seed * 7919);
    return [
      for (var i = 0; i < widget.count; i++)
        _Petal(
          angle: -math.pi / 2 + (rnd.nextDouble() - 0.5) * 2.2,
          distance: 90 + rnd.nextDouble() * 150,
          spin: (rnd.nextDouble() - 0.5) * 5,
          size: 12 + rnd.nextDouble() * 12,
          delay: rnd.nextDouble() * 0.25,
          warm: rnd.nextBool(),
        ),
    ];
  }

  @override
  void didUpdateWidget(covariant PetalBurst old) {
    super.didUpdateWidget(old);
    if (old.play != widget.play) {
      _petals = _make(widget.play);
      if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _c.isDismissed
            ? const SizedBox.expand()
            : CustomPaint(
                size: Size.infinite,
                painter: _PetalPainter(_petals, _c.value),
              ),
      ),
    );
  }
}

class _Petal {
  const _Petal({
    required this.angle,
    required this.distance,
    required this.spin,
    required this.size,
    required this.delay,
    required this.warm,
  });

  final double angle;
  final double distance;
  final double spin;
  final double size;
  final double delay;
  final bool warm;
}

class _PetalPainter extends CustomPainter {
  _PetalPainter(this.petals, this.t);

  final List<_Petal> petals;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.52);
    for (final p in petals) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = Curves.easeOutCubic.transform(local);
      final drift = Offset(
        math.cos(p.angle) * p.distance * eased,
        math.sin(p.angle) * p.distance * eased + 70 * eased * eased,
      );
      final fade = (1 - Curves.easeIn.transform(local)).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(origin.dx + drift.dx, origin.dy + drift.dy);
      canvas.rotate(p.spin * eased);
      final paint = Paint()
        ..color = (p.warm ? AppColors.marigold : AppColors.terracotta)
            .withValues(alpha: 0.85 * fade);
      // A petal: two arcs meeting at a point.
      final path = Path()
        ..moveTo(0, -p.size / 2)
        ..quadraticBezierTo(p.size * 0.5, 0, 0, p.size / 2)
        ..quadraticBezierTo(-p.size * 0.5, 0, 0, -p.size / 2)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter old) => old.t != t;
}
