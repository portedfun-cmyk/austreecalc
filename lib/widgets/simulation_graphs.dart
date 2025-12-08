import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Simple line chart showing safety factor versus wind speed.
class SafetyFactorVsWindGraph extends StatelessWidget {
  final List<double> windSpeeds;
  final List<double> safetyFactors;
  final double? designWindSpeed;
  final double? windToFailure;

  const SafetyFactorVsWindGraph({
    super.key,
    required this.windSpeeds,
    required this.safetyFactors,
    this.designWindSpeed,
    this.windToFailure,
  });

  @override
  Widget build(BuildContext context) {
    if (windSpeeds.length < 2 || safetyFactors.length < 2) {
      return const Text(
        'Structural margin vs wind speed graph will display after a calculation.',
      );
    }

    if (windSpeeds.length != safetyFactors.length) {
      return const Text(
        'Unable to plot structural margin vs wind speed (internal data mismatch).',
      );
    }

    final finiteYs =
        safetyFactors.where((v) => v.isFinite && v > 0).toList(growable: false);
    if (finiteYs.isEmpty) {
      return const Text(
        'Unable to plot structural margin vs wind speed (no positive finite values).',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Figure A1 – Structural margin (SF) versus wind speed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomPaint(
                size: Size.infinite,
                painter: _SfWindPainter(
                  xs: windSpeeds,
                  ys: safetyFactors,
                  designWindSpeed: designWindSpeed,
                  windToFailure: windToFailure,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SfWindPainter extends CustomPainter {
  final List<double> xs;
  final List<double> ys;
  final double? designWindSpeed;
  final double? windToFailure;

  _SfWindPainter({
    required this.xs,
    required this.ys,
    this.designWindSpeed,
    this.windToFailure,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (xs.isEmpty || ys.isEmpty || xs.length != ys.length) return;

    final finiteYs =
        ys.where((v) => v.isFinite && v > 0).toList(growable: false);
    if (finiteYs.isEmpty) return;

    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    if (maxX <= minX) return;

    double maxY = finiteYs.reduce(math.max);
    maxY = math.max(2.0, maxY * 1.1); // Add 10% headroom
    maxY = (maxY.ceil()).toDouble().clamp(2.0, 8.0);
    const minY = 0.0;

    const double leftPad = 44;
    const double rightPad = 16;
    const double topPad = 16;
    const double bottomPad = 36;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final axisPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1.5;

    final linePaint = Paint()
      ..color = Colors.green.shade700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final criticalPaint = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final markerPaint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 1.5;

    final origin = Offset(leftPad, size.height - bottomPad);

    double xToPx(double x) => origin.dx + (x - minX) / (maxX - minX) * chartWidth;
    double yToPx(double y) =>
        origin.dy - (y - minY) / (maxY - minY) * chartHeight;

    // Draw horizontal grid lines and Y-axis labels
    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );

    for (double sfLevel = 0; sfLevel <= maxY; sfLevel += 0.5) {
      final y = yToPx(sfLevel);
      final isCritical = (sfLevel - 1.0).abs() < 0.01;
      
      // Grid line
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + chartWidth, y),
        isCritical ? criticalPaint : gridPaint,
      );

      // Y-axis label
      textPainter.text = TextSpan(
        text: sfLevel.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 10,
          color: isCritical ? Colors.red.shade700 : Colors.black87,
          fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 4, y - 5));
    }

    // Draw vertical grid lines
    final xRange = maxX - minX;
    final xStep = xRange > 30 ? 10.0 : (xRange > 15 ? 5.0 : 2.0);
    for (double xVal = (minX / xStep).ceil() * xStep; xVal <= maxX; xVal += xStep) {
      final px = xToPx(xVal);
      canvas.drawLine(Offset(px, origin.dy), Offset(px, topPad), gridPaint);
    }

    // Axes
    canvas.drawLine(origin, Offset(origin.dx + chartWidth, origin.dy), axisPaint);
    canvas.drawLine(origin, Offset(origin.dx, topPad), axisPaint);

    // Plot the curve
    final path = Path();
    var hasPoint = false;
    for (var i = 0; i < xs.length; i++) {
      final x = xs[i];
      final y = ys[i];
      if (!y.isFinite) continue;
      final px = xToPx(x);
      final py = yToPx(y.clamp(minY, maxY));
      if (!hasPoint) {
        path.moveTo(px, py);
        hasPoint = true;
      } else {
        path.lineTo(px, py);
      }
    }
    if (hasPoint) {
      canvas.drawPath(path, linePaint);
    }

    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.fill;
    for (var i = 0; i < xs.length; i++) {
      final y = ys[i];
      if (!y.isFinite) continue;
      final px = xToPx(xs[i]);
      final py = yToPx(y.clamp(minY, maxY));
      canvas.drawCircle(Offset(px, py), 3, pointPaint);
    }

    // Draw design wind speed marker (vertical dashed line)
    if (designWindSpeed != null && designWindSpeed! >= minX && designWindSpeed! <= maxX) {
      final px = xToPx(designWindSpeed!);
      final dashPaint = Paint()
        ..color = Colors.blue.shade600
        ..strokeWidth = 2;
      // Draw dashed line
      for (double dy = topPad; dy < origin.dy; dy += 8) {
        canvas.drawLine(Offset(px, dy), Offset(px, math.min(dy + 4, origin.dy)), dashPaint);
      }
    }

    // Draw wind-to-failure marker
    if (windToFailure != null && windToFailure!.isFinite && windToFailure! >= minX && windToFailure! <= maxX) {
      final px = xToPx(windToFailure!);
      final failPaint = Paint()
        ..color = Colors.red.shade600
        ..strokeWidth = 2;
      for (double dy = topPad; dy < origin.dy; dy += 8) {
        canvas.drawLine(Offset(px, dy), Offset(px, math.min(dy + 4, origin.dy)), failPaint);
      }
    }

    // X-axis labels
    void drawXLabel(String text, double xPos, {Color? color}) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: color ?? Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, origin.dy + 4));
    }

    drawXLabel('${minX.toStringAsFixed(0)}', origin.dx);
    drawXLabel('${maxX.toStringAsFixed(0)} m/s', origin.dx + chartWidth);
    
    if (designWindSpeed != null && designWindSpeed! > minX + 5 && designWindSpeed! < maxX - 5) {
      drawXLabel('${designWindSpeed!.toStringAsFixed(0)}', xToPx(designWindSpeed!), color: Colors.blue.shade700);
    }

    // Y-axis title
    textPainter.text = const TextSpan(
      text: 'SF',
      style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(4, topPad - 2));

    // X-axis title
    textPainter.text = const TextSpan(
      text: 'Wind Speed (m/s)',
      style: TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(origin.dx + chartWidth / 2 - textPainter.width / 2, size.height - 14));

    // Legend
    final legendY = topPad + 4;
    final legendX = origin.dx + chartWidth - 120;
    
    // SF=1 critical line legend
    canvas.drawLine(Offset(legendX, legendY + 4), Offset(legendX + 16, legendY + 4), criticalPaint);
    textPainter.text = const TextSpan(
      text: 'SF = 1 (critical)',
      style: TextStyle(fontSize: 9, color: Colors.red),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 20, legendY));

    if (designWindSpeed != null) {
      canvas.drawLine(
        Offset(legendX, legendY + 16),
        Offset(legendX + 16, legendY + 16),
        Paint()..color = Colors.blue.shade600..strokeWidth = 2,
      );
      textPainter.text = const TextSpan(
        text: 'Design wind',
        style: TextStyle(fontSize: 9, color: Colors.blue),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 20, legendY + 12));
    }
  }

  @override
  bool shouldRepaint(covariant _SfWindPainter oldDelegate) {
    return oldDelegate.xs != xs || 
           oldDelegate.ys != ys ||
           oldDelegate.designWindSpeed != designWindSpeed ||
           oldDelegate.windToFailure != windToFailure;
  }
}

/// Line chart showing safety factor versus crown reduction percentage.
class ReductionEffectGraph extends StatelessWidget {
  final List<double> reductionsPercent;
  final List<double> safetyFactors;
  final double? currentReductionPercent;
  final double? sfBefore;
  final double? sfAfter;

  const ReductionEffectGraph({
    super.key,
    required this.reductionsPercent,
    required this.safetyFactors,
    this.currentReductionPercent,
    this.sfBefore,
    this.sfAfter,
  });

  @override
  Widget build(BuildContext context) {
    if (reductionsPercent.length < 2 || safetyFactors.length < 2) {
      return const Text(
        'Structural margin vs crown reduction graph will display after a pruning calculation.',
      );
    }

    if (reductionsPercent.length != safetyFactors.length) {
      return const Text(
        'Unable to plot structural margin vs crown reduction (internal data mismatch).',
      );
    }

    final finiteYs =
        safetyFactors.where((v) => v.isFinite && v > 0).toList(growable: false);
    if (finiteYs.isEmpty) {
      return const Text(
        'Unable to plot structural margin vs crown reduction (no positive finite values).',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Structural margin (SF) versus crown reduction (%)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomPaint(
                size: Size.infinite,
                painter: _ReductionPainter(
                  xs: reductionsPercent,
                  ys: safetyFactors,
                  currentReductionPercent: currentReductionPercent,
                  sfBefore: sfBefore,
                  sfAfter: sfAfter,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReductionPainter extends CustomPainter {
  final List<double> xs; // reduction %
  final List<double> ys; // SF
  final double? currentReductionPercent;
  final double? sfBefore;
  final double? sfAfter;

  _ReductionPainter({
    required this.xs,
    required this.ys,
    this.currentReductionPercent,
    this.sfBefore,
    this.sfAfter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (xs.isEmpty || ys.isEmpty || xs.length != ys.length) return;

    final finiteYs =
        ys.where((v) => v.isFinite && v > 0).toList(growable: false);
    if (finiteYs.isEmpty) return;

    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    if (maxX <= minX) return;

    double maxY = finiteYs.reduce(math.max);
    maxY = math.max(2.0, maxY * 1.1);
    maxY = (maxY.ceil()).toDouble().clamp(2.0, 8.0);
    const minY = 0.0;

    const double leftPad = 44;
    const double rightPad = 16;
    const double topPad = 16;
    const double bottomPad = 36;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final axisPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1.5;

    final linePaint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final criticalPaint = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final origin = Offset(leftPad, size.height - bottomPad);

    double xToPx(double x) => origin.dx + (x - minX) / (maxX - minX) * chartWidth;
    double yToPx(double y) =>
        origin.dy - (y - minY) / (maxY - minY) * chartHeight;

    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );

    // Draw horizontal grid lines and Y-axis labels
    for (double sfLevel = 0; sfLevel <= maxY; sfLevel += 0.5) {
      final y = yToPx(sfLevel);
      final isCritical = (sfLevel - 1.0).abs() < 0.01;
      
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + chartWidth, y),
        isCritical ? criticalPaint : gridPaint,
      );

      textPainter.text = TextSpan(
        text: sfLevel.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 10,
          color: isCritical ? Colors.red.shade700 : Colors.black87,
          fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 4, y - 5));
    }

    // Draw vertical grid lines every 5%
    for (double xVal = 0; xVal <= 40; xVal += 5) {
      if (xVal >= minX && xVal <= maxX) {
        final px = xToPx(xVal);
        canvas.drawLine(Offset(px, origin.dy), Offset(px, topPad), gridPaint);
      }
    }

    // Axes
    canvas.drawLine(origin, Offset(origin.dx + chartWidth, origin.dy), axisPaint);
    canvas.drawLine(origin, Offset(origin.dx, topPad), axisPaint);

    // Plot the curve
    final path = Path();
    var hasPoint = false;
    for (var i = 0; i < xs.length; i++) {
      final x = xs[i];
      final y = ys[i];
      if (!y.isFinite) continue;
      final px = xToPx(x);
      final py = yToPx(y.clamp(minY, maxY));
      if (!hasPoint) {
        path.moveTo(px, py);
        hasPoint = true;
      } else {
        path.lineTo(px, py);
      }
    }
    if (hasPoint) {
      canvas.drawPath(path, linePaint);
    }

    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.blue.shade800
      ..style = PaintingStyle.fill;
    for (var i = 0; i < xs.length; i++) {
      final y = ys[i];
      if (!y.isFinite) continue;
      final px = xToPx(xs[i]);
      final py = yToPx(y.clamp(minY, maxY));
      canvas.drawCircle(Offset(px, py), 3, pointPaint);
    }

    // Draw current reduction marker (vertical purple dashed line)
    if (currentReductionPercent != null && currentReductionPercent! >= minX && currentReductionPercent! <= maxX) {
      final px = xToPx(currentReductionPercent!);
      final markerPaint = Paint()
        ..color = Colors.purple.shade600
        ..strokeWidth = 2;
      for (double dy = topPad; dy < origin.dy; dy += 8) {
        canvas.drawLine(Offset(px, dy), Offset(px, math.min(dy + 4, origin.dy)), markerPaint);
      }
    }

    // Draw SF before/after markers as horizontal lines
    if (sfBefore != null && sfBefore!.isFinite && sfBefore! >= minY && sfBefore! <= maxY) {
      final py = yToPx(sfBefore!);
      final beforePaint = Paint()
        ..color = Colors.grey.shade600
        ..strokeWidth = 1.5;
      for (double dx = origin.dx; dx < origin.dx + chartWidth; dx += 10) {
        canvas.drawLine(Offset(dx, py), Offset(math.min(dx + 5, origin.dx + chartWidth), py), beforePaint);
      }
    }

    // X-axis labels
    void drawXLabel(String text, double xPos, {Color? color}) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: color ?? Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, origin.dy + 4));
    }

    drawXLabel('${minX.toStringAsFixed(0)}%', origin.dx);
    drawXLabel('${maxX.toStringAsFixed(0)}%', origin.dx + chartWidth);

    if (currentReductionPercent != null && currentReductionPercent! > minX + 3 && currentReductionPercent! < maxX - 3) {
      drawXLabel('${currentReductionPercent!.toStringAsFixed(0)}%', xToPx(currentReductionPercent!), color: Colors.purple.shade700);
    }

    // Y-axis title
    textPainter.text = const TextSpan(
      text: 'SF',
      style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(4, topPad - 2));

    // X-axis title
    textPainter.text = const TextSpan(
      text: 'Crown Reduction (%)',
      style: TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(origin.dx + chartWidth / 2 - textPainter.width / 2, size.height - 14));

    // Legend
    final legendY = topPad + 4;
    final legendX = origin.dx + chartWidth - 140;
    
    canvas.drawLine(Offset(legendX, legendY + 4), Offset(legendX + 16, legendY + 4), criticalPaint);
    textPainter.text = const TextSpan(
      text: 'SF = 1 (critical)',
      style: TextStyle(fontSize: 9, color: Colors.red),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 20, legendY));

    if (currentReductionPercent != null) {
      canvas.drawLine(
        Offset(legendX, legendY + 16),
        Offset(legendX + 16, legendY + 16),
        Paint()..color = Colors.purple.shade600..strokeWidth = 2,
      );
      textPainter.text = const TextSpan(
        text: 'Selected reduction',
        style: TextStyle(fontSize: 9, color: Colors.purple),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 20, legendY + 12));
    }

    if (sfBefore != null) {
      canvas.drawLine(
        Offset(legendX, legendY + 28),
        Offset(legendX + 16, legendY + 28),
        Paint()..color = Colors.grey.shade600..strokeWidth = 1.5,
      );
      textPainter.text = TextSpan(
        text: 'SF before: ${sfBefore!.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 20, legendY + 24));
    }
  }

  @override
  bool shouldRepaint(covariant _ReductionPainter oldDelegate) {
    return oldDelegate.xs != xs || 
           oldDelegate.ys != ys ||
           oldDelegate.currentReductionPercent != currentReductionPercent ||
           oldDelegate.sfBefore != sfBefore ||
           oldDelegate.sfAfter != sfAfter;
  }
}

