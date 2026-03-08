import 'package:flutter/material.dart';

class BadgeTag extends StatelessWidget {
  const BadgeTag({super.key, required this.label, required this.color, this.fontSize = 10});

  final String label;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
      ),
    );
  }
}
