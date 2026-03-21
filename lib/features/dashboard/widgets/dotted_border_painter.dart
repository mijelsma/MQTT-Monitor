import 'package:flutter/material.dart';

/// Paints a faint dotted border around empty grid cells while dragging.
class DottedBorderPainter extends CustomPainter {
  DottedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    final path = Path()..addRRect(rrect);

    canvas.drawPath(
      _createDashedPath(path, dashLength: 4, gapLength: 4),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  /// Converts a solid [source] path into a dashed one.
  static Path _createDashedPath(Path source, {required double dashLength, required double gapLength}) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        result.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + gapLength;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(DottedBorderPainter old) => old.color != color;
}