class ResidualWallGraph extends StatelessWidget {
  final List<double> residualWallPercents;
  final List<double> safetyFactors;
  final double? currentResidualPercent;
  final double? criticalResidualPercent;

  const ResidualWallGraph({
    super.key,
    required this.residualWallPercents,
    required this.safetyFactors,
    this.currentResidualPercent,
    this.criticalResidualPercent,
  });

  @override
  Widget build(BuildContext context) {
    if (residualWallPercents.length < 2 || safetyFactors.length < 2) {
      return const Text(
        'Decay / residual wall graph will display after a calculation.',
      );
    }

    if (residualWallPercents.length != safetyFactors.length) {
      return const Text(
        'Unable to plot decay / residual wall graph (internal data mismatch).',
      );
    }

    final finiteYs =
        safetyFactors.where((v) => v.isFinite && v > 0).toList(growable: false);
    if (finiteYs.isEmpty) {
      return const Text(
        'Unable to plot decay / residual wall graph (no positive finite values).',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Figure A2 – Structural margin (SF) versus residual wall (%)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomPaint(
                size: Size.infinite,
                painter: _ResidualWallPainter(
                  xs: residualWallPercents,
                  ys: safetyFactors,
                  currentResidualPercent: currentResidualPercent,
                  criticalResidualPercent: criticalResidualPercent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResidualWallPainter extends CustomPainter {
  final List<double> xs;
  final List<double> ys;
  final double? currentResidualPercent;
  final double? criticalResidualPercent;

  _ResidualWallPainter({
    required this.xs,
    required this.ys,
    this.currentResidualPercent,
    this.criticalResidualPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (xs.isEmpty || ys.isEmpty || xs.length != ys.length) return;

    final finiteYs =
        ys.where((v) => v.isFinite && v > 0).toList(growable: false);
    if (finiteYs.isEmpty) return;

    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    if (maxX <= minX) return;

    double maxY = finiteYs.reduce(math.max);
    maxY = math.max(2.0, maxY * 1.1);
    maxY = (maxY.ceil()).toDouble().clamp(2.0, 8.0);
    const minY = 0.0;

    const double leftPad = 44;
    const double rightPad = 16;
    const double topPad = 16;
    const double bottomPad = 36;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final axisPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1.5;

    final linePaint = Paint()
      ..color = Colors.orange.shade700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final criticalPaint = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final origin = Offset(leftPad, size.height - bottomPad);

    double xToPx(double x) => origin.dx + (x - minX) / (maxX - minX) * chartWidth;
    double yToPx(double y) =>
        origin.dy - (y - minY) / (maxY - minY) * chartHeight;

    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );

    // Draw horizontal grid lines and Y-axis labels
    for (double sfLevel = 0; sfLevel <= maxY; sfLevel += 0.5) {
      final y = yToPx(sfLevel);
      final isCritical = (sfLevel - 1.0).abs() < 0.01;
      
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + chartWidth, y),
        isCritical ? criticalPaint : gridPaint,
      );

      textPainter.text = TextSpan(
        text: sfLevel.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 10,
          color: isCritical ? Colors.red.shade700 : Colors.black87,
          fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 4, y - 5));
    }

    // Draw vertical grid lines every 10%
    for (double xVal = 20; xVal <= 100; xVal += 10) {
      if (xVal >= minX && xVal <= maxX) {
        final px = xToPx(xVal);
        canvas.drawLine(Offset(px, origin.dy), Offset(px, topPad), gridPaint);
      }
    }

    // Axes
    canvas.drawLine(origin, Offset(origin.dx + chartWidth, origin.dy), axisPaint);
    canvas.drawLine(origin, Offset(origin.dx, topPad), axisPaint);

    // Plot the decay curve
    final path = Path();
    var hasPoint = false;
    for (var i = 0; i < xs.length; i++) {
      final x = xs[i];
      final y = ys[i];
      if (!y.isFinite) continue;
      final px = xToPx(x);
      final py = yToPx(y.clamp(minY, maxY));
      if (!hasPoint) {
        path.moveTo(px, py);
        hasPoint = true;
      } else {
        path.lineTo(px, py);
      }
    }
    if (hasPoint) {
      canvas.drawPath(path, linePaint);
    }

    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.orange.shade800
      ..style = PaintingStyle.fill;
    for (var i = 0; i < xs.length; i++) {
      final y = ys[i];
      if (!y.isFinite) continue;
      final px = xToPx(xs[i]);
      final py = yToPx(y.clamp(minY, maxY));
      canvas.drawCircle(Offset(px, py), 3, pointPaint);
    }

    // Draw current residual wall marker (green vertical line)
    if (currentResidualPercent != null && currentResidualPercent! >= minX && currentResidualPercent! <= maxX) {
      final px = xToPx(currentResidualPercent!);
      final currentPaint = Paint()
        ..color = Colors.green.shade600
        ..strokeWidth = 2;
      for (double dy = topPad; dy < origin.dy; dy += 8) {
        canvas.drawLine(Offset(px, dy), Offset(px, math.min(dy + 4, origin.dy)), currentPaint);
      }
    }

    // Draw critical residual wall marker (red vertical line)
    if (criticalResidualPercent != null && criticalResidualPercent! >= minX && criticalResidualPercent! <= maxX) {
      final px = xToPx(criticalResidualPercent!);
      final critPaint = Paint()
        ..color = Colors.red.shade600
        ..strokeWidth = 2;
      for (double dy = topPad; dy < origin.dy; dy += 8) {
        canvas.drawLine(Offset(px, dy), Offset(px, math.min(dy + 4, origin.dy)), critPaint);
      }
    }

    // X-axis labels
    void drawXLabel(String text, double xPos, {Color? color}) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: color ?? Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, origin.dy + 4));
    }

    drawXLabel('${minX.toStringAsFixed(0)}%', origin.dx);
    drawXLabel('${maxX.toStringAsFixed(0)}%', origin.dx + chartWidth);

    if (currentResidualPercent != null && currentResidualPercent! > minX + 8 && currentResidualPercent! < maxX - 8) {
      drawXLabel('${currentResidualPercent!.toStringAsFixed(0)}%', xToPx(currentResidualPercent!), color: Colors.green.shade700);
    }
    if (criticalResidualPercent != null && criticalResidualPercent! > minX + 8 && criticalResidualPercent! < maxX - 8) {
      drawXLabel('${criticalResidualPercent!.toStringAsFixed(0)}%', xToPx(criticalResidualPercent!), color: Colors.red.shade700);
    }

    // Y-axis title
    textPainter.text = const TextSpan(
      text: 'SF',
      style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(4, topPad - 2));

    // X-axis title
    textPainter.text = const TextSpan(
      text: 'Residual Wall (%)',
      style: TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(origin.dx + chartWidth / 2 - textPainter.width / 2, size.height - 14));

    // Legend
    final legendY = topPad + 4;
    final legendX = origin.dx + chartWidth - 130;
    
    canvas.drawLine(Offset(legendX, legendY + 4), Offset(legendX + 16, legendY + 4), criticalPaint);
    textPainter.text = const TextSpan(
      text: 'SF = 1 (critical)',
      style: TextStyle(fontSize: 9, color: Colors.red),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 20, legendY));

    if (currentResidualPercent != null) {
      canvas.drawLine(
        Offset(legendX, legendY + 16),
        Offset(legendX + 16, legendY + 16),
        Paint()..color = Colors.green.shade600..strokeWidth = 2,
      );
      textPainter.text = const TextSpan(
        text: 'Current wall',
        style: TextStyle(fontSize: 9, color: Colors.green),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 20, legendY + 12));
    }

    if (criticalResidualPercent != null) {
      canvas.drawLine(
        Offset(legendX, legendY + 28),
        Offset(legendX + 16, legendY + 28),
        Paint()..color = Colors.red.shade600..strokeWidth = 2,
      );
      textPainter.text = const TextSpan(
        text: 'Critical wall',
        style: TextStyle(fontSize: 9, color: Colors.red),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 20, legendY + 24));
    }
  }

  @override
  bool shouldRepaint(covariant _ResidualWallPainter oldDelegate) {
    return oldDelegate.xs != xs || 
           oldDelegate.ys != ys ||
           oldDelegate.currentResidualPercent != currentResidualPercent ||
           oldDelegate.criticalResidualPercent != criticalResidualPercent;
  }
}

/// Animated schematic of before/after pruning as two trees side by side.
class PruningSimulationVisual extends StatefulWidget {
  final double heightM;
  final double crownBeforeM;
  final double crownAfterM;
  final double fullnessBefore;
  final double fullnessAfter;

  const PruningSimulationVisual({
    super.key,
    required this.heightM,
    required this.crownBeforeM,
    required this.crownAfterM,
    required this.fullnessBefore,
    required this.fullnessAfter,
  });

  @override
  State<PruningSimulationVisual> createState() => _PruningSimulationVisualState();
}

class _PruningSimulationVisualState extends State<PruningSimulationVisual>
    with TickerProviderStateMixin {
  late AnimationController _swayController;
  late AnimationController _leafController;
  late Animation<double> _swayAnimation;
  late Animation<double> _leafAnimation;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _swayAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );
    
    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _leafAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leafController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _swayController.dispose();
    _leafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reductionPct = widget.crownBeforeM > 0 
        ? ((widget.crownBeforeM - widget.crownAfterM) / widget.crownBeforeM * 100).toStringAsFixed(0)
        : '0';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Before vs After Pruning Comparison',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.air, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('Wind simulation', style: TextStyle(fontSize: 10, color: Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: Listenable.merge([_swayAnimation, _leafAnimation]),
              builder: (context, child) {
                final sway = _swayAnimation.value;
                final leaf = _leafAnimation.value;
                // Before tree sways more (larger crown catches more wind)
                final beforeSway = sway * 0.15;
                // After tree sways less (smaller crown = less wind load)
                final afterSway = sway * 0.08 * (widget.crownAfterM / widget.crownBeforeM).clamp(0.3, 1.0);
                
                return Row(
                  children: [
                    // Before tree - more sway (more wind load)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFB0E0E6), Color(0xFFE6F3FF)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: _AnimatedTreePainter(
                            crownDiameterM: widget.crownBeforeM,
                            fullness: widget.fullnessBefore,
                            label: 'BEFORE',
                            sway: beforeSway,
                            leafSway: leaf,
                            isAfter: false,
                          ),
                        ),
                      ),
                    ),
                    // Arrow showing transformation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward, color: Colors.green, size: 24),
                          const SizedBox(height: 4),
                          Text('-$reductionPct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('crown', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.trending_down, color: Colors.green, size: 16),
                                Text('Less', style: TextStyle(fontSize: 8, color: Colors.green)),
                                Text('sway', style: TextStyle(fontSize: 8, color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // After tree - less sway (reduced wind load)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFB0E0E6), Color(0xFFE6F3FF)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade400, width: 2),
                        ),
                        child: CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: _AnimatedTreePainter(
                            crownDiameterM: widget.crownAfterM,
                            fullness: widget.fullnessAfter,
                            label: 'AFTER',
                            sway: afterSway,
                            leafSway: leaf * 0.6,
                            isAfter: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('Crown Ø', '${widget.crownBeforeM.toStringAsFixed(1)}m → ${widget.crownAfterM.toStringAsFixed(1)}m', Colors.brown),
              _buildStatChip('Fullness', '${(widget.fullnessBefore * 100).toStringAsFixed(0)}% → ${(widget.fullnessAfter * 100).toStringAsFixed(0)}%', Colors.green),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _SingleTreePainter extends CustomPainter {
  final double crownDiameterM;
  final double fullness;
  final String label;
  final bool isAfter;

  _SingleTreePainter({
    required this.crownDiameterM,
    required this.fullness,
    this.label = '',
    this.isAfter = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.92;
    final trunkTopY = size.height * 0.45;
    final trunkX = size.width * 0.5;
    final trunkWidth = size.width * 0.06;

    // Ground with grass
    final groundPaint = Paint()..color = const Color(0xFF4A7C23);
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), groundPaint);
    
    // Root flare
    final rootPaint = Paint()..color = const Color(0xFF5D4037);
    final rootPath = Path();
    rootPath.moveTo(trunkX - trunkWidth * 2, groundY);
    rootPath.quadraticBezierTo(trunkX - trunkWidth, groundY - trunkWidth, trunkX, groundY - trunkWidth * 1.5);
    rootPath.quadraticBezierTo(trunkX + trunkWidth, groundY - trunkWidth, trunkX + trunkWidth * 2, groundY);
    rootPath.lineTo(trunkX + trunkWidth * 2, groundY + 2);
    rootPath.lineTo(trunkX - trunkWidth * 2, groundY + 2);
    rootPath.close();
    canvas.drawPath(rootPath, rootPaint);

    // Trunk with gradient
    final trunkPath = Path();
    trunkPath.moveTo(trunkX - trunkWidth, groundY - trunkWidth);
    trunkPath.lineTo(trunkX - trunkWidth * 0.5, trunkTopY);
    trunkPath.lineTo(trunkX + trunkWidth * 0.5, trunkTopY);
    trunkPath.lineTo(trunkX + trunkWidth, groundY - trunkWidth);
    trunkPath.close();
    
    final trunkGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [Color(0xFF3E2723), Color(0xFF5D4037), Color(0xFF4E342E)],
    );
    canvas.drawPath(trunkPath, Paint()..shader = trunkGradient.createShader(
      Rect.fromLTWH(trunkX - trunkWidth, trunkTopY, trunkWidth * 2, groundY - trunkTopY)));

    // Crown - multiple layers for depth
    final crownCenterY = trunkTopY - size.height * 0.1;
    final maxRadius = size.width * 0.38;
    final radius = maxRadius * (0.7 + 0.3 * (crownDiameterM / 15).clamp(0.5, 1.5));
    final crownAlpha = (0.6 + 0.4 * fullness.clamp(0.0, 1.0));
    
    // Shadow layer
    final shadowGreen = Color.lerp(const Color(0xFF004D00), const Color(0xFF8B7355), 1 - fullness)!;
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final dist = radius * 0.4;
      final blobX = trunkX - 3 + math.cos(angle) * dist;
      final blobY = crownCenterY + 5 + math.sin(angle) * dist * 0.6;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(blobX, blobY), width: radius * 0.6, height: radius * 0.45),
        Paint()..color = shadowGreen.withOpacity(crownAlpha * 0.8),
      );
    }
    
    // Main foliage
    final baseGreen = Color.lerp(const Color(0xFF228B22), const Color(0xFFA08060), 1 - fullness)!;
    for (var layer = 0; layer < 3; layer++) {
      final layerColor = Color.lerp(const Color(0xFF006400), baseGreen, layer / 2)!;
      for (var i = 0; i < 10; i++) {
        final angle = (i / 10 + layer * 0.1) * 2 * math.pi;
        final dist = radius * (0.25 + (i % 3) * 0.12);
        final blobX = trunkX + layer * 2 + math.cos(angle) * dist;
        final blobY = crownCenterY + layer * 3 + math.sin(angle) * dist * 0.55;
        final blobW = radius * (0.4 + (i % 2) * 0.15);
        final blobH = blobW * 0.65;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(blobX, blobY), width: blobW, height: blobH),
          Paint()..color = layerColor.withOpacity(crownAlpha),
        );
      }
    }
    
    // Highlight clusters
    final lightGreen = Color.lerp(const Color(0xFF32CD32), const Color(0xFFD2B48C), 1 - fullness)!;
    final random = math.Random(42);
    for (var i = 0; i < 12; i++) {
      final angle = random.nextDouble() * math.pi * 1.5 - math.pi * 0.25;
      final dist = random.nextDouble() * radius * 0.5;
      final x = trunkX + 5 + math.cos(angle) * dist;
      final y = crownCenterY - 3 + math.sin(angle) * dist * 0.5;
      final dotSize = 2.0 + random.nextDouble() * 5;
      canvas.drawCircle(Offset(x, y), dotSize, Paint()..color = lightGreen.withOpacity(crownAlpha * 0.7));
    }
    
    // Draw label
    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isAfter ? const Color(0xFF2E7D32) : const Color(0xFF555555),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, 6));
    }
    
    // Crown diameter indicator
    final diamPaint = Paint()
      ..color = Colors.brown.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(trunkX - radius * 0.7, crownCenterY + radius * 0.5),
      Offset(trunkX + radius * 0.7, crownCenterY + radius * 0.5),
      diamPaint,
    );
    
    // Diameter text
    final diamText = TextPainter(
      text: TextSpan(
        text: '${crownDiameterM.toStringAsFixed(1)}m',
        style: TextStyle(fontSize: 9, color: Colors.brown.shade700),
      ),
      textDirection: TextDirection.ltr,
    );
    diamText.layout();
    diamText.paint(canvas, Offset(trunkX - diamText.width / 2, crownCenterY + radius * 0.5 + 2));
  }

  @override
  bool shouldRepaint(covariant _SingleTreePainter oldDelegate) {
    return oldDelegate.crownDiameterM != crownDiameterM ||
        oldDelegate.fullness != fullness ||
        oldDelegate.label != label ||
        oldDelegate.isAfter != isAfter;
  }
}

