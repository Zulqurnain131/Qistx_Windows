import 'package:flutter/material.dart';

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  DashedCirclePainter({
    this.color = const Color(0xFFFF5500),
    this.strokeWidth = 1.5,
    this.dashCount = 45,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double circumference = 2 * 3.141592653589793 * radius;
    final double dashWidth = circumference / (dashCount * 2);
    final double spaceWidth = dashWidth;

    double currentAngle = 0;
    while (currentAngle < 2 * 3.141592653589793) {
      final double sweepAngle =
          (dashWidth / circumference) * 2 * 3.141592653589793;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle +=
          sweepAngle + ((spaceWidth / circumference) * 2 * 3.141592653589793);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
