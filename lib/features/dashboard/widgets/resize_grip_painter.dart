import 'package:flutter/material.dart';

/// Paints two diagonal grip lines in the bottom-right corner of a card.
class ResizeGripPainter extends CustomPainter {
  ResizeGripPainter({required this.color});

  final Color color;

  /// Distance from the bottom-right corner to the end of each line.
  static const double _edgeInset = 4.0;

  /// Starting offset of the first grip line from the corner.
  static const double _firstLineOffset = 6.0;

  /// Spacing between the two grip lines.
  static const double _lineSpacing = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 2; i++) {
      final offset = _firstLineOffset + i * _lineSpacing;
      canvas.drawLine(Offset(size.width - offset, size.height - _edgeInset), Offset(size.width - _edgeInset, size.height - offset), paint);
    }
  }

  @override
  bool shouldRepaint(ResizeGripPainter old) => old.color != color;
}
