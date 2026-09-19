import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A clay oil lamp (diya). When [lit] a flame flickers above the wick and
/// throws a warm glow; unlit it is a dark, quiet clay bowl.
class DiyaLamp extends StatefulWidget {
  const DiyaLamp({super.key, required this.lit, this.tapped = false, this.size = 92});

  final bool lit;
  final bool tapped;
  final double size;

  @override
  State<DiyaLamp> createState() => _DiyaLampState();
}

class _DiyaLampState extends State<DiyaLamp> with SingleTickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.lit) _flicker.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant DiyaLamp old) {
    super.didUpdateWidget(old);
    if (widget.lit && !_flicker.isAnimating) {
      _flicker.repeat(reverse: true);
    } else if (!widget.lit && _flicker.isAnimating) {
      _flicker.stop();
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _flicker,
        builder: (context, _) => CustomPaint(
          painter: _DiyaPainter(
            lit: widget.lit,
            tapped: widget.tapped,
            flicker: still ? 0.5 : _flicker.value,
          ),
        ),
      ),
    );
  }
}

class _DiyaPainter extends CustomPainter {
  _DiyaPainter({required this.lit, required this.tapped, required this.flicker});

  final bool lit;
  final bool tapped;
  final double flicker;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final bowlTop = h * 0.60;
    final bowlW = w * 0.80;

    // Warm glow on the surface and in the air.
    if (lit) {
      final glowR = w * (0.95 + 0.06 * flicker);
      canvas.drawCircle(
        Offset(cx, h * 0.52),
        glowR,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFB347).withValues(alpha: 0.55),
            const Color(0xFFFF7A1A).withValues(alpha: 0.18),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: Offset(cx, h * 0.52), radius: glowR)),
      );
    }

    // Soft shadow under the lamp.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.93), width: bowlW * 1.05, height: h * 0.10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Clay bowl: a half-round body with a flat base.
    final body = Path()
      ..moveTo(cx - bowlW / 2, bowlTop)
      ..quadraticBezierTo(cx - bowlW / 2, h * 0.93, cx - bowlW * 0.18, h * 0.93)
      ..lineTo(cx + bowlW * 0.18, h * 0.93)
      ..quadraticBezierTo(cx + bowlW / 2, h * 0.93, cx + bowlW / 2, bowlTop)
      ..close();
    final clayLight = lit ? const Color(0xFFD9743F) : const Color(0xFF8E4A2C);
    final clayDark = lit ? const Color(0xFF7A2E14) : const Color(0xFF4A2214);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [clayLight, clayDark],
        ).createShader(Rect.fromLTWH(cx - bowlW / 2, bowlTop, bowlW, h * 0.35)),
    );

    // A pale decorative band around the bowl.
    canvas.drawPath(
      Path()
        ..moveTo(cx - bowlW * 0.44, h * 0.72)
        ..quadraticBezierTo(cx, h * 0.80, cx + bowlW * 0.44, h * 0.72),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF2D9A8).withValues(alpha: lit ? 0.7 : 0.35),
    );

    // Rim and the dark pool of oil.
    final rim = Rect.fromCenter(center: Offset(cx, bowlTop), width: bowlW, height: h * 0.16);
    canvas.drawOval(
      rim,
      Paint()..color = lit ? const Color(0xFFE79A5E) : const Color(0xFF9C5B3A),
    );
    canvas.drawOval(
      rim.deflate(4),
      Paint()
        ..shader = RadialGradient(colors: [
          lit ? const Color(0xFFFFC46B) : const Color(0xFF2A160C),
          const Color(0xFF2A160C),
        ]).createShader(rim),
    );

    // Pointed spout (where the wick rests), typical of a diya.
    final spout = Path()
      ..moveTo(cx + bowlW * 0.34, bowlTop - h * 0.02)
      ..lineTo(cx + bowlW * 0.58, bowlTop - h * 0.07)
      ..lineTo(cx + bowlW * 0.40, bowlTop + h * 0.05)
      ..close();
    canvas.drawPath(spout, Paint()..color = lit ? const Color(0xFFD9743F) : const Color(0xFF7A3E24));

    // Wick.
    final wickBase = Offset(cx, bowlTop - h * 0.01);
    canvas.drawLine(
      wickBase,
      Offset(cx, bowlTop - h * 0.11),
      Paint()
        ..color = const Color(0xFF1A1008)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    if (lit) {
      // Flame: a teardrop that sways a little.
      final sway = (flicker - 0.5) * w * 0.05;
      final base = Offset(cx, bowlTop - h * 0.10);
      final tipY = base.dy - h * (0.30 + 0.03 * flicker);
      final flame = Path()
        ..moveTo(base.dx, tipY)
        ..cubicTo(base.dx + w * 0.16 + sway, base.dy - h * 0.16, base.dx + w * 0.13, base.dy, base.dx, base.dy + h * 0.01)
        ..cubicTo(base.dx - w * 0.13, base.dy, base.dx - w * 0.16 + sway, base.dy - h * 0.16, base.dx, tipY)
        ..close();
      canvas.drawPath(
        flame,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: const [Color(0xFFFF6A00), Color(0xFFFFB300), Color(0xFFFFF3B0)],
          ).createShader(Rect.fromLTRB(base.dx - w * 0.16, tipY, base.dx + w * 0.16, base.dy)),
      );
      // Bright core.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(base.dx, base.dy - h * 0.05), width: w * 0.07, height: h * 0.13),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    // A small marigold petal under lamps the elder has already tapped.
    if (tapped) {
      final petalC = Offset(cx, h * 0.985);
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / 5;
        canvas.drawCircle(
          petalC + Offset(math.cos(a), math.sin(a)) * 5,
          3.2,
          Paint()..color = const Color(0xFFFFC21A),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DiyaPainter old) =>
      old.lit != lit || old.tapped != tapped || old.flicker != flicker;
}

/// Night-time festival backdrop: deep indigo sky fading to warm dark earth,
/// a scatter of stars and a faint rangoli on the ground.
class FestivalNightBackdrop extends StatelessWidget {
  const FestivalNightBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(painter: _NightPainter(), size: Size.infinite),
    );
  }
}

class _NightPainter extends CustomPainter {
  const _NightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141B33), Color(0xFF1F2440), Color(0xFF3A2620)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    final rnd = math.Random(7);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (var i = 0; i < 38; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.5),
        rnd.nextDouble() * 1.3 + 0.4,
        star,
      );
    }

    // Faint rangoli on the ground.
    final c = Offset(size.width / 2, size.height * 0.93);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFFB347).withValues(alpha: 0.13);
    for (final r in [size.width * 0.16, size.width * 0.28, size.width * 0.40]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: r * 2, height: r * 0.7), line);
    }
    for (var i = 0; i < 16; i++) {
      final a = i * 2 * math.pi / 16;
      final p1 = c + Offset(math.cos(a) * size.width * 0.16, math.sin(a) * size.width * 0.056);
      final p2 = c + Offset(math.cos(a) * size.width * 0.40, math.sin(a) * size.width * 0.14);
      canvas.drawLine(p1, p2, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
