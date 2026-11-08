import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Verre plein (bu) ou vide (à boire), comme sur la maquette 5.
class GlassIcon extends StatelessWidget {
  const GlassIcon({super.key, required this.filled, this.size = 40});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 0.85,
    height: size * 1.2,
    child: CustomPaint(painter: _GlassPainter(filled)),
  );
}

class _GlassPainter extends CustomPainter {
  _GlassPainter(this.filled);

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inset = w * 0.12;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - inset, h)
      ..lineTo(inset, h)
      ..close();
    final paint = Paint()
      ..color = AppColors.water
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke;
    canvas.drawPath(path, paint);
    if (filled) {
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) => old.filled != filled;
}
