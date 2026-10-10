import 'dart:math' as math;

import 'package:flutter/material.dart';

class StatisticsScreenWidgets {
  ///// Top Metrices Box Function
  static Widget buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isPrimary, // true for orange card, false for white card
    Color? subtitleColor, // Optional custom color for subtitle
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isPrimary
            ? const Color(0xFFFF5722)
            : Colors.white, // Orange or White
        borderRadius: BorderRadius.circular(12.0),
        border: isPrimary
            ? null
            : Border.all(
                color: const Color(0xFFFF5722),
                width: 1.0,
              ), // Orange border for secondary cards
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            title,
            style: TextStyle(
              color: isPrimary ? Colors.white70 : Colors.orange.shade800,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),

          // Value / Number
          Text(
            value,
            style: TextStyle(
              color: isPrimary ? Colors.white : const Color(0xFFFF5722),
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),

          // Subtitle (e.g. Percentage or Status)
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor ?? (isPrimary ? Colors.white : Colors.green),
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  //// Top Metrices Function End
}

class StatisticsLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String duration;
  final bool showTotalSales;
  final bool showUdhaar;
  final bool showCollection;

  StatisticsLineChartPainter({
    required this.data,
    required this.duration,
    required this.showTotalSales,
    required this.showUdhaar,
    required this.showCollection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double leftPadding = 45;
    const double bottomPadding = 45;
    const double topPadding = 10;

    final double chartWidth = size.width - leftPadding;
    final double chartHeight = size.height - bottomPadding - topPadding;

    double getValue(Map<String, dynamic> item, String key) {
      final value = item[key];

      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    final List<double> totalSales = data
        .map((item) => getValue(item, 'total_sales'))
        .toList();

    final List<double> udhaar = data
        .map((item) => getValue(item, 'udhaar_sales'))
        .toList();

    final List<double> collection = data
        .map((item) => getValue(item, 'collection'))
        .toList();

    double maxValue = 0;

    for (final value in totalSales) {
      if (value > maxValue) maxValue = value;
    }

    for (final value in udhaar) {
      if (value > maxValue) maxValue = value;
    }

    for (final value in collection) {
      if (value > maxValue) maxValue = value;
    }

    const int gridLines = 4;

    if (maxValue <= 0) {
      maxValue = 1;
    }

    final double step = _niceStep(maxValue / gridLines);
    maxValue = step * gridLines;

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (int i = 0; i <= gridLines; i++) {
      final double y = topPadding + chartHeight - (i * chartHeight / gridLines);

      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      final TextPainter yLabel = TextPainter(
        text: TextSpan(
          text: _formatAxisValue(step * i),
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      yLabel.paint(
        canvas,
        Offset(leftPadding - yLabel.width - 6, y - (yLabel.height / 2)),
      );
    }

    List<Offset> createPoints(List<double> values) {
      final List<Offset> points = [];

      for (int i = 0; i < values.length; i++) {
        final double x = data.length == 1
            ? leftPadding + chartWidth / 2
            : leftPadding + (i * chartWidth / (data.length - 1));

        final double normalized = values[i] / maxValue;

        final double y = topPadding + chartHeight - (normalized * chartHeight);

        points.add(Offset(x, y));
      }

      return points;
    }

    final salesPoints = createPoints(totalSales);
    final udhaarPoints = createPoints(udhaar);
    final collectionPoints = createPoints(collection);

    if (showTotalSales) {
      _drawLine(canvas, salesPoints, const Color(0xFF1E88E5));
    }

    if (showUdhaar) {
      _drawLine(canvas, udhaarPoints, const Color(0xFFFF7043));
    }

    if (showCollection) {
      _drawLine(canvas, collectionPoints, const Color(0xFF26A69A));
    }

    int labelStep;

    if (duration == 'yearly') {
      labelStep = 1;
    } else if (duration == 'monthly') {
      labelStep = 5;
    } else if (duration == 'weekly') {
      labelStep = 1;
    } else {
      labelStep = data.length > 12 ? 3 : 1;
    }

    for (int i = 0; i < data.length; i++) {
      if (i % labelStep != 0 && i != data.length - 1) {
        continue;
      }

      final String label = data[i]['label']?.toString() ?? '';

      final double x = data.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (i * chartWidth / (data.length - 1));

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      labelPainter.layout();

      labelPainter.paint(
        canvas,
        Offset(x - (labelPainter.width / 2), size.height - 30),
      );
    }
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  double _niceStep(double rawStep) {
    if (rawStep <= 0) return 1;

    final double exponent = (math.log(rawStep) / math.ln10).floorToDouble();

    final double magnitude = math.pow(10, exponent).toDouble();

    final double normalized = rawStep / magnitude;

    const List<double> niceValues = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10];

    for (final double nice in niceValues) {
      if (normalized <= nice) {
        return nice * magnitude;
      }
    }

    return 10 * magnitude;
  }

  String _formatAxisValue(double value) {
    if (value == 0) return '0';

    if (value >= 1000000) {
      final double m = value / 1000000;

      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M';
    }

    if (value >= 1000) {
      final double k = value / 1000;

      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }

    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant StatisticsLineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.duration != duration ||
        oldDelegate.showTotalSales != showTotalSales ||
        oldDelegate.showUdhaar != showUdhaar ||
        oldDelegate.showCollection != showCollection;
  }
}
