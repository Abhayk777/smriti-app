import 'package:flutter/material.dart';

import '../../app_colors.dart';

// ---------------------------------------------------------------------------
// A friendly pointing hand
// ---------------------------------------------------------------------------

/// A pointing hand with a gamosa-red sleeve. The fingertip is at [tip], so the
/// stage can place the fingertip exactly on a target.
class DemoHand extends StatelessWidget {
  const DemoHand({super.key, this.width = 92});

  final double width;

  static const double aspect = 1.45;

  /// Fingertip position as a fraction of the hand's size.
  static const Offset tip = Offset(0.38, 0.03);

  Offset get tipOffset => Offset(width * tip.dx, width * aspect * tip.dy);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * aspect),
      painter: const _HandPainter(),
    );
  }
}

class _HandPainter extends CustomPainter {
  const _HandPainter();

  static const _skin = Color(0xFFEDB78E);
  static const _skinLight = Color(0xFFF8D6B6);
  static const _skinShade = Color(0xFFC98C63);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);

    canvas.drawOval(
      const Rect.fromLTWH(14, 118, 70, 16),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    Paint skin(Rect r) => Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_skinLight, _skin, _skinShade],
        stops: [0.0, 0.55, 1.0],
      ).createShader(r);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = _skinShade.withValues(alpha: 0.75);

    const palm = Rect.fromLTWH(14, 66, 70, 62);
    canvas.drawRRect(RRect.fromRectAndRadius(palm, const Radius.circular(26)), skin(palm));

    for (final k in const [
      Rect.fromLTWH(48, 58, 16, 30),
      Rect.fromLTWH(62, 62, 15, 28),
      Rect.fromLTWH(74, 68, 13, 24),
    ]) {
      final rr = RRect.fromRectAndRadius(k, const Radius.circular(8));
      canvas.drawRRect(rr, skin(k));
      canvas.drawRRect(rr, line);
    }

    final thumb = Path()
      ..moveTo(18, 100)
      ..cubicTo(2, 96, 2, 74, 14, 68)
      ..cubicTo(22, 64, 30, 72, 32, 84)
      ..close();
    canvas.drawPath(thumb, skin(const Rect.fromLTWH(2, 64, 30, 40)));
    canvas.drawPath(thumb, line);

    const finger = Rect.fromLTWH(28, 4, 22, 92);
    final fingerRR = RRect.fromRectAndRadius(finger, const Radius.circular(11));
    canvas.drawRRect(fingerRR, skin(finger));
    canvas.drawRRect(fingerRR, line);
    canvas.drawLine(const Offset(33, 52), const Offset(45, 52), line);
    canvas.drawLine(const Offset(33, 60), const Offset(45, 60), line);
    final nail = RRect.fromRectAndRadius(
      const Rect.fromLTWH(32, 6, 14, 17),
      const Radius.circular(7),
    );
    canvas.drawRRect(nail, Paint()..color = const Color(0xFFFBE3D3));

    const cuff = Rect.fromLTWH(10, 118, 78, 27);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        cuff,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      ),
      Paint()..color = AppColors.gamosaRed,
    );
    canvas.drawRect(const Rect.fromLTWH(10, 126, 78, 3), Paint()..color = AppColors.marigold);
    canvas.drawRect(
      const Rect.fromLTWH(10, 132, 78, 1.6),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// An expanding golden ring where the hand taps.
class DemoRipple extends StatelessWidget {
  const DemoRipple({super.key, required this.progress, this.size = 72});

  /// 0 (just tapped) to 1 (gone).
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final d = size * (0.4 + 0.9 * progress);
    return IgnorePointer(
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.marigold.withValues(alpha: 0.32 * (1 - progress)),
          boxShadow: [
            BoxShadow(
              color: AppColors.marigold.withValues(alpha: 0.55 * (1 - progress)),
              blurRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
