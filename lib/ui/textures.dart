import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'motion.dart';

/// The surfaces the app is built on.
///
/// A flat fill is what makes an app look like a template. Everything here
/// gives the page something of the material the app is named for: dyed cotton,
/// warm light, thread. It stays quiet enough to read large text over.

/// A slow wash of warm light behind a screen: two or three soft pools of
/// colour that drift, like sun moving across a room. One cycle takes about a
/// minute, so it is felt rather than watched.
class LivingBackground extends StatefulWidget {
  const LivingBackground({
    super.key,
    required this.child,
    this.tint,
    this.intensity = 1,
  });

  final Widget child;

  /// The screen's own colour, pulled into the wash.
  final Color? tint;

  /// 0 keeps the page plain; 1 is the normal amount of colour.
  final double intensity;

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 64),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.stillness(context)) {
      _drift.value = 0.3;
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.tint ?? AppColors.terracotta;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) => CustomPaint(
                painter: _WashPainter(
                  t: _drift.value,
                  tint: tint,
                  intensity: widget.intensity,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: const _ThreadPainter()),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _WashPainter extends CustomPainter {
  const _WashPainter({required this.t, required this.tint, required this.intensity});

  final double t;
  final Color tint;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.pageBackground);
    if (intensity <= 0) return;

    final a = t * 2 * math.pi;
    final pools = <(Offset, double, Color)>[
      (
        Offset(size.width * (0.18 + 0.12 * math.sin(a)),
            size.height * (0.12 + 0.05 * math.cos(a * 0.8))),
        size.width * 0.85,
        tint.withValues(alpha: 0.20 * intensity),
      ),
      (
        Offset(size.width * (0.86 + 0.10 * math.cos(a * 0.7)),
            size.height * (0.30 + 0.07 * math.sin(a * 1.1))),
        size.width * 0.7,
        AppColors.marigold.withValues(alpha: 0.16 * intensity),
      ),
      (
        Offset(size.width * (0.5 + 0.16 * math.sin(a * 0.55)),
            size.height * (0.92 + 0.05 * math.cos(a))),
        size.width * 0.95,
        AppColors.leafGreen.withValues(alpha: 0.12 * intensity),
      ),
    ];

    for (final (centre, radius, colour) in pools) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [colour, colour.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WashPainter old) =>
      old.t != t || old.tint != tint || old.intensity != intensity;
}

/// The weave: barely-there warp and weft lines that give the page the grain
/// of cloth instead of the flatness of paint.
class _ThreadPainter extends CustomPainter {
  const _ThreadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final warp = Paint()
      ..color = AppColors.terracottaDeep.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), warp);
    }
    final weft = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), weft);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter oldDelegate) => false;
}

/// A panel that sits on the living background like a piece of cloth laid on a
/// table: warm white, a long soft shadow, and an optional woven edge.
class ClothPanel extends StatelessWidget {
  const ClothPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.radius = 28,
    this.tint,
    this.selvedge = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? tint;

  /// Draws the gamosa's red edge stripe down the left side.
  final bool selvedge;

  @override
  Widget build(BuildContext context) {
    final t = tint ?? AppColors.terracotta;
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: t.withValues(alpha: 0.13),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selvedge)
            SizedBox(
              width: 7,
              child: CustomPaint(painter: _SelvedgePainter(t)),
            ),
          Expanded(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

/// The woven edge of a gamosa, running down the side of a panel.
class _SelvedgePainter extends CustomPainter {
  const _SelvedgePainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colour.withValues(alpha: 0.9));
    final thread = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (double y = 4; y < size.height; y += 11) {
      canvas.drawRect(Rect.fromLTWH(2, y, size.width - 4, 3), thread);
    }
  }

  @override
  bool shouldRepaint(covariant _SelvedgePainter old) => old.colour != colour;
}

/// A large headline set over its own colour, used at the top of a screen so
/// each place in the app has a face of its own instead of a grey app bar.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.color,
    required this.child,
    this.height,
    this.trailing,
  });

  final Color color;
  final Widget child;
  final double? height;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.08)!,
              Color.lerp(color, Colors.black, 0.16)!,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _MotifPainter(color)),
              ),
            ),
            child,
            if (trailing != null) Positioned(right: 16, top: 12, child: trailing!),
          ],
        ),
      ),
    );
  }
}

/// Faint woven diamonds in the corner of a banner, the motif from the edge of
/// a gamosa, so the header carries the app's own pattern rather than a stock
/// gradient.
class _MotifPainter extends CustomPainter {
  const _MotifPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const step = 34.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = size.width * 0.52; x < size.width + step; x += step) {
        final d = step * 0.24;
        // Every other row is offset by half a step, the way a weave staggers.
        final cx = (y ~/ step).isEven ? x : x + step / 2;
        final path = Path()
          ..moveTo(cx, y - d)
          ..lineTo(cx + d, y)
          ..lineTo(cx, y + d)
          ..lineTo(cx - d, y)
          ..close();
        canvas.drawPath(path, ink);
      }
    }
    // A pair of thin rules along the bottom, as on the cloth's border.
    final rule = Paint()..color = Colors.white.withValues(alpha: 0.16);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 9, size.width, 2), rule);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 4, size.width, 1), rule);
  }

  @override
  bool shouldRepaint(covariant _MotifPainter old) => old.colour != colour;
}