/// Animated tree painter for pruning comparison with sway effect.
class _AnimatedTreePainter extends CustomPainter {
  final double crownDiameterM;
  final double fullness;
  final String label;
  final double sway;
  final double leafSway;
  final bool isAfter;

  _AnimatedTreePainter({
    required this.crownDiameterM,
    required this.fullness,
    required this.label,
    required this.sway,
    required this.leafSway,
    this.isAfter = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.88;
    final trunkTopY = size.height * 0.42;
    final trunkX = size.width * 0.5;
    final trunkWidth = size.width * 0.055;
    final trunkHeight = groundY - trunkTopY;

    // Ground with grass
    final groundPaint = Paint()..color = const Color(0xFF4A7C23);
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), groundPaint);
    
    // Calculate bend offset at top
    final bendOffset = sway * trunkHeight * 0.25;
    
    // Root flare
    final rootPaint = Paint()..color = const Color(0xFF5D4037);
    final rootPath = Path();
    rootPath.moveTo(trunkX - trunkWidth * 2.5, groundY);
    rootPath.quadraticBezierTo(trunkX - trunkWidth, groundY - trunkWidth * 0.8, trunkX, groundY - trunkWidth * 1.2);
    rootPath.quadraticBezierTo(trunkX + trunkWidth, groundY - trunkWidth * 0.8, trunkX + trunkWidth * 2.5, groundY);
    rootPath.close();
    canvas.drawPath(rootPath, rootPaint);

    // Trunk with bend
    final trunkPath = Path();
    trunkPath.moveTo(trunkX - trunkWidth, groundY - trunkWidth);
    trunkPath.quadraticBezierTo(
      trunkX - trunkWidth * 0.7 + bendOffset * 0.3, trunkTopY + trunkHeight * 0.5,
      trunkX - trunkWidth * 0.4 + bendOffset, trunkTopY,
    );
    trunkPath.lineTo(trunkX + trunkWidth * 0.4 + bendOffset, trunkTopY);
    trunkPath.quadraticBezierTo(
      trunkX + trunkWidth * 0.7 + bendOffset * 0.3, trunkTopY + trunkHeight * 0.5,
      trunkX + trunkWidth, groundY - trunkWidth,
    );
    trunkPath.close();
    
    final trunkGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [Color(0xFF3E2723), Color(0xFF5D4037), Color(0xFF4E342E)],
    );
    canvas.drawPath(trunkPath, Paint()..shader = trunkGradient.createShader(
      Rect.fromLTWH(trunkX - trunkWidth * 2, trunkTopY, trunkWidth * 4, trunkHeight)));

    // Crown
    final crownCenterX = trunkX + bendOffset;
    final crownCenterY = trunkTopY - size.height * 0.12;
    final maxRadius = size.width * 0.38;
    final radius = maxRadius * (0.6 + 0.4 * (crownDiameterM / 12).clamp(0.4, 1.2));
    final crownAlpha = 0.5 + 0.5 * fullness.clamp(0.0, 1.0);
    
    // Shadow layer
    final shadowGreen = Color.lerp(const Color(0xFF004D00), const Color(0xFF8B7355), 1 - fullness)!;
    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi;
      final wobble = math.sin(angle * 2 + leafSway * 3) * radius * 0.08;
      final dist = radius * 0.35 + wobble;
      final blobX = crownCenterX - 2 + math.cos(angle) * dist;
      final blobY = crownCenterY + 4 + math.sin(angle) * dist * 0.55;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(blobX, blobY), width: radius * 0.55, height: radius * 0.4),
        Paint()..color = shadowGreen.withOpacity(crownAlpha * 0.7),
      );
    }
    
    // Main foliage with sway
    final baseGreen = Color.lerp(const Color(0xFF228B22), const Color(0xFFA08060), 1 - fullness)!;
    for (var layer = 0; layer < 3; layer++) {
      final layerColor = Color.lerp(const Color(0xFF006400), baseGreen, layer / 2)!;
      for (var i = 0; i < 8; i++) {
        final angle = (i / 8 + layer * 0.1) * 2 * math.pi;
        final wobble = math.sin(angle * 2 + leafSway * 4) * radius * 0.1;
        final dist = radius * (0.2 + (i % 3) * 0.1) + wobble;
        final blobX = crownCenterX + layer * 2 + math.cos(angle) * dist + leafSway * 3;
        final blobY = crownCenterY + layer * 2 + math.sin(angle) * dist * 0.5;
        final blobW = radius * (0.35 + (i % 2) * 0.12);
        final blobH = blobW * 0.6;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(blobX, blobY), width: blobW, height: blobH),
          Paint()..color = layerColor.withOpacity(crownAlpha),
        );
      }
    }
    
    // Highlights
    final lightGreen = Color.lerp(const Color(0xFF32CD32), const Color(0xFFD2B48C), 1 - fullness)!;
    final random = math.Random(42);
    for (var i = 0; i < 8; i++) {
      final angle = random.nextDouble() * math.pi * 1.5 - math.pi * 0.25;
      final dist = random.nextDouble() * radius * 0.4;
      final x = crownCenterX + 4 + math.cos(angle) * dist + leafSway * 2;
      final y = crownCenterY - 2 + math.sin(angle) * dist * 0.4;
      final dotSize = 2.0 + random.nextDouble() * 4;
      canvas.drawCircle(Offset(x, y), dotSize, Paint()..color = lightGreen.withOpacity(crownAlpha * 0.6));
    }
    
    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAfter ? const Color(0xFF2E7D32) : const Color(0xFF555555),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, 4));
    
    // Crown diameter
    final diamText = TextPainter(
      text: TextSpan(
        text: '${crownDiameterM.toStringAsFixed(1)}m',
        style: TextStyle(fontSize: 9, color: Colors.brown.shade700, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    );
    diamText.layout();
    diamText.paint(canvas, Offset((size.width - diamText.width) / 2, groundY + 3));
  }

  @override
  bool shouldRepaint(covariant _AnimatedTreePainter oldDelegate) {
    return oldDelegate.crownDiameterM != crownDiameterM ||
        oldDelegate.fullness != fullness ||
        oldDelegate.sway != sway ||
        oldDelegate.leafSway != leafSway;
  }
}

/// Graph showing critical residual wall % vs wind speed.
/// Shows how much decay the tree can tolerate before failure at each wind speed.
class DecayToleranceVsWindGraph extends StatelessWidget {
  final List<double> windSpeeds;
  final List<double> criticalResidualWallPercents;
  final double? designWindSpeed;
  final double? currentResidualPercent;

  const DecayToleranceVsWindGraph({
    super.key,
    required this.windSpeeds,
    required this.criticalResidualWallPercents,
    this.designWindSpeed,
    this.currentResidualPercent,
  });

  @override
  Widget build(BuildContext context) {
    if (windSpeeds.length < 2 || criticalResidualWallPercents.length < 2) {
      return const Text(
        'Decay tolerance vs wind speed graph will display after a calculation.',
      );
    }

    if (windSpeeds.length != criticalResidualWallPercents.length) {
      return const Text(
        'Unable to plot decay tolerance graph (internal data mismatch).',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Figure A3 – Critical residual wall (%) vs wind speed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        const Text(
          'Shows minimum sound wood required to avoid failure at each wind speed',
          style: TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomPaint(
                size: Size.infinite,
                painter: _DecayTolerancePainter(
                  windSpeeds: windSpeeds,
                  criticalWalls: criticalResidualWallPercents,
                  designWindSpeed: designWindSpeed,
                  currentResidualPercent: currentResidualPercent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DecayTolerancePainter extends CustomPainter {
  final List<double> windSpeeds;
  final List<double> criticalWalls;
  final double? designWindSpeed;
  final double? currentResidualPercent;

  _DecayTolerancePainter({
    required this.windSpeeds,
    required this.criticalWalls,
    this.designWindSpeed,
    this.currentResidualPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (windSpeeds.isEmpty || criticalWalls.isEmpty || windSpeeds.length != criticalWalls.length) return;

    final validPairs = <MapEntry<double, double>>[];
    for (var i = 0; i < windSpeeds.length; i++) {
      final w = windSpeeds[i];
      final c = criticalWalls[i];
      if (w.isFinite && c.isFinite && c > 0 && c <= 100) {
        validPairs.add(MapEntry(w, c));
      }
    }
    if (validPairs.length < 2) return;

    final xs = validPairs.map((e) => e.key).toList();
    final ys = validPairs.map((e) => e.value).toList();

    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    if (maxX <= minX) return;

    const minY = 0.0;
    const maxY = 100.0;

    const double leftPad = 50;
    const double rightPad = 16;
    const double topPad = 20;
    const double bottomPad = 40;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final axisPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1.5;

    final linePaint = Paint()
      ..color = Colors.purple.shade700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final dangerZonePaint = Paint()
      ..color = Colors.red.shade100;

    final safeZonePaint = Paint()
      ..color = Colors.green.shade50;

    final origin = Offset(leftPad, size.height - bottomPad);

    double xToPx(double x) => origin.dx + (x - minX) / (maxX - minX) * chartWidth;
    double yToPx(double y) => origin.dy - (y - minY) / (maxY - minY) * chartHeight;

    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );

    // Fill zones - area ABOVE curve is "safe zone" (enough wall), 
    // area BELOW curve is "failure zone" (not enough wall)
    
    // Draw the safe zone (ABOVE the critical wall curve = enough sound wood)
    final safePath = Path();
    safePath.moveTo(xToPx(xs.first), topPad);
    for (var i = 0; i < xs.length; i++) {
      safePath.lineTo(xToPx(xs[i]), yToPx(ys[i]));
    }
    safePath.lineTo(xToPx(xs.last), topPad);
    safePath.close();
    canvas.drawPath(safePath, safeZonePaint);

    // Draw the failure zone (BELOW the critical wall curve = not enough wall)
    final failPath = Path();
    failPath.moveTo(xToPx(xs.first), origin.dy);
    for (var i = 0; i < xs.length; i++) {
      failPath.lineTo(xToPx(xs[i]), yToPx(ys[i]));
    }
    failPath.lineTo(xToPx(xs.last), origin.dy);
    failPath.close();
    canvas.drawPath(failPath, dangerZonePaint);

    // Draw horizontal grid lines and Y-axis labels every 20%
    for (double pct = 0; pct <= 100; pct += 20) {
      final y = yToPx(pct);
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + chartWidth, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: '${pct.toStringAsFixed(0)}%',
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 4, y - 5));
    }

    // Draw vertical grid lines
    final xRange = maxX - minX;
    final xStep = xRange > 30 ? 10.0 : (xRange > 15 ? 5.0 : 2.0);
    for (double xVal = (minX / xStep).ceil() * xStep; xVal <= maxX; xVal += xStep) {
      final px = xToPx(xVal);
      canvas.drawLine(Offset(px, origin.dy), Offset(px, topPad), gridPaint);
    }

    // Axes
    canvas.drawLine(origin, Offset(origin.dx + chartWidth, origin.dy), axisPaint);
    canvas.drawLine(origin, Offset(origin.dx, topPad), axisPaint);

    // Plot the critical wall curve
    final path = Path();
    for (var i = 0; i < xs.length; i++) {
      final px = xToPx(xs[i]);
      final py = yToPx(ys[i].clamp(minY, maxY));
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.purple.shade900
      ..style = PaintingStyle.fill;
    for (var i = 0; i < xs.length; i++) {
      final px = xToPx(xs[i]);
      final py = yToPx(ys[i].clamp(minY, maxY));
      canvas.drawCircle(Offset(px, py), 4, pointPaint);
    }

    // Draw design wind speed marker
    if (designWindSpeed != null && designWindSpeed! >= minX && designWindSpeed! <= maxX) {
      final px = xToPx(designWindSpeed!);
      final dashPaint = Paint()
        ..color = Colors.blue.shade600
        ..strokeWidth = 2;
      for (double dy = topPad; dy < origin.dy; dy += 8) {
        canvas.drawLine(Offset(px, dy), Offset(px, math.min(dy + 4, origin.dy)), dashPaint);
      }
    }

    // Draw current residual wall marker (horizontal line)
    if (currentResidualPercent != null && currentResidualPercent! >= minY && currentResidualPercent! <= maxY) {
      final py = yToPx(currentResidualPercent!);
      final currentPaint = Paint()
        ..color = Colors.green.shade600
        ..strokeWidth = 2;
      for (double dx = origin.dx; dx < origin.dx + chartWidth; dx += 8) {
        canvas.drawLine(Offset(dx, py), Offset(math.min(dx + 4, origin.dx + chartWidth), py), currentPaint);
      }
    }

    // X-axis labels
    void drawXLabel(String text, double xPos, {Color? color}) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: color ?? Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, origin.dy + 4));
    }

    drawXLabel('${minX.toStringAsFixed(0)}', origin.dx);
    drawXLabel('${maxX.toStringAsFixed(0)} m/s', origin.dx + chartWidth);

    if (designWindSpeed != null && designWindSpeed! > minX + 5 && designWindSpeed! < maxX - 5) {
      drawXLabel('${designWindSpeed!.toStringAsFixed(0)}', xToPx(designWindSpeed!), color: Colors.blue.shade700);
    }

    // Y-axis title
    textPainter.text = const TextSpan(
      text: 'Min. Wall',
      style: TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(2, topPad - 2));

    // X-axis title
    textPainter.text = const TextSpan(
      text: 'Wind Speed (m/s)',
      style: TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(origin.dx + chartWidth / 2 - textPainter.width / 2, size.height - 14));

    // Legend
    final legendY = topPad + 6;
    final legendX = origin.dx + 8;

    // Zone labels - Green (safe) at top, Red (failure) below
    canvas.drawRect(Rect.fromLTWH(legendX, legendY, 12, 12), safeZonePaint);
    canvas.drawRect(
      Rect.fromLTWH(legendX, legendY, 12, 12),
      Paint()..color = Colors.green.shade300..style = PaintingStyle.stroke..strokeWidth = 1,
    );
    textPainter.text = const TextSpan(
      text: 'SAFE (above critical line)',
      style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 16, legendY));

    canvas.drawRect(Rect.fromLTWH(legendX, legendY + 16, 12, 12), dangerZonePaint);
    canvas.drawRect(
      Rect.fromLTWH(legendX, legendY + 16, 12, 12),
      Paint()..color = Colors.red.shade300..style = PaintingStyle.stroke..strokeWidth = 1,
    );
    textPainter.text = const TextSpan(
      text: 'FAILURE (below critical line)',
      style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 16, legendY + 16));

    // Current wall legend
    if (currentResidualPercent != null) {
      canvas.drawLine(
        Offset(legendX + 180, legendY + 6),
        Offset(legendX + 196, legendY + 6),
        Paint()..color = Colors.green.shade600..strokeWidth = 2,
      );
      textPainter.text = TextSpan(
        text: 'Current: ${currentResidualPercent!.toStringAsFixed(0)}%',
        style: const TextStyle(fontSize: 9, color: Colors.green),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 200, legendY + 2));
    }

    if (designWindSpeed != null) {
      canvas.drawLine(
        Offset(legendX + 180, legendY + 20),
        Offset(legendX + 196, legendY + 20),
        Paint()..color = Colors.blue.shade600..strokeWidth = 2,
      );
      textPainter.text = const TextSpan(
        text: 'Design wind',
        style: TextStyle(fontSize: 9, color: Colors.blue),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 200, legendY + 16));
    }
  }

  @override
  bool shouldRepaint(covariant _DecayTolerancePainter oldDelegate) {
    return oldDelegate.windSpeeds != windSpeeds ||
           oldDelegate.criticalWalls != criticalWalls ||
           oldDelegate.designWindSpeed != designWindSpeed ||
           oldDelegate.currentResidualPercent != currentResidualPercent;
  }
}

