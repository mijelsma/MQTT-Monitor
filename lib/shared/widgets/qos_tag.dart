import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'badge_tag.dart';

/// Full-size QoS badge (used in topic tree rows, etc.).
class QosTag extends StatelessWidget {
  const QosTag({super.key, required this.qos});

  final int qos;

  @override
  Widget build(BuildContext context) {
    return BadgeTag(label: 'Q$qos', color: colorFor(qos));
  }

  /// Returns the semantic color for a given QoS level.
  static Color colorFor(int qos) => switch (qos) {
    0 => AppColors.neutral400,
    1 => AppColors.info500,
    2 => AppColors.warning500,
    _ => AppColors.neutral400,
  };
}

/// A tiny read-only QoS indicator for compact list rows.
///
/// Uses [QosTag.colorFor] by default, but accepts an optional [color] override
/// (e.g. a shortcut's display colour).
class QosChip extends StatelessWidget {
  const QosChip({super.key, required this.qos, this.color});

  final int qos;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? QosTag.colorFor(qos);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(3.5)),
      child: Text(
        'Q$qos',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.withValues(alpha: 0.75), letterSpacing: 0.3),
      ),
    );
  }
}

String qosLabel(int qos) => switch (qos) {
  0 => 'At most once',
  1 => 'At least once',
  2 => 'Exactly once',
  _ => 'Unknown',
};
