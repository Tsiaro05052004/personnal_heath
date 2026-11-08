import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Icône de gélule inclinée (comme sur les maquettes) : Material n'en a pas.
/// Prend la couleur et la taille de l'[IconTheme] courant.
class PillIcon extends StatelessWidget {
  const PillIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: CustomPaint(
        painter: _PillPainter(color ?? theme.color ?? Colors.black),
      ),
    );
  }
}

class _PillPainter extends CustomPainter {
  _PillPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.09;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-math.pi / 4);
    final length = s * 0.86;
    final width = s * 0.38;
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: length,
      height: width,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(width / 2)),
        paint,
      )
      ..drawLine(Offset(0, -width / 2), Offset(0, width / 2), paint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _PillPainter oldDelegate) =>
      oldDelegate.color != color;
}
