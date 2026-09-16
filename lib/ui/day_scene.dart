import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A hill landscape that follows the real time of day.
///
/// The sky moves through dawn, day, golden hour, sunset and night; the sun
/// travels across the sky between sunrise and sunset and a crescent moon with
/// stars takes over after dark. Layered ridges fade into haze with distance,
/// as the blue hills of the North-East do, above a tea-garden slope. Clouds
/// drift slowly, mist lies in the valleys in the morning, and a few birds
/// cross the sky by day.
///
/// The landscape occupies the bottom [landHeight] pixels; the rest is sky, so
/// text can sit above the hills without overlapping them.
class DayScene extends StatefulWidget {
  const DayScene({super.key, required this.now, this.landHeight = 120});

  final DateTime now;
  final double landHeight;

  /// Whether text drawn over the sky at [now] should be light.
  static bool prefersLightText(DateTime now) {
    final top = _SkyClock.at(now.hour * 60 + now.minute).top;
    return top.computeLuminance() < 0.3;
  }

  @override
  State<DayScene> createState() => _DaySceneState();
}

class _DaySceneState extends State<DayScene>
    with SingleTickerProviderStateMixin {
  // One slow loop drives cloud drift, birds and twinkling stars.
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _drift.stop();
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
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _DayScenePainter(
              minute: widget.now.hour * 60 + widget.now.minute,
              landHeight: widget.landHeight,
              drift: _drift.value,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sky colours through the day
// ---------------------------------------------------------------------------

class _SkyKey {
  const _SkyKey(this.minute, this.top, this.horizon);

  final int minute;
  final Color top;
  final Color horizon;
}

class _SkyClock {
  // Sunrise and sunset in the North-East are early; around 5:20 and 17:50
  // through much of the year.
  static const sunrise = 320;
  static const sunset = 1070;
  static const moonrise = 1130;
  static const moonset = 270 + 1440;

  static const _keys = [
    _SkyKey(0, Color(0xFF0D1433), Color(0xFF1F2A55)),
    _SkyKey(270, Color(0xFF121B40), Color(0xFF2A3563)),
    _SkyKey(320, Color(0xFF4A5189), Color(0xFFE9A57F)),
    _SkyKey(380, Color(0xFF8DB6E3), Color(0xFFF7DDB6)),
    _SkyKey(480, Color(0xFF9CC5EC), Color(0xFFDDEFF8)),
    _SkyKey(720, Color(0xFF93C1EE), Color(0xFFE3F2FA)),
    _SkyKey(930, Color(0xFF9DC3E8), Color(0xFFEEF1E6)),
    _SkyKey(1020, Color(0xFFA9B7DD), Color(0xFFF6D29A)),
    _SkyKey(1075, Color(0xFF5F63A0), Color(0xFFEE9A6E)),
    _SkyKey(1130, Color(0xFF2A2F66), Color(0xFF7A5578)),
    _SkyKey(1220, Color(0xFF111A3E), Color(0xFF2A3360)),
    _SkyKey(1440, Color(0xFF0D1433), Color(0xFF1F2A55)),
  ];

  static ({Color top, Color horizon}) at(int minute) {
    final m = minute.clamp(0, 1439);
    for (var i = 0; i < _keys.length - 1; i++) {
      final a = _keys[i];
      final b = _keys[i + 1];
      if (m >= a.minute && m <= b.minute) {
        final t = (m - a.minute) / (b.minute - a.minute);
        return (
          top: Color.lerp(a.top, b.top, t)!,
          horizon: Color.lerp(a.horizon, b.horizon, t)!,
        );
      }
    }
    return (top: _keys.first.top, horizon: _keys.first.horizon);
  }

  /// 0 in full daylight, 1 in full night.
  static double nightness(Color top) =>
      (1 - (top.computeLuminance() / 0.45)).clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _DayScenePainter extends CustomPainter {
  _DayScenePainter({
    required this.minute,
    required this.landHeight,
    required this.drift,
  });

  final int minute;
  final double landHeight;
  final double drift;

  static const _nightInk = Color(0xFF0B1220);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final land = math.min(landHeight, h * 0.7);
    final horizonY = h - land * 0.62;

    final sky = _SkyClock.at(minute);
    final night = _SkyClock.nightness(sky.top);

    // Sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.top, sky.horizon],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, horizonY + land * 0.2)),
    );

    if (night > 0.05) _paintStars(canvas, w, horizonY, night);
    _paintMoon(canvas, w, horizonY, sky.top, night);
    _paintSun(canvas, w, horizonY);
    _paintClouds(canvas, w, horizonY, sky, night);
    if (night < 0.4) _paintBirds(canvas, w, horizonY, night);

    // Ridges, far to near. Distant ridges take on the sky colour (haze).
    _paintRidge(canvas, size,
        base: h - land * 0.62, amp: land * 0.20, seed: 1,
        color: const Color(0xFF7F9BB8), haze: 0.55, night: night, horizon: sky.horizon);
    _paintMist(canvas, w, h - land * 0.50, land, night);
    _paintRidge(canvas, size,
        base: h - land * 0.46, amp: land * 0.18, seed: 2,
        color: const Color(0xFF5C8578), haze: 0.30, night: night, horizon: sky.horizon);
    _paintRidge(canvas, size,
        base: h - land * 0.30, amp: land * 0.14, seed: 3,
        color: const Color(0xFF3F6A4A), haze: 0.12, night: night, horizon: sky.horizon,
        trees: true);
    _paintTeaGarden(canvas, size, land, night, sky.horizon);
  }

  Color _shade(Color c, double haze, double night, Color horizon) {
    final hazed = Color.lerp(c, horizon, haze)!;
    return Color.lerp(hazed, _nightInk, night * 0.72)!;
  }

  double _ridgeY(double x, double w, double base, double amp, int seed) {
    final f = 2 * math.pi / w;
    final p = seed * 1.7;
    final n = 0.55 * math.sin(x * f * (1.1 + seed * 0.23) + p) +
        0.30 * math.sin(x * f * (2.7 + seed * 0.41) + p * 2.3) +
        0.15 * math.sin(x * f * (6.3 + seed * 0.7) + p * 0.7);
    return base - amp * (0.5 + 0.5 * n);
  }

  void _paintRidge(
    Canvas canvas,
    Size size, {
    required double base,
    required double amp,
    required int seed,
    required Color color,
    required double haze,
    required double night,
    required Color horizon,
    bool trees = false,
  }) {
    final w = size.width;
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= w; x += 3) {
      path.lineTo(x, _ridgeY(x, w, base, amp, seed));
    }
    path
      ..lineTo(w, size.height)
      ..close();
    final fill = _shade(color, haze, night, horizon);
    final ridgePaint = Paint()..color = fill;
    if (haze > 0.4) {
      // The farthest ridge is slightly out of focus.
      ridgePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    }
    canvas.drawPath(path, ridgePaint);

    if (trees) {
      // A few slender trees along the crest.
      final treePaint = Paint()..color = Color.lerp(fill, _nightInk, 0.25)!;
      final th = amp * 0.9;
      for (final fx in const [0.08, 0.13, 0.71, 0.76, 0.93]) {
        final x = w * fx;
        final y = _ridgeY(x, w, base, amp, seed) + 2;
        final tree = Path()
          ..moveTo(x, y - th)
          ..lineTo(x + th * 0.22, y)
          ..lineTo(x - th * 0.22, y)
          ..close();
        canvas.drawPath(tree, treePaint);
      }
    }
  }

  void _paintTeaGarden(Canvas canvas, Size size, double land, double night, Color horizon) {
    final w = size.width;
    final h = size.height;
    final top = h - land * 0.16;
    final slope = Path()
      ..moveTo(0, top + land * 0.04)
      ..quadraticBezierTo(w * 0.45, top - land * 0.06, w, top + land * 0.02)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final base = _shade(const Color(0xFF4F7F36), 0.04, night, horizon);
    canvas.drawPath(slope, Paint()..color = base);

    // Rows of rounded tea bushes following the slope.
    final bush = Paint()..color = Color.lerp(base, const Color(0xFF9BC46A), 0.28 * (1 - night))!;
    const rows = 3;
    for (var r = 0; r < rows; r++) {
      final rowY = top + land * (0.035 + r * 0.05);
      final radius = land * (0.018 + r * 0.006);
      for (double x = radius; x < w; x += radius * 2.6) {
        final curve = -land * 0.05 * math.sin(math.pi * x / w) * (1 - r / rows);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, rowY + curve),
            width: radius * 2.4,
            height: radius * 1.3,
          ),
          bush,
        );
      }
    }
  }

  void _paintSun(Canvas canvas, double w, double horizonY) {
    if (minute < _SkyClock.sunrise - 15 || minute > _SkyClock.sunset + 15) return;
    final p = ((minute - _SkyClock.sunrise) / (_SkyClock.sunset - _SkyClock.sunrise))
        .clamp(0.0, 1.0);
    final elevation = math.sin(math.pi * p);
    // East on the left, west on the right; kept to the right side of the sky
    // at midday so the greeting text stays clear.
    final x = w * (0.40 + 0.52 * p);
    final top = horizonY * 0.18;
    final y = horizonY - (horizonY - top) * elevation;
    final r = math.max(12.0, math.min(w, horizonY) * 0.09);

    final core = Color.lerp(const Color(0xFFF08A3C), const Color(0xFFFFE7A3), elevation)!;
    canvas.drawCircle(
      Offset(x, y),
      r * 3.2,
      Paint()
        ..shader = RadialGradient(
          colors: [core.withValues(alpha: 0.35), core.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r * 3.2)),
    );
    canvas.drawCircle(Offset(x, y), r, Paint()..color = core);
  }

  void _paintMoon(Canvas canvas, double w, double horizonY, Color skyTop, double night) {
    final m = minute < _SkyClock.moonrise ? minute + 1440 : minute;
    if (m < _SkyClock.moonrise || m > _SkyClock.moonset || night < 0.3) return;
    final p = (m - _SkyClock.moonrise) / (_SkyClock.moonset - _SkyClock.moonrise);
    final elevation = math.sin(math.pi * p);
    final x = w * (0.40 + 0.52 * p);
    final y = horizonY - (horizonY - horizonY * 0.2) * elevation;
    final r = math.max(10.0, math.min(w, horizonY) * 0.07);

    canvas.drawCircle(
      Offset(x, y),
      r * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF3EED6).withValues(alpha: 0.18 * night),
            const Color(0xFFF3EED6).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r * 3)),
    );
    canvas.saveLayer(Rect.fromCircle(center: Offset(x, y), radius: r * 1.2), Paint());
    canvas.drawCircle(Offset(x, y), r, Paint()..color = const Color(0xFFF3EED6));
    canvas.drawCircle(
      Offset(x + r * 0.45, y - r * 0.2),
      r * 0.9,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  void _paintStars(Canvas canvas, double w, double horizonY, double night) {
    final rnd = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 45; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * horizonY * 0.85;
      final phase = rnd.nextDouble() * math.pi * 2;
      final twinkle = 0.6 + 0.4 * math.sin(drift * math.pi * 2 * 20 + phase);
      paint.color = Colors.white.withValues(alpha: night * twinkle * 0.85);
      canvas.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble() * 1.1, paint);
    }
  }

  void _paintClouds(
    Canvas canvas,
    double w,
    double horizonY,
    ({Color top, Color horizon}) sky,
    double night,
  ) {
    final day = Color.lerp(Colors.white, sky.horizon, 0.25)!;
    final color = Color.lerp(day, const Color(0xFF3A4468), night)!;
    final alpha = 0.85 - night * 0.55;
    const clouds = [
      (0.10, 0.30, 1.0, 1.0),
      (0.55, 0.16, 0.7, 1.6),
      (0.85, 0.42, 0.85, 1.25),
    ];
    for (final (bx, by, scale, speed) in clouds) {
      final span = w * 1.4;
      final x = ((bx * w + drift * speed * span) % span) - w * 0.2;
      final y = horizonY * by;
      final s = math.max(18.0, w * 0.06) * scale;
      // Soft edges read as cloud rather than a drawn shape.
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.22);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - s * 1.6, y, s * 3.4, s * 0.8),
        Radius.circular(s * 0.4),
      );
      canvas.drawRRect(rrect, paint);
      canvas.drawCircle(Offset(x - s * 0.5, y + s * 0.05), s * 0.62, paint);
      canvas.drawCircle(Offset(x + s * 0.45, y - s * 0.1), s * 0.8, paint);
    }
  }

  void _paintBirds(Canvas canvas, double w, double horizonY, double night) {
    if (minute < _SkyClock.sunrise + 30 || minute > _SkyClock.sunset - 20) return;
    final paint = Paint()
      ..color = const Color(0xFF2E3440).withValues(alpha: 0.7 * (1 - night))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const flock = [(0.0, 0.0, 1.0), (0.05, 0.04, 0.8), (-0.04, 0.06, 0.7)];
    final cx = ((drift * 3) % 1.2 - 0.1) * w;
    final cy = horizonY * 0.5;
    final flap = math.sin(drift * math.pi * 2 * 90);
    for (final (dx, dy, s) in flock) {
      final x = cx + dx * w;
      final y = cy + dy * horizonY;
      final span = 7.0 * s;
      final lift = span * (0.35 + 0.25 * flap);
      final path = Path()
        ..moveTo(x - span, y - lift)
        ..quadraticBezierTo(x - span * 0.4, y - lift * 0.2, x, y)
        ..quadraticBezierTo(x + span * 0.4, y - lift * 0.2, x + span, y - lift);
      canvas.drawPath(path, paint);
    }
  }

  void _paintMist(Canvas canvas, double w, double y, double land, double night) {
    // Valley mist, strongest just after sunrise.
    final morning = minute >= _SkyClock.sunrise && minute <= 600
        ? math.sin(math.pi * (minute - _SkyClock.sunrise) / (600 - _SkyClock.sunrise))
        : 0.0;
    if (morning <= 0.02) return;
    final rect = Rect.fromLTWH(0, y - land * 0.12, w, land * 0.24);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.45 * morning * (1 - night)),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _DayScenePainter old) =>
      old.minute != minute || old.drift != drift || old.landHeight != landHeight;
}