/// Cross-section visualization showing stem with cavity.
class CrossSectionDiagram extends StatelessWidget {
  final double dbhCm;
  final double? cavityDiameterCm;
  final double? bendingStressMPa;
  final double? strengthMPa;

  const CrossSectionDiagram({
    super.key,
    required this.dbhCm,
    this.cavityDiameterCm,
    this.bendingStressMPa,
    this.strengthMPa,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cross-section diagram',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: _CrossSectionPainter(
                dbhCm: dbhCm,
                cavityDiameterCm: cavityDiameterCm,
                bendingStressMPa: bendingStressMPa,
                strengthMPa: strengthMPa,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CrossSectionPainter extends CustomPainter {
  final double dbhCm;
  final double? cavityDiameterCm;
  final double? bendingStressMPa;
  final double? strengthMPa;

  _CrossSectionPainter({
    required this.dbhCm,
    this.cavityDiameterCm,
    this.bendingStressMPa,
    this.strengthMPa,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.35;
    final centerY = size.height * 0.5;
    final maxRadius = math.min(size.width * 0.3, size.height * 0.4);
    
    final outerRadius = maxRadius;
    final cavityRadius = cavityDiameterCm != null && cavityDiameterCm! > 0
        ? maxRadius * (cavityDiameterCm! / dbhCm)
        : 0.0;
    
    // Draw outer stem (wood)
    final woodPaint = Paint()
      ..color = Colors.brown.shade300
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), outerRadius, woodPaint);
    
    // Draw bark ring
    final barkPaint = Paint()
      ..color = Colors.brown.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(centerX, centerY), outerRadius, barkPaint);
    
    // Draw cavity (if present)
    if (cavityRadius > 0) {
      final cavityPaint = Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), cavityRadius, cavityPaint);
      
      // Cavity border
      final cavityBorderPaint = Paint()
        ..color = Colors.grey.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(centerX, centerY), cavityRadius, cavityBorderPaint);
    }
    
    // Draw dimension lines and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Outer diameter label
    final dimLinePaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1;
    
    // Horizontal dimension line for DBH
    final leftX = centerX - outerRadius;
    final rightX = centerX + outerRadius;
    canvas.drawLine(Offset(leftX, centerY + outerRadius + 20), 
                    Offset(rightX, centerY + outerRadius + 20), dimLinePaint);
    canvas.drawLine(Offset(leftX, centerY + outerRadius + 15), 
                    Offset(leftX, centerY + outerRadius + 25), dimLinePaint);
    canvas.drawLine(Offset(rightX, centerY + outerRadius + 15), 
                    Offset(rightX, centerY + outerRadius + 25), dimLinePaint);
    
    textPainter.text = TextSpan(
      text: 'DBH: ${dbhCm.toStringAsFixed(0)} cm',
      style: const TextStyle(fontSize: 11, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, centerY + outerRadius + 25));
    
    // Wall thickness annotation
    if (cavityRadius > 0) {
      final wallThicknessCm = (dbhCm - (cavityDiameterCm ?? 0)) / 2;
      final residualWallPct = ((dbhCm - (cavityDiameterCm ?? 0)) / dbhCm) * 100;
      
      // Wall thickness line
      canvas.drawLine(Offset(centerX + cavityRadius, centerY - 10),
                      Offset(centerX + outerRadius, centerY - 10), dimLinePaint);
      
      textPainter.text = TextSpan(
        text: 't = ${wallThicknessCm.toStringAsFixed(1)} cm',
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX + cavityRadius + 2, centerY - 25));
      
      // Cavity diameter
      textPainter.text = TextSpan(
        text: 'Cavity: ${cavityDiameterCm!.toStringAsFixed(0)} cm',
        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, centerY - 8));
      
      // Residual wall percentage
      textPainter.text = TextSpan(
        text: 'Residual wall: ${residualWallPct.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 11, 
          color: residualWallPct < 30 ? Colors.red : Colors.green.shade700,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, centerY + 8));
    }
    
    // Right side: stress/strength info
    final infoX = size.width * 0.65;
    var infoY = 20.0;
    
    textPainter.text = const TextSpan(
      text: 'Section Properties',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 20;
    
    // Section modulus calculation
    final outerR = dbhCm / 2 / 100; // meters
    final innerR = (cavityDiameterCm ?? 0) / 2 / 100; // meters
    final I = (math.pi / 4) * (math.pow(outerR, 4) - math.pow(innerR, 4));
    final Z = I / outerR * 1e6; // cm³
    
    textPainter.text = TextSpan(
      text: 'Section modulus (Z): ${Z.toStringAsFixed(0)} cm³',
      style: const TextStyle(fontSize: 10, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 16;
    
    // Moment of inertia
    final Icm4 = I * 1e8; // convert to cm⁴
    textPainter.text = TextSpan(
      text: 'Moment of inertia (I): ${(Icm4 / 1000).toStringAsFixed(1)}×10³ cm⁴',
      style: const TextStyle(fontSize: 10, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 16;
    
    // Cross-sectional area
    final A = math.pi * (math.pow(outerR, 2) - math.pow(innerR, 2)) * 1e4; // cm²
    textPainter.text = TextSpan(
      text: 'Cross-sectional area: ${A.toStringAsFixed(0)} cm²',
      style: const TextStyle(fontSize: 10, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 20;
    
    // Stress info
    if (bendingStressMPa != null) {
      textPainter.text = const TextSpan(
        text: 'Stress Analysis',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(infoX, infoY));
      infoY += 18;
      
      textPainter.text = TextSpan(
        text: 'Bending stress (σ): ${bendingStressMPa!.toStringAsFixed(2)} MPa',
        style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(infoX, infoY));
      infoY += 16;
      
      if (strengthMPa != null) {
        textPainter.text = TextSpan(
          text: 'Bending strength (fb): ${strengthMPa!.toStringAsFixed(1)} MPa',
          style: TextStyle(fontSize: 10, color: Colors.green.shade700),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(infoX, infoY));
        infoY += 16;
        
        final ratio = bendingStressMPa! / strengthMPa!;
        textPainter.text = TextSpan(
          text: 'Utilisation: ${(ratio * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.bold,
            color: ratio > 1.0 ? Colors.red : Colors.green.shade700,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(infoX, infoY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CrossSectionPainter oldDelegate) {
    return oldDelegate.dbhCm != dbhCm ||
           oldDelegate.cavityDiameterCm != cavityDiameterCm ||
           oldDelegate.bendingStressMPa != bendingStressMPa ||
           oldDelegate.strengthMPa != strengthMPa;
  }
}

/// Bending moment diagram showing stress distribution along stem height.
class BendingMomentDiagram extends StatelessWidget {
  final double heightM;
  final double maxMomentKNm;
  final double crownDiameterM;

  const BendingMomentDiagram({
    super.key,
    required this.heightM,
    required this.maxMomentKNm,
    required this.crownDiameterM,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bending moment distribution',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        const Text(
          'Shows how bending moment varies with height',
          style: TextStyle(fontSize: 10, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: _BendingMomentPainter(
                heightM: heightM,
                maxMomentKNm: maxMomentKNm,
                crownDiameterM: crownDiameterM,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BendingMomentPainter extends CustomPainter {
  final double heightM;
  final double maxMomentKNm;
  final double crownDiameterM;

  _BendingMomentPainter({
    required this.heightM,
    required this.maxMomentKNm,
    required this.crownDiameterM,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 50.0;
    const rightPad = 100.0;
    const topPad = 20.0;
    const bottomPad = 30.0;
    
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;
    
    final origin = Offset(leftPad, size.height - bottomPad);
    
    // Moment varies approximately quadratically from 0 at top to max at base
    // M(z) = M_base * (1 - z/H)² approximately for wind loading on a cantilever
    
    final axisPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5;
    
    final momentPaint = Paint()
      ..color = Colors.purple.shade600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..color = Colors.purple.shade100
      ..style = PaintingStyle.fill;
    
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;
    
    // Draw tree outline on left
    final treePaint = Paint()
      ..color = Colors.brown.shade400
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final treeX = leftPad - 25;
    canvas.drawLine(
      Offset(treeX, origin.dy),
      Offset(treeX, topPad + 20),
      treePaint,
    );
    
    // Crown
    final crownPaint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(treeX, topPad + 10), 15, crownPaint);
    
    // Axes
    canvas.drawLine(origin, Offset(origin.dx + chartWidth, origin.dy), axisPaint);
    canvas.drawLine(origin, Offset(origin.dx, topPad), axisPaint);
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Y-axis labels (height)
    for (var h = 0.0; h <= heightM; h += heightM / 4) {
      final y = origin.dy - (h / heightM) * chartHeight;
      canvas.drawLine(Offset(origin.dx - 3, y), Offset(origin.dx, y), axisPaint);
      canvas.drawLine(Offset(origin.dx, y), Offset(origin.dx + chartWidth, y), gridPaint);
      
      textPainter.text = TextSpan(
        text: '${h.toStringAsFixed(1)}m',
        style: const TextStyle(fontSize: 9, color: Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 5, y - 5));
    }
    
    // X-axis labels (moment)
    for (var m = 0.0; m <= maxMomentKNm; m += maxMomentKNm / 4) {
      final x = origin.dx + (m / maxMomentKNm) * chartWidth;
      canvas.drawLine(Offset(x, origin.dy), Offset(x, origin.dy + 3), axisPaint);
      
      textPainter.text = TextSpan(
        text: '${m.toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 9, color: Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, origin.dy + 5));
    }
    
    // Draw moment curve (quadratic distribution)
    final fillPath = Path();
    final linePath = Path();
    fillPath.moveTo(origin.dx, origin.dy);
    linePath.moveTo(origin.dx, origin.dy);
    
    const steps = 30;
    for (var i = 0; i <= steps; i++) {
      final hFrac = i / steps;
      // Moment decreases from base (hFrac=0) to top (hFrac=1)
      // M(z) ≈ M_base * (1 - z/H)² for distributed wind load
      final mFrac = math.pow(1 - hFrac, 2);
      
      final y = origin.dy - hFrac * chartHeight;
      final x = origin.dx + mFrac * chartWidth;
      
      fillPath.lineTo(x, y);
      linePath.lineTo(x, y);
    }
    
    fillPath.lineTo(origin.dx, topPad);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, momentPaint);
    
    // Labels
    textPainter.text = const TextSpan(
      text: 'Height (m)',
      style: TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(4, topPad));
    
    textPainter.text = const TextSpan(
      text: 'Bending Moment (kN·m)',
      style: TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(origin.dx + chartWidth / 2 - textPainter.width / 2, size.height - 12));
    
    // Key values on right side
    final infoX = origin.dx + chartWidth + 10;
    var infoY = topPad;
    
    textPainter.text = const TextSpan(
      text: 'Key Values',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 18;
    
    textPainter.text = TextSpan(
      text: 'M_base:',
      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 14;
    
    textPainter.text = TextSpan(
      text: '${maxMomentKNm.toStringAsFixed(1)} kN·m',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 20;
    
    textPainter.text = TextSpan(
      text: 'Height:',
      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 14;
    
    textPainter.text = TextSpan(
      text: '${heightM.toStringAsFixed(1)} m',
      style: const TextStyle(fontSize: 11, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(infoX, infoY));
    infoY += 20;
    
    // Critical point annotation
    final critY = origin.dy;
    final critX = origin.dx + chartWidth;
    
    canvas.drawCircle(Offset(critX, critY), 5, Paint()..color = Colors.red);
    textPainter.text = const TextSpan(
      text: '← Critical\n   (max stress)',
      style: TextStyle(fontSize: 9, color: Colors.red),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(critX + 8, critY - 10));
  }

  @override
  bool shouldRepaint(covariant _BendingMomentPainter oldDelegate) {
    return oldDelegate.heightM != heightM ||
           oldDelegate.maxMomentKNm != maxMomentKNm ||
           oldDelegate.crownDiameterM != crownDiameterM;
  }
}

/// Multi-scenario comparison showing SF at different wind speeds.
class WindScenarioComparison extends StatelessWidget {
  final Map<String, double> scenarioSafetyFactors; // label -> SF

  const WindScenarioComparison({
    super.key,
    required this.scenarioSafetyFactors,
  });

  @override
  Widget build(BuildContext context) {
    if (scenarioSafetyFactors.isEmpty) {
      return const Text('No scenario data available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wind region comparison',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        const Text(
          'Safety factor at different regional wind speeds',
          style: TextStyle(fontSize: 10, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScenarioComparisonPainter(
                scenarios: scenarioSafetyFactors,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScenarioComparisonPainter extends CustomPainter {
  final Map<String, double> scenarios;

  _ScenarioComparisonPainter({required this.scenarios});

  @override
  void paint(Canvas canvas, Size size) {
    if (scenarios.isEmpty) return;
    
    const leftPad = 50.0;
    const rightPad = 20.0;
    const topPad = 20.0;
    const bottomPad = 50.0;
    
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;
    
    final entries = scenarios.entries.toList();
    final barWidth = chartWidth / entries.length * 0.7;
    final spacing = chartWidth / entries.length;
    
    double maxSF = entries.map((e) => e.value).reduce(math.max);
    maxSF = math.max(maxSF, 2.0);
    maxSF = (maxSF * 1.2).ceilToDouble();
    
    final origin = Offset(leftPad, size.height - bottomPad);
    
    final axisPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5;
    
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;
    
    final criticalPaint = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 1.5;
    
    // Axes
    canvas.drawLine(origin, Offset(origin.dx + chartWidth, origin.dy), axisPaint);
    canvas.drawLine(origin, Offset(origin.dx, topPad), axisPaint);
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Y-axis labels and grid
    for (var sf = 0.0; sf <= maxSF; sf += 0.5) {
      final y = origin.dy - (sf / maxSF) * chartHeight;
      final isCritical = (sf - 1.0).abs() < 0.01;
      
      canvas.drawLine(
        Offset(origin.dx, y), 
        Offset(origin.dx + chartWidth, y), 
        isCritical ? criticalPaint : gridPaint,
      );
      
      textPainter.text = TextSpan(
        text: sf.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 9, 
          color: isCritical ? Colors.red : Colors.black87,
          fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 4, y - 5));
    }
    
    // Draw bars
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final sf = entry.value;
      
      final barHeight = (sf / maxSF) * chartHeight;
      final barLeft = origin.dx + i * spacing + (spacing - barWidth) / 2;
      
      // Bar color based on SF
      Color barColor;
      if (sf >= 1.5) {
        barColor = Colors.green.shade400;
      } else if (sf >= 1.0) {
        barColor = Colors.orange.shade400;
      } else {
        barColor = Colors.red.shade400;
      }
      
      final barRect = Rect.fromLTWH(
        barLeft, 
        origin.dy - barHeight, 
        barWidth, 
        barHeight,
      );
      
      canvas.drawRect(barRect, Paint()..color = barColor);
      canvas.drawRect(barRect, Paint()
        ..color = barColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      
      // SF value on top of bar
      textPainter.text = TextSpan(
        text: sf.toStringAsFixed(2),
        style: TextStyle(
          fontSize: 10, 
          fontWeight: FontWeight.bold,
          color: sf >= 1.0 ? Colors.black87 : Colors.red,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        barLeft + barWidth / 2 - textPainter.width / 2, 
        origin.dy - barHeight - 14,
      ));
      
      // Label below bar
      textPainter.text = TextSpan(
        text: entry.key,
        style: const TextStyle(fontSize: 9, color: Colors.black87),
      );
      textPainter.layout();
      
      // Rotate label if needed
      canvas.save();
      canvas.translate(barLeft + barWidth / 2, origin.dy + 5);
      canvas.rotate(-0.4);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
      canvas.restore();
    }
    
    // Y-axis title
    textPainter.text = const TextSpan(
      text: 'SF',
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(4, topPad - 2));
    
    // Critical line label
    final critY = origin.dy - (1.0 / maxSF) * chartHeight;
    textPainter.text = const TextSpan(
      text: 'SF=1',
      style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(origin.dx + chartWidth + 4, critY - 5));
  }

  @override
  bool shouldRepaint(covariant _ScenarioComparisonPainter oldDelegate) {
    return oldDelegate.scenarios != scenarios;
  }
}

/// Defect factor breakdown showing contribution of each factor.
class DefectFactorBreakdown extends StatelessWidget {
  final Map<String, double> factorContributions; // label -> factor value (0-1)
  final double combinedFactor;

  const DefectFactorBreakdown({
    super.key,
    required this.factorContributions,
    required this.combinedFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Defect factor breakdown',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          'Combined k_defect = ${combinedFactor.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11, 
            color: combinedFactor >= 0.7 ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 150,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: _DefectBreakdownPainter(
                factors: factorContributions,
                combined: combinedFactor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DefectBreakdownPainter extends CustomPainter {
  final Map<String, double> factors;
  final double combined;

  _DefectBreakdownPainter({required this.factors, required this.combined});

  @override
  void paint(Canvas canvas, Size size) {
    if (factors.isEmpty) return;
    
    const leftPad = 120.0;
    const rightPad = 50.0;
    const topPad = 15.0;
    const bottomPad = 25.0;
    
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;
    
    final entries = factors.entries.toList();
    final barHeight = chartHeight / (entries.length + 1) * 0.7;
    final spacing = chartHeight / (entries.length + 1);
    
    final origin = Offset(leftPad, topPad);
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw factor bars
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final factor = entry.value;
      
      final barTop = origin.dy + i * spacing + (spacing - barHeight) / 2;
      final barWidthPx = factor * chartWidth;
      
      // Color based on factor value
      Color barColor;
      if (factor >= 0.9) {
        barColor = Colors.green.shade300;
      } else if (factor >= 0.7) {
        barColor = Colors.orange.shade300;
      } else {
        barColor = Colors.red.shade300;
      }
      
      final barRect = Rect.fromLTWH(origin.dx, barTop, barWidthPx, barHeight);
      canvas.drawRect(barRect, Paint()..color = barColor);
      canvas.drawRect(barRect, Paint()
        ..color = Colors.grey.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      
      // Label on left
      textPainter.text = TextSpan(
        text: entry.key,
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 5, barTop + barHeight / 2 - 5));
      
      // Value on right of bar
      textPainter.text = TextSpan(
        text: '×${factor.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 10, 
          fontWeight: FontWeight.bold,
          color: factor >= 0.8 ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx + barWidthPx + 5, barTop + barHeight / 2 - 5));
    }
    
    // Combined factor bar (highlighted)
    final combinedTop = origin.dy + entries.length * spacing + (spacing - barHeight) / 2;
    final combinedWidthPx = combined * chartWidth;
    
    final combinedColor = combined >= 0.7 
        ? Colors.green.shade500 
        : combined >= 0.4 
            ? Colors.orange.shade500 
            : Colors.red.shade500;
    
    final combinedRect = Rect.fromLTWH(origin.dx, combinedTop, combinedWidthPx, barHeight);
    canvas.drawRect(combinedRect, Paint()..color = combinedColor);
    canvas.drawRect(combinedRect, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    
    textPainter.text = const TextSpan(
      text: 'COMBINED',
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 5, combinedTop + barHeight / 2 - 5));
    
    textPainter.text = TextSpan(
      text: '= ${combined.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 11, 
        fontWeight: FontWeight.bold,
        color: combinedColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(origin.dx + combinedWidthPx + 5, combinedTop + barHeight / 2 - 5));
    
    // Scale line at 1.0
    final fullX = origin.dx + chartWidth;
    canvas.drawLine(
      Offset(fullX, topPad),
      Offset(fullX, size.height - bottomPad),
      Paint()..color = Colors.grey.shade400..strokeWidth = 1,
    );
    
    textPainter.text = const TextSpan(
      text: '1.0',
      style: TextStyle(fontSize: 9, color: Colors.grey),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(fullX - textPainter.width / 2, size.height - bottomPad + 5));
  }

  @override
  bool shouldRepaint(covariant _DefectBreakdownPainter oldDelegate) {
    return oldDelegate.factors != factors || oldDelegate.combined != combined;
  }
}

/// Interactive live wind load simulator with realistic animated tree.
class LiveWindLoadSimulator extends StatefulWidget {
  final double dbhCm;
  final double heightM;
  final double crownDiameterM;
  final double? cavityDiameterCm;
  final double speciesStrengthMPa;
  final double defectFactor;
  final double siteFactor;
  final double designWindSpeed;
  final Function(double windSpeed, double safetyFactor, bool hasFailed)? onUpdate;

  const LiveWindLoadSimulator({
    super.key,
    required this.dbhCm,
    required this.heightM,
    required this.crownDiameterM,
    this.cavityDiameterCm,
    required this.speciesStrengthMPa,
    this.defectFactor = 1.0,
    this.siteFactor = 1.0,
    required this.designWindSpeed,
    this.onUpdate,
  });

  @override
  State<LiveWindLoadSimulator> createState() => _LiveWindLoadSimulatorState();
}

class _LiveWindLoadSimulatorState extends State<LiveWindLoadSimulator>
    with TickerProviderStateMixin {
  double _currentWindSpeed = 0.0;
  double _safetyFactor = 10.0;
  bool _hasFailed = false;
  bool _isAnimating = false;
  double _failureWindSpeed = 0.0;
  
  // Additional load factors
  int _stemCount = 1; // 1-5 stems
  double _leanAngle = 0.0; // degrees from vertical (-30 to +30)
  double _crownAsymmetry = 0.0; // -1 (left heavy) to +1 (right heavy)
  bool _hasDeadwood = false;
  bool _hasHangingBranches = false;
  bool _isExposed = false; // hilltop/edge exposure
  double _targetProximity = 0.0; // 0 = no target, 1 = target directly below
  bool _showOptions = false;
  
  // Defect/fungi location: 0=none, 1=base, 2=mid-trunk, 3=upper-trunk, 4=branch-union
  int _defectLocation = 0;
  
  // Cavity type: 0=closed/internal, 1=open cavity, 2=pipe/hollow
  int _cavityType = 0;
  double _cavityOpeningAngle = 90.0; // degrees of opening for open cavity
  
  // Pruning comparison mode
  bool _showPruningComparison = false;
  double _crownReductionPercent = 20.0;
  
  late AnimationController _swayController;
  late AnimationController _failureController;
  late AnimationController _leafController;
  late Animation<double> _swayAnimation;
  late Animation<double> _failureAnimation;
  late Animation<double> _leafAnimation;

  @override
  void initState() {
    super.initState();
    _currentWindSpeed = widget.designWindSpeed * 0.3;
    
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _swayAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );
    
    _failureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _failureAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _failureController, curve: Curves.easeIn),
    );
    
    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _leafAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leafController, curve: Curves.easeInOut),
    );
    
    _calculateSF();
    _calculateFailurePoint();
  }

  @override
  void dispose() {
    _swayController.dispose();
    _failureController.dispose();
    _leafController.dispose();
    super.dispose();
  }

  double _getLoadMultiplier() {
    double mult = 1.0;
    
    // Multi-stem: increases load due to multiple catch points
    mult *= 1.0 + (_stemCount - 1) * 0.15;
    
    // Lean: increases moment arm
    mult *= 1.0 + (_leanAngle.abs() / 30) * 0.3;
    
    // Crown asymmetry: increases effective load
    mult *= 1.0 + _crownAsymmetry.abs() * 0.2;
    
    // Deadwood: adds weight
    if (_hasDeadwood) mult *= 1.1;
    
    // Hanging branches: sail effect
    if (_hasHangingBranches) mult *= 1.15;
    
    // Exposed position: higher wind speeds
    if (_isExposed) mult *= 1.25;
    
    return mult;
  }

  void _calculateFailurePoint() {
    double low = 10.0;
    double high = 100.0;
    
    for (var i = 0; i < 20; i++) {
      final mid = (low + high) / 2;
      final sf = _calculateSFAtWind(mid);
      
      if ((sf - 1.0).abs() < 0.01) {
        _failureWindSpeed = mid;
        break;
      }
      
      if (sf > 1.0) {
        low = mid;
      } else {
        high = mid;
      }
      _failureWindSpeed = mid;
    }
  }

  double _calculateSFAtWind(double windSpeed) {
    final rho = 1.2;
    final Cd = 1.2;
    final loadMult = _getLoadMultiplier();
    final q = 0.5 * rho * windSpeed * windSpeed * Cd * widget.siteFactor * loadMult;
    
    final crownArea = math.pi / 4 * widget.crownDiameterM * widget.crownDiameterM * 0.7;
    final force = q * crownArea;
    final moment = force * widget.heightM * 0.7;
    
    final outerR = widget.dbhCm / 2 / 100;
    final innerR = (widget.cavityDiameterCm ?? 0) / 2 / 100;
    final I = (math.pi / 4) * (math.pow(outerR, 4) - math.pow(innerR, 4));
    final Z = I / outerR;
    
    final stress = moment / Z / 1e6;
    final strength = widget.speciesStrengthMPa * widget.defectFactor;
    
    return strength / stress;
  }

  void _calculateSF() {
    final sf = _calculateSFAtWind(_currentWindSpeed);
    final wasFailed = _hasFailed;
    
    setState(() {
      _safetyFactor = sf;
      _hasFailed = sf < 1.0;
    });
    
    if (_hasFailed && !wasFailed) {
      _failureController.forward();
    } else if (!_hasFailed && wasFailed) {
      _failureController.reset();
    }
    
    _calculateFailurePoint();
    widget.onUpdate?.call(_currentWindSpeed, sf, _hasFailed);
  }

  void _onWindChanged(double value) {
    setState(() {
      _currentWindSpeed = value;
    });
    _calculateSF();
  }

  void _startWindAnimation() {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
      _currentWindSpeed = 5.0;
      _hasFailed = false;
    });
    _failureController.reset();
    
    _animateWind();
  }

  void _animateWind() async {
    while (_isAnimating && _currentWindSpeed < 80 && !_hasFailed) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted || !_isAnimating) break;
      
      setState(() {
        _currentWindSpeed += 0.5;
      });
      _calculateSF();
    }
    
    if (mounted) {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _stopAnimation() {
    setState(() {
      _isAnimating = false;
    });
  }

  void _reset() {
    setState(() {
      _currentWindSpeed = widget.designWindSpeed * 0.3;
      _hasFailed = false;
      _isAnimating = false;
    });
    _failureController.reset();
    _calculateSF();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final deflectionFactor = (_currentWindSpeed / 60.0).clamp(0.0, 1.5);
    final stressRatio = (1.0 / _safetyFactor).clamp(0.0, 2.0);
    
    Color stemColor;
    if (_hasFailed) {
      stemColor = Colors.red.shade900;
    } else if (stressRatio > 0.8) {
      stemColor = Colors.red.shade600;
    } else if (stressRatio > 0.6) {
      stemColor = Colors.orange.shade600;
    } else if (stressRatio > 0.4) {
      stemColor = Colors.yellow.shade700;
    } else {
      stemColor = Colors.brown.shade600;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Live Wind Load Simulator', style: theme.textTheme.titleLarge),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showOptions = !_showOptions),
                  icon: Icon(_showOptions ? Icons.expand_less : Icons.settings),
                  label: Text(_showOptions ? 'Hide options' : 'Tree options'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Realistic tree model based on your inputs. Load multiplier: ${_getLoadMultiplier().toStringAsFixed(2)}x',
              style: theme.textTheme.bodySmall,
            ),
            
            // Expandable options panel
            if (_showOptions) ...[
              const Divider(),
              Text('Tree Configuration', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              
              // Multi-stem selector
              Row(
                children: [
                  const Text('Stem count: '),
                  const SizedBox(width: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1')),
                      ButtonSegment(value: 2, label: Text('2')),
                      ButtonSegment(value: 3, label: Text('3')),
                      ButtonSegment(value: 4, label: Text('4+')),
                    ],
                    selected: {_stemCount.clamp(1, 4)},
                    onSelectionChanged: (v) {
                      setState(() => _stemCount = v.first);
                      _calculateSF();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Lean angle
              Row(
                children: [
                  const SizedBox(width: 100, child: Text('Lean angle:')),
                  Expanded(
                    child: Slider(
                      value: _leanAngle,
                      min: -30,
                      max: 30,
                      divisions: 12,
                      label: '${_leanAngle.toStringAsFixed(0)}°',
                      onChanged: (v) {
                        setState(() => _leanAngle = v);
                        _calculateSF();
                      },
                    ),
                  ),
                  SizedBox(width: 50, child: Text('${_leanAngle.toStringAsFixed(0)}°')),
                ],
              ),
              
              // Crown asymmetry
              Row(
                children: [
                  const SizedBox(width: 100, child: Text('Crown bias:')),
                  Expanded(
                    child: Slider(
                      value: _crownAsymmetry,
                      min: -1.0,
                      max: 1.0,
                      divisions: 10,
                      label: _crownAsymmetry < -0.3 ? 'Left' : _crownAsymmetry > 0.3 ? 'Right' : 'Balanced',
                      onChanged: (v) {
                        setState(() => _crownAsymmetry = v);
                        _calculateSF();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 60, 
                    child: Text(
                      _crownAsymmetry < -0.3 ? 'Left' : _crownAsymmetry > 0.3 ? 'Right' : 'Even',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: const Text('Deadwood'),
                    selected: _hasDeadwood,
                    onSelected: (v) {
                      setState(() => _hasDeadwood = v);
                      _calculateSF();
                    },
                  ),
                  FilterChip(
                    label: const Text('Hanging branches'),
                    selected: _hasHangingBranches,
                    onSelected: (v) {
                      setState(() => _hasHangingBranches = v);
                      _calculateSF();
                    },
                  ),
                  FilterChip(
                    label: const Text('Exposed position'),
                    selected: _isExposed,
                    onSelected: (v) {
                      setState(() => _isExposed = v);
                      _calculateSF();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              // Target proximity
              Row(
                children: [
                  const SizedBox(width: 100, child: Text('Target below:')),
                  Expanded(
                    child: Slider(
                      value: _targetProximity,
                      min: 0,
                      max: 1,
                      divisions: 4,
                      onChanged: (v) => setState(() => _targetProximity = v),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      _targetProximity < 0.25 ? 'None' : _targetProximity < 0.75 ? 'Near' : 'Direct',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              Text('Defect / Fungi Location', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('None'),
                    selected: _defectLocation == 0,
                    onSelected: (_) => setState(() => _defectLocation = 0),
                  ),
                  ChoiceChip(
                    label: const Text('Base'),
                    selected: _defectLocation == 1,
                    onSelected: (_) => setState(() => _defectLocation = 1),
                  ),
                  ChoiceChip(
                    label: const Text('Mid-trunk'),
                    selected: _defectLocation == 2,
                    onSelected: (_) => setState(() => _defectLocation = 2),
                  ),
                  ChoiceChip(
                    label: const Text('Upper'),
                    selected: _defectLocation == 3,
                    onSelected: (_) => setState(() => _defectLocation = 3),
                  ),
                  ChoiceChip(
                    label: const Text('Branch union'),
                    selected: _defectLocation == 4,
                    onSelected: (_) => setState(() => _defectLocation = 4),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              Text('Cavity Type', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('Closed/Internal'),
                    selected: _cavityType == 0,
                    onSelected: (_) => setState(() => _cavityType = 0),
                  ),
                  ChoiceChip(
                    label: const Text('Open cavity'),
                    selected: _cavityType == 1,
                    avatar: _cavityType == 1 ? const Icon(Icons.warning, size: 16, color: Colors.orange) : null,
                    onSelected: (_) => setState(() => _cavityType = 1),
                  ),
                  ChoiceChip(
                    label: const Text('Pipe/Hollow'),
                    selected: _cavityType == 2,
                    avatar: _cavityType == 2 ? const Icon(Icons.circle_outlined, size: 16, color: Colors.red) : null,
                    onSelected: (_) => setState(() => _cavityType = 2),
                  ),
                ],
              ),
              if (_cavityType == 1) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 100, child: Text('Opening size:')),
                    Expanded(
                      child: Slider(
                        value: _cavityOpeningAngle,
                        min: 30,
                        max: 180,
                        divisions: 5,
                        label: '${_cavityOpeningAngle.toStringAsFixed(0)}°',
                        onChanged: (v) => setState(() => _cavityOpeningAngle = v),
                      ),
                    ),
                    SizedBox(width: 40, child: Text('${_cavityOpeningAngle.toStringAsFixed(0)}°')),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _showPruningComparison,
                    onChanged: (v) => setState(() => _showPruningComparison = v ?? false),
                  ),
                  const Text('Show pruning comparison'),
                ],
              ),
              if (_showPruningComparison) ...[
                Row(
                  children: [
                    const SizedBox(width: 100, child: Text('Crown reduction:')),
                    Expanded(
                      child: Slider(
                        value: _crownReductionPercent,
                        min: 10,
                        max: 50,
                        divisions: 8,
                        label: '${_crownReductionPercent.toStringAsFixed(0)}%',
                        onChanged: (v) => setState(() => _crownReductionPercent = v),
                      ),
                    ),
                    SizedBox(width: 40, child: Text('${_crownReductionPercent.toStringAsFixed(0)}%')),
                  ],
                ),
              ],
              const Divider(),
            ],
            
            const SizedBox(height: 8),
            
            // Tree visualization - more realistic
            SizedBox(
              height: _showPruningComparison ? 360 : 320,
              child: AnimatedBuilder(
                animation: Listenable.merge([_swayAnimation, _failureAnimation, _leafAnimation]),
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _RealisticTreePainter(
                      dbhCm: widget.dbhCm,
                      heightM: widget.heightM,
                      crownDiameterM: widget.crownDiameterM,
                      deflection: deflectionFactor,
                      swayOffset: _swayAnimation.value * deflectionFactor * 0.3,
                      leafSway: _leafAnimation.value,
                      failureProgress: _failureAnimation.value,
                      stemColor: stemColor,
                      hasFailed: _hasFailed,
                      windSpeed: _currentWindSpeed,
                      safetyFactor: _safetyFactor,
                      failureWindSpeed: _failureWindSpeed,
                      designWindSpeed: widget.designWindSpeed,
                      residualWallPct: widget.cavityDiameterCm != null
                          ? ((widget.dbhCm - widget.cavityDiameterCm!) / widget.dbhCm) * 100
                          : 100.0,
                      stemCount: _stemCount,
                      leanAngle: _leanAngle,
                      crownAsymmetry: _crownAsymmetry,
                      hasDeadwood: _hasDeadwood,
                      hasHangingBranches: _hasHangingBranches,
                      targetProximity: _targetProximity,
                      defectLocation: _defectLocation,
                      showPruningComparison: _showPruningComparison,
                      crownReductionPercent: _crownReductionPercent,
                      cavityType: _cavityType,
                      cavityOpeningAngle: _cavityOpeningAngle,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Wind speed slider
            Row(
              children: [
                const Icon(Icons.air, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wind Speed: ${_currentWindSpeed.toStringAsFixed(1)} m/s',
                        style: theme.textTheme.titleMedium,
                      ),
                      Slider(
                        value: _currentWindSpeed.clamp(0.0, 80.0),
                        min: 0.0,
                        max: 80.0,
                        divisions: 80,
                        activeColor: _hasFailed ? Colors.red : Colors.blue,
                        onChanged: _isAnimating ? null : _onWindChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Status display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasFailed 
                    ? Colors.red.shade100 
                    : _safetyFactor < 1.5 
                        ? Colors.orange.shade100 
                        : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasFailed ? Colors.red : Colors.green,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasFailed ? Icons.dangerous : Icons.check_circle,
                    color: _hasFailed ? Colors.red : Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasFailed 
                              ? 'FAILURE - Tree has failed!' 
                              : 'SF = ${_safetyFactor.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _hasFailed ? Colors.red.shade900 : Colors.green.shade900,
                          ),
                        ),
                        Text(
                          _hasFailed
                              ? 'Wind exceeded structural capacity at ${_currentWindSpeed.toStringAsFixed(0)} m/s'
                              : 'Tree can withstand current wind load',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isAnimating ? _stopAnimation : _startWindAnimation,
                  icon: Icon(_isAnimating ? Icons.stop : Icons.play_arrow),
                  label: Text(_isAnimating ? 'Stop' : 'Animate to Failure'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnimating ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Key values
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _infoChip('Design wind', '${widget.designWindSpeed.toStringAsFixed(0)} m/s', Colors.blue),
                _infoChip('Failure wind', '${_failureWindSpeed.toStringAsFixed(0)} m/s', Colors.red),
                _infoChip('Stress ratio', '${(100 / _safetyFactor).toStringAsFixed(0)}%', 
                    stressRatio > 0.8 ? Colors.red : stressRatio > 0.5 ? Colors.orange : Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LiveTreePainter extends CustomPainter {
  final double deflection;
  final double swayOffset;
  final double failureProgress;
  final Color stemColor;
  final bool hasFailed;
  final double windSpeed;
  final double safetyFactor;
  final double failureWindSpeed;
  final double designWindSpeed;
  final double residualWallPct;

  _LiveTreePainter({
    required this.deflection,
    required this.swayOffset,
    required this.failureProgress,
    required this.stemColor,
    required this.hasFailed,
    required this.windSpeed,
    required this.safetyFactor,
    required this.failureWindSpeed,
    required this.designWindSpeed,
    required this.residualWallPct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final groundY = size.height - 40;
    final treeHeight = size.height - 100;
    
    // Ground
    final groundPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      groundPaint,
    );
    
    // Wind arrows
    _drawWindArrows(canvas, size, centerX);
    
    // Calculate bend points for the tree
    final bendAngle = (deflection + swayOffset) * 0.4; // radians
    final failureBend = failureProgress * 1.2; // additional bend on failure
    final totalBend = bendAngle + failureBend;
    
    // Draw tree stem with curve
    _drawBentStem(canvas, centerX, groundY, treeHeight, totalBend);
    
    // Draw crown
    _drawCrown(canvas, centerX, groundY, treeHeight, totalBend);
    
    // Draw roots
    _drawRoots(canvas, centerX, groundY);
    
    // Draw failure crack if failing
    if (hasFailed || failureProgress > 0) {
      _drawFailureCrack(canvas, centerX, groundY, treeHeight);
    }
    
    // Info panel on right
    _drawInfoPanel(canvas, size);
    
    // Wind speed gauge
    _drawWindGauge(canvas, size);
  }

  void _drawWindArrows(Canvas canvas, Size size, double centerX) {
    final arrowPaint = Paint()
      ..color = Colors.blue.shade400.withOpacity((windSpeed / 60).clamp(0.3, 1.0))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final arrowCount = (windSpeed / 15).ceil().clamp(1, 5);
    final arrowLength = 20 + windSpeed * 0.5;
    
    for (var i = 0; i < arrowCount; i++) {
      final y = 60.0 + i * 40;
      final startX = 20.0;
      final endX = startX + arrowLength;
      
      canvas.drawLine(Offset(startX, y), Offset(endX, y), arrowPaint);
      canvas.drawLine(Offset(endX, y), Offset(endX - 8, y - 6), arrowPaint);
      canvas.drawLine(Offset(endX, y), Offset(endX - 8, y + 6), arrowPaint);
    }
    
    // Wind speed label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${windSpeed.toStringAsFixed(0)} m/s',
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 30));
  }

  void _drawBentStem(Canvas canvas, double centerX, double groundY, double height, double bend) {
    final stemPaint = Paint()
      ..color = stemColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(centerX, groundY);
    
    // Create curved stem using quadratic bezier
    final segments = 10;
    for (var i = 1; i <= segments; i++) {
      final t = i / segments;
      final y = groundY - height * t;
      // Bend increases with height (cubic)
      final xOffset = math.pow(t, 2) * bend * height * 0.3;
      path.lineTo(centerX + xOffset, y);
    }
    
    canvas.drawPath(path, stemPaint);
    
    // Draw stem outline
    final outlinePaint = Paint()
      ..color = Colors.brown.shade900
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, outlinePaint..strokeWidth = 14);
    canvas.drawPath(path, stemPaint);
    
    // Draw cavity indicator if hollow
    if (residualWallPct < 100) {
      final cavityPaint = Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, cavityPaint);
    }
  }

  void _drawCrown(Canvas canvas, double centerX, double groundY, double height, double bend) {
    final topY = groundY - height;
    final xOffset = math.pow(1.0, 2) * bend * height * 0.3;
    final crownX = centerX + xOffset;
    
    // Main crown
    final crownPaint = Paint()
      ..color = hasFailed ? Colors.brown.shade400 : Colors.green.shade500
      ..style = PaintingStyle.fill;
    
    // Draw multiple overlapping circles for crown
    final crownRadius = 35.0;
    canvas.drawCircle(Offset(crownX, topY), crownRadius, crownPaint);
    canvas.drawCircle(Offset(crownX - 20, topY + 15), crownRadius * 0.8, crownPaint);
    canvas.drawCircle(Offset(crownX + 20, topY + 15), crownRadius * 0.8, crownPaint);
    canvas.drawCircle(Offset(crownX, topY + 20), crownRadius * 0.7, crownPaint);
    
    // Crown outline
    final outlinePaint = Paint()
      ..color = hasFailed ? Colors.brown.shade600 : Colors.green.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(crownX, topY), crownRadius, outlinePaint);
  }

  void _drawRoots(Canvas canvas, double centerX, double groundY) {
    final rootPaint = Paint()
      ..color = Colors.brown.shade700
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    // Draw spreading roots
    for (var angle = -60.0; angle <= 60.0; angle += 30.0) {
      final rad = angle * math.pi / 180;
      final length = 25.0 + (60 - angle.abs()) * 0.3;
      canvas.drawLine(
        Offset(centerX, groundY),
        Offset(centerX + math.sin(rad) * length, groundY + math.cos(rad) * length * 0.5),
        rootPaint,
      );
    }
  }

  void _drawFailureCrack(Canvas canvas, double centerX, double groundY, double height) {
    final crackPaint = Paint()
      ..color = Colors.red.shade900
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final failureY = groundY - height * 0.15; // Break point near base
    final crackSize = failureProgress * 15;
    
    // Jagged crack lines
    final path = Path();
    path.moveTo(centerX - 8, failureY - crackSize);
    path.lineTo(centerX - 3, failureY);
    path.lineTo(centerX + 2, failureY - crackSize * 0.7);
    path.lineTo(centerX + 8, failureY + crackSize);
    
    canvas.drawPath(path, crackPaint);
    
    // Red glow effect
    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.3 * failureProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(centerX, failureY), 20, glowPaint);
  }

  void _drawInfoPanel(Canvas canvas, Size size) {
    final panelX = size.width * 0.65;
    final panelY = 20.0;
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    var y = panelY;
    
    // Title
    textPainter.text = const TextSpan(
      text: 'Live Status',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
    y += 24;
    
    // Safety Factor
    final sfColor = hasFailed ? Colors.red : safetyFactor < 1.5 ? Colors.orange : Colors.green;
    textPainter.text = TextSpan(
      text: 'SF: ${safetyFactor.toStringAsFixed(2)}',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sfColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
    y += 26;
    
    // Stress level bar
    final stressRatio = (1.0 / safetyFactor).clamp(0.0, 1.0);
    final barWidth = 100.0;
    final barHeight = 12.0;
    
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(panelX, y, barWidth, barHeight),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.grey.shade300,
    );
    
    // Fill
    final fillColor = stressRatio > 0.8 ? Colors.red : stressRatio > 0.5 ? Colors.orange : Colors.green;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(panelX, y, barWidth * stressRatio, barHeight),
        const Radius.circular(6),
      ),
      Paint()..color = fillColor,
    );
    y += 20;
    
    textPainter.text = TextSpan(
      text: 'Stress: ${(stressRatio * 100).toStringAsFixed(0)}%',
      style: const TextStyle(fontSize: 11, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
    y += 24;
    
    // Wall info
    textPainter.text = TextSpan(
      text: 'Wall: ${residualWallPct.toStringAsFixed(0)}%',
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
    y += 20;
    
    // Failure point
    textPainter.text = TextSpan(
      text: 'Fails at: ${failureWindSpeed.toStringAsFixed(0)} m/s',
      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
  }

  void _drawWindGauge(Canvas canvas, Size size) {
    final gaugeX = size.width - 50;
    final gaugeY = size.height - 100;
    final gaugeHeight = 150.0;
    
    // Gauge background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(gaugeX, gaugeY - gaugeHeight, 20, gaugeHeight),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.grey.shade200,
    );
    
    // Gauge markers
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var ws = 0; ws <= 80; ws += 20) {
      final y = gaugeY - (ws / 80) * gaugeHeight;
      canvas.drawLine(
        Offset(gaugeX - 5, y),
        Offset(gaugeX, y),
        Paint()..color = Colors.grey.shade600..strokeWidth = 1,
      );
      textPainter.text = TextSpan(
        text: '$ws',
        style: const TextStyle(fontSize: 9, color: Colors.black54),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(gaugeX - textPainter.width - 8, y - 5));
    }
    
    // Design wind marker
    final designY = gaugeY - (designWindSpeed / 80) * gaugeHeight;
    canvas.drawLine(
      Offset(gaugeX - 8, designY),
      Offset(gaugeX + 28, designY),
      Paint()..color = Colors.blue..strokeWidth = 2,
    );
    
    // Failure wind marker
    final failY = gaugeY - (failureWindSpeed / 80) * gaugeHeight;
    canvas.drawLine(
      Offset(gaugeX - 8, failY),
      Offset(gaugeX + 28, failY),
      Paint()..color = Colors.red..strokeWidth = 2,
    );
    
    // Current fill
    final currentHeight = (windSpeed / 80) * gaugeHeight;
    final fillColor = windSpeed > failureWindSpeed ? Colors.red : Colors.blue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(gaugeX, gaugeY - currentHeight, 20, currentHeight),
        const Radius.circular(10),
      ),
      Paint()..color = fillColor.withOpacity(0.7),
    );
    
    // Labels
    textPainter.text = const TextSpan(
      text: 'm/s',
      style: TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(gaugeX + 2, gaugeY + 5));
  }

  @override
  bool shouldRepaint(covariant _LiveTreePainter oldDelegate) {
    return oldDelegate.deflection != deflection ||
           oldDelegate.swayOffset != swayOffset ||
           oldDelegate.failureProgress != failureProgress ||
           oldDelegate.stemColor != stemColor ||
           oldDelegate.hasFailed != hasFailed ||
           oldDelegate.windSpeed != windSpeed ||
           oldDelegate.safetyFactor != safetyFactor;
  }
}

/// More realistic tree painter with multi-stem support and proportional rendering.
class _RealisticTreePainter extends CustomPainter {
  final double dbhCm;
  final double heightM;
  final double crownDiameterM;
  final double deflection;
  final double swayOffset;
  final double leafSway;
  final double failureProgress;
  final Color stemColor;
  final bool hasFailed;
  final double windSpeed;
  final double safetyFactor;
  final double failureWindSpeed;
  final double designWindSpeed;
  final double residualWallPct;
  final int stemCount;
  final double leanAngle;
  final double crownAsymmetry;
  final bool hasDeadwood;
  final bool hasHangingBranches;
  final double targetProximity;
  final int defectLocation; // 0=none, 1=base, 2=mid, 3=upper, 4=branch union
  final bool showPruningComparison;
  final double crownReductionPercent;
  final int cavityType; // 0=closed, 1=open, 2=pipe
  final double cavityOpeningAngle;

  _RealisticTreePainter({
    required this.dbhCm,
    required this.heightM,
    required this.crownDiameterM,
    required this.deflection,
    required this.swayOffset,
    required this.leafSway,
    required this.failureProgress,
    required this.stemColor,
    required this.hasFailed,
    required this.windSpeed,
    required this.safetyFactor,
    required this.failureWindSpeed,
    required this.designWindSpeed,
    required this.residualWallPct,
    required this.stemCount,
    required this.leanAngle,
    required this.crownAsymmetry,
    required this.hasDeadwood,
    required this.hasHangingBranches,
    required this.targetProximity,
    this.defectLocation = 0,
    this.showPruningComparison = false,
    this.crownReductionPercent = 20.0,
    this.cavityType = 0,
    this.cavityOpeningAngle = 90.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - 50;
    final maxTreeHeight = size.height - 90;
    
    // Scale tree based on actual proportions
    final scale = maxTreeHeight / (heightM * 10); // 10px per meter
    final treeHeight = heightM * scale * 8;
    final crownRadius = crownDiameterM * scale * 4;
    final stemWidth = (dbhCm / 10) * scale * 2;
    
    final centerX = size.width * 0.35;
    
    // Draw realistic sky gradient
    final skyRect = Rect.fromLTWH(0, 0, size.width, groundY);
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF87CEEB),
        Color(0xFFB0E0E6),
        Color(0xFFE6F3FF),
      ],
    );
    canvas.drawRect(skyRect, Paint()..shader = skyGradient.createShader(skyRect));
    
    // Clouds
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawOval(Rect.fromCenter(center: Offset(80, 35), width: 50, height: 20), cloudPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(105, 30), width: 35, height: 15), cloudPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width - 60, 45), width: 45, height: 18), cloudPaint);
    
    // Draw realistic ground with grass
    final groundRect = Rect.fromLTWH(0, groundY, size.width, size.height - groundY);
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF4A7C23),
        Color(0xFF3D6B1E),
        Color(0xFF2D5016),
      ],
    );
    canvas.drawRect(groundRect, Paint()..shader = groundGradient.createShader(groundRect));
    
    // Grass texture
    final grassPaint = Paint()
      ..color = const Color(0xFF5C8A2F)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final random = math.Random(99);
    for (var i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = groundY + random.nextDouble() * 10;
      final h = 3 + random.nextDouble() * 5;
      final lean = (random.nextDouble() - 0.5) * 0.2 + windSpeed / 250;
      canvas.drawLine(Offset(x, baseY), Offset(x + lean * h, baseY - h), grassPaint);
    }
    
    // Draw target if present
    if (targetProximity > 0) {
      _drawTarget(canvas, centerX, groundY, targetProximity);
    }
    
    // Draw wind arrows
    _drawWindArrows(canvas, size);
    
    // Calculate base lean and dynamic bend
    final baseLean = leanAngle * math.pi / 180;
    final dynamicBend = (deflection + swayOffset) * 0.4 + failureProgress * 1.2;
    
    // For pruning comparison, draw two trees side by side
    if (showPruningComparison) {
      final treeSpacing = size.width * 0.22;
      final leftX = size.width * 0.25;
      final rightX = size.width * 0.55;
      final reducedCrown = crownRadius * (1 - crownReductionPercent / 100);
      
      // Label: Original
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = const TextSpan(
        text: 'ORIGINAL',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF555555)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftX - textPainter.width / 2, groundY + 15));
      
      // Label: After Pruning
      textPainter.text = TextSpan(
        text: 'AFTER ${crownReductionPercent.toStringAsFixed(0)}% REDUCTION',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rightX - textPainter.width / 2, groundY + 15));
      
      // Draw original tree (left)
      _drawRoots(canvas, leftX, groundY, stemWidth * 0.8);
      _drawStem(canvas, leftX, groundY, treeHeight * 0.8, stemWidth * 0.8, baseLean + dynamicBend, 0);
      _drawRealisticCrown(canvas, leftX, groundY, treeHeight * 0.8, crownRadius * 0.8, baseLean + dynamicBend, leafSway);
      
      // Draw pruned tree (right) - smaller crown, less sway
      _drawRoots(canvas, rightX, groundY, stemWidth * 0.8);
      _drawStem(canvas, rightX, groundY, treeHeight * 0.8, stemWidth * 0.8, baseLean + dynamicBend * 0.6, 0);
      _drawRealisticCrown(canvas, rightX, groundY, treeHeight * 0.8, reducedCrown * 0.8, baseLean + dynamicBend * 0.6, leafSway * 0.7);
      
      // Show reduced wind load effect
      _drawPruningArrow(canvas, leftX, rightX, groundY - treeHeight * 0.5);
    } else {
      // Single tree view
      _drawRoots(canvas, centerX, groundY, stemWidth);
      
      // Draw stems - crown follows main stem for multi-stem
      final mainStemTopX = centerX + math.pow(1.0, 1.8) * (baseLean + dynamicBend) * treeHeight * 0.35;
      
      for (var s = 0; s < stemCount; s++) {
        final stemOffset = stemCount > 1 
            ? (s - (stemCount - 1) / 2) * stemWidth * 1.2 
            : 0.0;
        final stemH = stemCount > 1 ? treeHeight * (0.7 + s * 0.1) : treeHeight;
        _drawStem(canvas, centerX + stemOffset, groundY, stemH, 
                  stemWidth / math.sqrt(stemCount), baseLean + dynamicBend, s);
      }
      
      // Draw crown centered on main stem top
      _drawRealisticCrown(canvas, mainStemTopX, groundY, treeHeight, crownRadius, 
                          baseLean + dynamicBend, leafSway);
      
      // Draw defect/fungi at specified location
      if (defectLocation > 0) {
        _drawDefect(canvas, centerX, groundY, treeHeight, stemWidth, crownRadius, baseLean + dynamicBend);
      }
      
      // Draw deadwood if present
      if (hasDeadwood) {
        _drawDeadwood(canvas, mainStemTopX, groundY - treeHeight * 0.6, crownRadius);
      }
      
      // Draw hanging branches if present
      if (hasHangingBranches) {
        _drawHangingBranches(canvas, mainStemTopX, groundY - treeHeight * 0.5, crownRadius, leafSway);
      }
      
      // Draw failure crack
      if (hasFailed || failureProgress > 0) {
        _drawFailureCrack(canvas, centerX, groundY, treeHeight, stemWidth);
      }
    }
    
    // Draw info panel
    _drawInfoPanel(canvas, size);
    
    // Draw wind gauge
    _drawWindGauge(canvas, size);
  }

  void _drawTarget(Canvas canvas, double centerX, double groundY, double proximity) {
    final targetX = centerX + proximity * 50;
    final targetY = groundY + 10;
    
    // House shape
    final housePaint = Paint()..color = Colors.red.shade100;
    final roofPaint = Paint()..color = Colors.red.shade400;
    final outlinePaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // House body
    canvas.drawRect(
      Rect.fromLTWH(targetX - 15, targetY, 30, 25),
      housePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(targetX - 15, targetY, 30, 25),
      outlinePaint,
    );
    
    // Roof
    final roofPath = Path()
      ..moveTo(targetX - 20, targetY)
      ..lineTo(targetX, targetY - 15)
      ..lineTo(targetX + 20, targetY)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
    canvas.drawPath(roofPath, outlinePaint);
    
    // "TARGET" label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'TARGET',
        style: TextStyle(fontSize: 9, color: Colors.red.shade700, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(targetX - textPainter.width / 2, targetY + 28));
  }

  void _drawWindArrows(Canvas canvas, Size size) {
    final arrowIntensity = (windSpeed / 60).clamp(0.3, 1.0);
    final arrowPaint = Paint()
      ..color = Colors.blue.shade400.withOpacity(arrowIntensity)
      ..strokeWidth = 2 + windSpeed / 30
      ..strokeCap = StrokeCap.round;
    
    final arrowCount = (windSpeed / 12).ceil().clamp(1, 6);
    
    for (var i = 0; i < arrowCount; i++) {
      final y = 50.0 + i * 35;
      final startX = 15.0;
      final length = 25 + windSpeed * 0.6;
      final endX = startX + length;
      
      // Arrow shaft
      canvas.drawLine(Offset(startX, y), Offset(endX, y), arrowPaint);
      
      // Arrow head
      canvas.drawLine(Offset(endX, y), Offset(endX - 10, y - 7), arrowPaint);
      canvas.drawLine(Offset(endX, y), Offset(endX - 10, y + 7), arrowPaint);
    }
    
    // Wind speed label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${windSpeed.toStringAsFixed(0)} m/s',
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(15, 20));
  }

  void _drawRoots(Canvas canvas, double centerX, double groundY, double stemWidth) {
    final rootPaint = Paint()
      ..color = Colors.brown.shade800
      ..strokeWidth = stemWidth * 0.3
      ..strokeCap = StrokeCap.round;
    
    for (var angle = -70.0; angle <= 70.0; angle += 20.0) {
      final rad = angle * math.pi / 180;
      final length = 20.0 + (70 - angle.abs()) * 0.4;
      final endX = centerX + math.sin(rad) * length;
      final endY = groundY + math.cos(rad) * length * 0.4;
      
      canvas.drawLine(Offset(centerX, groundY), Offset(endX, endY), rootPaint);
    }
  }

  void _drawStem(Canvas canvas, double baseX, double groundY, double height, 
                 double width, double totalBend, int stemIndex) {
    final segments = 18;
    final leftPts = <Offset>[];
    final rightPts = <Offset>[];
    final centerPts = <Offset>[];
    
    // Build trunk shape with taper and bend
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final y = groundY - height * t;
      final xBend = math.pow(t, 1.8) * totalBend * height * 0.35;
      final taper = width * (1.0 - t * 0.55);
      
      centerPts.add(Offset(baseX + xBend, y));
      leftPts.add(Offset(baseX + xBend - taper, y));
      rightPts.add(Offset(baseX + xBend + taper, y));
    }
    
    // Draw trunk with realistic bark colors
    final trunkPath = Path();
    trunkPath.moveTo(leftPts.first.dx, leftPts.first.dy);
    for (final p in leftPts) trunkPath.lineTo(p.dx, p.dy);
    for (final p in rightPts.reversed) trunkPath.lineTo(p.dx, p.dy);
    trunkPath.close();
    
    // Gradient for 3D effect
    final barkGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFF3E2723),
        Color.lerp(const Color(0xFF5D4037), stemColor, 0.4)!,
        const Color(0xFF4E342E),
        const Color(0xFF3E2723),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
    
    canvas.drawPath(trunkPath, Paint()
      ..shader = barkGradient.createShader(
        Rect.fromLTWH(baseX - width * 2, groundY - height, width * 4, height)));
    
    // Bark texture - vertical fissures
    final fissurePaint = Paint()
      ..color = const Color(0xFF2D1F1A).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    for (var i = 1; i < segments - 1; i++) {
      final t = i / segments;
      if (i % 2 == 0) {
        final taper = width * (1.0 - t * 0.55) * 0.6;
        // Vertical bark lines
        canvas.drawLine(
          Offset(centerPts[i].dx - taper * 0.5, centerPts[i].dy),
          Offset(centerPts[i].dx - taper * 0.4, centerPts[i + 1].dy),
          fissurePaint,
        );
        canvas.drawLine(
          Offset(centerPts[i].dx + taper * 0.3, centerPts[i].dy),
          Offset(centerPts[i].dx + taper * 0.5, centerPts[i + 1].dy),
          fissurePaint,
        );
      }
    }
    
    // Highlight on right side (sun)
    final highlightPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.3)
      ..strokeWidth = width * 0.3;
    for (var i = 0; i < centerPts.length - 1; i++) {
      final t = i / centerPts.length;
      final offset = width * (1 - t * 0.55) * 0.5;
      canvas.drawLine(
        Offset(centerPts[i].dx + offset, centerPts[i].dy),
        Offset(centerPts[i + 1].dx + offset, centerPts[i + 1].dy),
        highlightPaint..strokeWidth = width * (1 - t * 0.55) * 0.2,
      );
    }
    
    // Cavity indicator based on type
    if (residualWallPct < 100) {
      final cavitySize = 1 - residualWallPct / 100;
      
      if (cavityType == 0) {
        // Closed/internal cavity - just a dark line
        final cavityPaint = Paint()
          ..color = const Color(0xFF1A1A1A).withOpacity(0.4 * cavitySize)
          ..strokeWidth = width * 0.35 * cavitySize;
        for (var i = 0; i < centerPts.length - 1; i++) {
          canvas.drawLine(centerPts[i], centerPts[i + 1], cavityPaint);
        }
      } else if (cavityType == 1) {
        // Open cavity - visible hole in trunk
        final cavityHeight = height * 0.3 * cavitySize.clamp(0.3, 1.0);
        final cavityY = groundY - height * 0.25;
        final openingWidth = width * (cavityOpeningAngle / 180) * cavitySize;
        
        // Dark interior
        final interiorPaint = Paint()..color = const Color(0xFF1A0A00);
        final interiorPath = Path();
        interiorPath.moveTo(centerPts[4].dx - openingWidth * 0.8, cavityY);
        interiorPath.quadraticBezierTo(
          centerPts[4].dx, cavityY - cavityHeight * 0.3,
          centerPts[4].dx + openingWidth * 0.5, cavityY,
        );
        interiorPath.lineTo(centerPts[4].dx + openingWidth * 0.3, cavityY + cavityHeight);
        interiorPath.quadraticBezierTo(
          centerPts[4].dx - openingWidth * 0.2, cavityY + cavityHeight * 0.7,
          centerPts[4].dx - openingWidth * 0.6, cavityY + cavityHeight * 0.5,
        );
        interiorPath.close();
        canvas.drawPath(interiorPath, interiorPaint);
        
        // Cavity edge/lip
        final edgePaint = Paint()
          ..color = const Color(0xFF3E2723)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawPath(interiorPath, edgePaint);
        
        // Decay staining around opening
        final stainPaint = Paint()
          ..color = const Color(0xFF2D1F1A).withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerPts[4].dx, cavityY + cavityHeight * 0.5),
            width: openingWidth * 2,
            height: cavityHeight * 1.3,
          ),
          stainPaint,
        );
        
        // Callus/wound wood around edge
        final callusPaint = Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(centerPts[4].dx, cavityY + cavityHeight * 0.4),
            width: openingWidth * 1.6,
            height: cavityHeight * 0.8,
          ),
          0.3, 2.5, false, callusPaint,
        );
      } else if (cavityType == 2) {
        // Pipe/hollow - complete hollow through trunk
        final pipeWidth = width * 0.6 * cavitySize;
        
        // Dark hollow core visible at top and bottom
        final pipePaint = Paint()..color = const Color(0xFF0A0500);
        
        // Top opening
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerPts[segments - 2].dx, centerPts[segments - 2].dy),
            width: pipeWidth,
            height: pipeWidth * 0.4,
          ),
          pipePaint,
        );
        
        // Base opening (if visible)
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerPts[2].dx, centerPts[2].dy),
            width: pipeWidth * 1.2,
            height: pipeWidth * 0.5,
          ),
          pipePaint,
        );
        
        // Hollow interior line
        final hollowPaint = Paint()
          ..color = const Color(0xFF1A0A00).withOpacity(0.6)
          ..strokeWidth = pipeWidth * 0.8;
        for (var i = 2; i < centerPts.length - 2; i++) {
          canvas.drawLine(centerPts[i], centerPts[i + 1], hollowPaint);
        }
      }
    }
  }

  void _drawRealisticCrown(Canvas canvas, double centerX, double groundY, 
                           double treeHeight, double radius, double bend, double leafSway) {
    final topY = groundY - treeHeight;
    final xOffset = math.pow(1.0, 2) * bend * treeHeight * 0.25;
    final crownX = centerX + xOffset + crownAsymmetry * radius * 0.3;
    
    // Natural colors
    final baseGreen = hasFailed ? const Color(0xFF8B7355) : const Color(0xFF228B22);
    final lightGreen = hasFailed ? const Color(0xFFA08060) : const Color(0xFF32CD32);
    final darkGreen = hasFailed ? const Color(0xFF6B5344) : const Color(0xFF006400);
    final shadowGreen = hasFailed ? const Color(0xFF5A4636) : const Color(0xFF004D00);
    
    final random = math.Random(42);
    
    // Shadow layer (back)
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final dist = radius * (0.5 + random.nextDouble() * 0.3);
      final blobX = crownX - 5 + math.cos(angle) * dist;
      final blobY = topY + 8 + math.sin(angle) * dist * 0.6;
      final blobR = radius * (0.25 + random.nextDouble() * 0.15);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(blobX, blobY), width: blobR * 2.2, height: blobR * 1.6),
        Paint()..color = shadowGreen,
      );
    }
    
    // Main foliage - organic overlapping blobs
    for (var layer = 0; layer < 4; layer++) {
      final layerColor = Color.lerp(darkGreen, baseGreen, layer / 3)!;
      final layerOffset = layer * 4.0;
      
      for (var i = 0; i < 15; i++) {
        final angle = (i / 15 + layer * 0.1) * 2 * math.pi;
        final wobble = math.sin(angle * 2 + leafSway * 3) * 8;
        final dist = radius * (0.3 + (i % 3) * 0.15) + wobble;
        final blobX = crownX + layerOffset + math.cos(angle) * dist + leafSway * 2;
        final blobY = topY + layer * 5 + math.sin(angle) * dist * 0.65;
        final blobW = radius * (0.35 + random.nextDouble() * 0.2);
        final blobH = blobW * (0.6 + random.nextDouble() * 0.3);
        
        canvas.drawOval(
          Rect.fromCenter(center: Offset(blobX, blobY), width: blobW, height: blobH),
          Paint()..color = layerColor,
        );
      }
    }
    
    // Highlight clusters (lighter green on top/right for sun effect)
    for (var i = 0; i < 20; i++) {
      final angle = random.nextDouble() * math.pi * 1.5 - math.pi * 0.25;
      final dist = random.nextDouble() * radius * 0.6;
      final x = crownX + 10 + math.cos(angle) * dist + leafSway * 4;
      final y = topY - 5 + math.sin(angle) * dist * 0.5;
      final size = 4.0 + random.nextDouble() * 10;
      
      canvas.drawCircle(Offset(x, y), size, Paint()..color = lightGreen.withOpacity(0.7));
    }
    
    // Detailed leaf texture on edges
    for (var i = 0; i < 35; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = radius * (0.7 + random.nextDouble() * 0.3);
      final leafX = crownX + math.cos(angle) * dist + leafSway * 3;
      final leafY = topY + math.sin(angle) * dist * 0.55;
      final leafSize = 2.0 + random.nextDouble() * 5;
      
      canvas.drawCircle(
        Offset(leafX, leafY), 
        leafSize, 
        Paint()..color = Color.lerp(baseGreen, lightGreen, random.nextDouble())!.withOpacity(0.8),
      );
    }
  }

  void _drawDeadwood(Canvas canvas, double centerX, double y, double crownRadius) {
    final deadPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    // Draw dead branch stubs
    canvas.drawLine(
      Offset(centerX + crownRadius * 0.5, y),
      Offset(centerX + crownRadius * 0.8, y - 10),
      deadPaint,
    );
    canvas.drawLine(
      Offset(centerX - crownRadius * 0.3, y + 20),
      Offset(centerX - crownRadius * 0.6, y + 15),
      deadPaint,
    );
    
    // Deadwood label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '☠️',
        style: const TextStyle(fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + crownRadius * 0.8, y - 20));
  }

  void _drawHangingBranches(Canvas canvas, double centerX, double y, double crownRadius, double sway) {
    final branchPaint = Paint()
      ..color = Colors.brown.shade600
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final leafPaint = Paint()..color = Colors.green.shade600;
    
    // Hanging branch curves
    for (var i = 0; i < 2; i++) {
      final startX = centerX + (i == 0 ? -1 : 1) * crownRadius * 0.4;
      final path = Path()..moveTo(startX, y);
      
      final hangLength = 30 + sway * 10;
      path.quadraticBezierTo(
        startX + (i == 0 ? -15 : 15) + sway * 5,
        y + hangLength * 0.5,
        startX + (i == 0 ? -10 : 10) + sway * 8,
        y + hangLength,
      );
      
      canvas.drawPath(path, branchPaint);
      
      // Leaves on hanging branch
      canvas.drawCircle(Offset(startX + (i == 0 ? -10 : 10) + sway * 8, y + hangLength), 8, leafPaint);
    }
  }

  void _drawDefect(Canvas canvas, double centerX, double groundY, double treeHeight, 
                   double stemWidth, double crownRadius, double bend) {
    // defectLocation: 1=base, 2=mid-trunk, 3=upper-trunk, 4=branch-union
    double defectY;
    double defectX;
    String label;
    
    switch (defectLocation) {
      case 1: // Base
        defectY = groundY - treeHeight * 0.08;
        defectX = centerX + bend * treeHeight * 0.02;
        label = 'Basal decay';
        break;
      case 2: // Mid-trunk
        defectY = groundY - treeHeight * 0.35;
        defectX = centerX + bend * treeHeight * 0.12;
        label = 'Trunk cavity';
        break;
      case 3: // Upper trunk
        defectY = groundY - treeHeight * 0.55;
        defectX = centerX + bend * treeHeight * 0.2;
        label = 'Upper decay';
        break;
      case 4: // Branch union
        defectY = groundY - treeHeight * 0.7;
        defectX = centerX + bend * treeHeight * 0.25 + crownRadius * 0.2;
        label = 'Weak union';
        break;
      default:
        return;
    }
    
    // Fungi/decay bracket shape
    final fungusPaint = Paint()..color = const Color(0xFF8B4513);
    final fungusLight = Paint()..color = const Color(0xFFD2691E);
    final outlinePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw bracket fungus shapes
    for (var i = 0; i < 3; i++) {
      final offsetY = i * 8.0;
      final bracketPath = Path();
      final bx = defectX + stemWidth * 0.8;
      final by = defectY + offsetY;
      final bw = 12.0 + i * 3;
      final bh = 6.0 + i * 2;
      
      bracketPath.moveTo(bx, by);
      bracketPath.quadraticBezierTo(bx + bw, by - bh * 0.5, bx + bw * 0.9, by + bh);
      bracketPath.quadraticBezierTo(bx + bw * 0.3, by + bh * 1.2, bx, by);
      
      canvas.drawPath(bracketPath, i == 0 ? fungusLight : fungusPaint);
      canvas.drawPath(bracketPath, outlinePaint);
    }
    
    // Decay zone indicator (dark area on trunk)
    final decayPaint = Paint()
      ..color = const Color(0xFF2D1F1A).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(defectX, defectY + 10), width: stemWidth * 1.5, height: 25),
      decayPaint,
    );
    
    // Label with arrow
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B0000),
          backgroundColor: Color(0xAAFFFFFF),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final labelX = defectX + stemWidth * 2;
    final labelY = defectY - 5;
    textPainter.paint(canvas, Offset(labelX, labelY));
    
    // Arrow pointing to defect
    final arrowPaint = Paint()
      ..color = const Color(0xFF8B0000)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(labelX - 2, labelY + 6), Offset(defectX + stemWidth, defectY + 5), arrowPaint);
  }

  void _drawPruningArrow(Canvas canvas, double leftX, double rightX, double y) {
    final arrowPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final midX = (leftX + rightX) / 2;
    
    // Arrow from left tree to right tree
    canvas.drawLine(Offset(leftX + 40, y), Offset(rightX - 40, y), arrowPaint);
    
    // Arrow head
    canvas.drawLine(Offset(rightX - 40, y), Offset(rightX - 50, y - 8), arrowPaint);
    canvas.drawLine(Offset(rightX - 40, y), Offset(rightX - 50, y + 8), arrowPaint);
    
    // Label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Less wind load',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, y - 18));
  }

  void _drawFailureCrack(Canvas canvas, double centerX, double groundY, double height, double stemWidth) {
    final crackY = groundY - height * 0.1;
    final crackSize = failureProgress * 20;
    
    // Crack pattern
    final crackPaint = Paint()
      ..color = Colors.red.shade900
      ..strokeWidth = 2 + failureProgress * 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(centerX - stemWidth, crackY - crackSize);
    path.lineTo(centerX - stemWidth * 0.3, crackY);
    path.lineTo(centerX + stemWidth * 0.2, crackY - crackSize * 0.5);
    path.lineTo(centerX + stemWidth, crackY + crackSize);
    
    canvas.drawPath(path, crackPaint);
    
    // Red glow
    if (failureProgress > 0.5) {
      final glowPaint = Paint()
        ..color = Colors.red.withOpacity(0.4 * failureProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(centerX, crackY), 30, glowPaint);
    }
    
    // Splinter lines
    if (failureProgress > 0.7) {
      final splinterPaint = Paint()
        ..color = Colors.orange.shade300
        ..strokeWidth = 1;
      for (var i = 0; i < 5; i++) {
        final angle = (i - 2) * 0.3;
        canvas.drawLine(
          Offset(centerX, crackY),
          Offset(centerX + math.cos(angle) * 15, crackY + math.sin(angle) * 15),
          splinterPaint,
        );
      }
    }
  }

  void _drawInfoPanel(Canvas canvas, Size size) {
    final panelX = size.width * 0.68;
    var y = 15.0;
    
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(panelX - 8, y - 5, size.width - panelX, 130),
        const Radius.circular(8),
      ),
      bgPaint,
    );
    
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // Title
    textPainter.text = const TextSpan(
      text: 'Live Status',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
    y += 20;
    
    // Safety Factor
    final sfColor = hasFailed ? Colors.red : safetyFactor < 1.5 ? Colors.orange : Colors.green;
    textPainter.text = TextSpan(
      text: 'SF: ${safetyFactor.toStringAsFixed(2)}',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sfColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
    y += 24;
    
    // Stress bar
    final stressRatio = (1.0 / safetyFactor).clamp(0.0, 1.0);
    final barWidth = 90.0;
    final barHeight = 10.0;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(panelX, y, barWidth, barHeight), const Radius.circular(5)),
      Paint()..color = Colors.grey.shade200,
    );
    
    final fillColor = stressRatio > 0.8 ? Colors.red : stressRatio > 0.5 ? Colors.orange : Colors.green;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(panelX, y, barWidth * stressRatio, barHeight), const Radius.circular(5)),
      Paint()..color = fillColor,
    );
    y += 16;
    
    textPainter.text = TextSpan(
      text: 'Stress: ${(stressRatio * 100).toStringAsFixed(0)}%',
      style: const TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
    y += 18;
    
    // Tree info
    textPainter.text = TextSpan(
      text: 'H: ${heightM.toStringAsFixed(1)}m  DBH: ${dbhCm.toStringAsFixed(0)}cm',
      style: const TextStyle(fontSize: 10, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
    y += 16;
    
    textPainter.text = TextSpan(
      text: 'Fails at: ${failureWindSpeed.toStringAsFixed(0)} m/s',
      style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(panelX, y));
  }

  void _drawWindGauge(Canvas canvas, Size size) {
    final gaugeX = size.width - 45;
    final gaugeY = size.height - 70;
    final gaugeHeight = 180.0;
    
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(gaugeX, gaugeY - gaugeHeight, 24, gaugeHeight),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.grey.shade200,
    );
    
    // Markers
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var ws = 0; ws <= 80; ws += 20) {
      final y = gaugeY - (ws / 80) * gaugeHeight;
      canvas.drawLine(Offset(gaugeX - 4, y), Offset(gaugeX, y), Paint()..color = Colors.grey.shade500);
      
      textPainter.text = TextSpan(
        text: '$ws',
        style: const TextStyle(fontSize: 9, color: Colors.black54),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(gaugeX - textPainter.width - 6, y - 5));
    }
    
    // Design wind marker (blue)
    final designY = gaugeY - (designWindSpeed / 80) * gaugeHeight;
    canvas.drawLine(
      Offset(gaugeX - 6, designY), Offset(gaugeX + 30, designY),
      Paint()..color = Colors.blue..strokeWidth = 2,
    );
    
    // Failure wind marker (red)
    final failY = gaugeY - (failureWindSpeed / 80) * gaugeHeight;
    canvas.drawLine(
      Offset(gaugeX - 6, failY), Offset(gaugeX + 30, failY),
      Paint()..color = Colors.red..strokeWidth = 2,
    );
    
    // Current fill
    final currentHeight = (windSpeed / 80) * gaugeHeight;
    final fillColor = windSpeed > failureWindSpeed ? Colors.red : Colors.blue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(gaugeX, gaugeY - currentHeight, 24, currentHeight),
        const Radius.circular(12),
      ),
      Paint()..color = fillColor.withOpacity(0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _RealisticTreePainter oldDelegate) {
    return oldDelegate.deflection != deflection ||
           oldDelegate.swayOffset != swayOffset ||
           oldDelegate.leafSway != leafSway ||
           oldDelegate.failureProgress != failureProgress ||
           oldDelegate.hasFailed != hasFailed ||
           oldDelegate.windSpeed != windSpeed ||
           oldDelegate.safetyFactor != safetyFactor ||
           oldDelegate.stemCount != stemCount ||
           oldDelegate.leanAngle != leanAngle ||
           oldDelegate.crownAsymmetry != crownAsymmetry ||
           oldDelegate.defectLocation != defectLocation ||
           oldDelegate.showPruningComparison != showPruningComparison ||
           oldDelegate.crownReductionPercent != crownReductionPercent;
  }
}
