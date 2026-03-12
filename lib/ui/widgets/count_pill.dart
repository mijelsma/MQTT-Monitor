import 'package:flutter/material.dart';

/// A compact pill badge showing a numeric count with a label.
///
/// Large numbers are automatically shortened: ≥ 10 000 → `15k`, ≥ 1 000 → `1.2k`.
/// Styling is derived entirely from [color] so the widget fits any theme.
class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.count, required this.label, required this.color});

  final int count;
  final String label;
  final Color color;

  String get _text {
    if (count >= 10000) return '${(count / 1000).round()}k';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        '$_text $label',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85), letterSpacing: 0.1),
      ),
    );
  }
}
