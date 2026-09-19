import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A strip of hand-woven cloth. Each cell of [pattern] is a square of woven
/// thread in one of [colors]; [type] picks the motif worked into every cell.
/// Fringe hangs from both ends, like the end of a gamosa or a phanek.
class WovenStrip extends StatelessWidget {
  const WovenStrip({
    super.key,
    required this.pattern,
    required this.colors,
    required this.type,
    this.cell = 40,
  });

  final List<int> pattern;
  final List<int> colors;
  final String type;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final fringe = cell * 0.28;
    return CustomPaint(
      size: Size(pattern.length * cell + fringe * 2, cell + 10),
      painter: _WovenPainter(
        cells: [for (final i in pattern) Color(colors[i % colors.length])],
        type: type,
        cell: cell,
        fringe: fringe,
      ),
    );
  }
}

class _WovenPainter extends CustomPainter {
  _WovenPainter({
    required this.cells,
    required this.type,
    required this.cell,
    required this.fringe,
  });

  final List<Color> cells;
  final String type;
  final double cell;
  final double fringe;

  @override
  void paint(Canvas canvas, Size size) {
    final cloth = Rect.fromLTWH(fringe, 2, cells.length * cell, cell);

    // Shadow the cloth casts.
    canvas.drawRRect(
      RRect.fromRectAndRadius(cloth.shift(const Offset(0, 4)), const Radius.circular(4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Fringe: loose threads at both ends.
    final threads = math.max(6, (cell / 4).round());
    for (final left in [true, false]) {
      final c = left ? cells.first : cells.last;
      final x0 = left ? cloth.left : cloth.right;
      final dir = left ? -1.0 : 1.0;
      for (var i = 0; i < threads; i++) {
        final y = cloth.top + (i + 0.5) * cloth.height / threads;
        final len = fringe * (0.75 + 0.25 * ((i * 7) % 3) / 2);
        canvas.drawLine(
          Offset(x0, y),
          Offset(x0 + dir * len, y + ((i.isEven) ? 1.5 : -1.5)),
          Paint()
            ..color = Color.lerp(c, Colors.white, 0.35)!
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(cloth, const Radius.circular(3)));

    for (var i = 0; i < cells.length; i++) {
      final r = Rect.fromLTWH(cloth.left + i * cell, cloth.top, cell, cell);
      _paintCell(canvas, r, cells[i]);
    }

    // Weave texture across the whole strip: weft lines and warp lines.
    final weft = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var y = cloth.top + 1.5; y < cloth.bottom; y += 3) {
      canvas.drawLine(Offset(cloth.left, y), Offset(cloth.right, y), weft);
    }
    final warp = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var x = cloth.left + 1.5; x < cloth.right; x += 3) {
      canvas.drawLine(Offset(x, cloth.top), Offset(x, cloth.bottom), warp);
    }

    // Gentle roundness: darker at the top and bottom edges.
    canvas.drawRect(
      cloth,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.16),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.18),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(cloth),
    );
    canvas.restore();
  }

  void _paintCell(Canvas canvas, Rect r, Color color) {
    canvas.drawRect(r, Paint()..color = color);

    // A slightly lighter weft thread picks out the motif.
    final motif = Color.lerp(color, Colors.white, 0.55)!;
    final ink = Paint()
      ..color = motif
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.2, cell * 0.07)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = motif;
    final c = r.center;
    final m = cell * 0.26;

    switch (type) {
      case 'diamonds':
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - m)
            ..lineTo(c.dx + m, c.dy)
            ..lineTo(c.dx, c.dy + m)
            ..lineTo(c.dx - m, c.dy)
            ..close(),
          ink,
        );
        canvas.drawCircle(c, cell * 0.05, fill);
      case 'zigzag':
        final p = Path()..moveTo(r.left + cell * 0.12, c.dy + m * 0.6);
        for (var k = 1; k <= 4; k++) {
          p.lineTo(r.left + cell * (0.12 + 0.19 * k), c.dy + (k.isOdd ? -m * 0.6 : m * 0.6));
        }
        canvas.drawPath(p, ink);
      case 'dots':
        for (final o in [const Offset(-1, -1), const Offset(1, -1), const Offset(-1, 1), const Offset(1, 1)]) {
          canvas.drawCircle(c + o * (cell * 0.16), cell * 0.06, fill);
        }
      case 'crosses':
        canvas.drawLine(c + Offset(-m, -m), c + Offset(m, m), ink);
        canvas.drawLine(c + Offset(m, -m), c + Offset(-m, m), ink);
      case 'chevron':
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - m, c.dy - m * 0.4)
            ..lineTo(c.dx, c.dy + m * 0.6)
            ..lineTo(c.dx + m, c.dy - m * 0.4),
          ink,
        );
      default: // stripes
        for (var k = -1; k <= 1; k++) {
          final x = c.dx + k * cell * 0.22;
          canvas.drawLine(Offset(x, r.top + cell * 0.14), Offset(x, r.bottom - cell * 0.14), ink);
        }
    }

    // Thin dark seam between neighbouring colour blocks.
    canvas.drawLine(
      r.topLeft,
      r.bottomLeft,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _WovenPainter old) =>
      old.type != type || old.cell != cell || old.cells != cells;
}
