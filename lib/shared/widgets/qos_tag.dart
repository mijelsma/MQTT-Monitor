import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'badge_tag.dart';

/// Full-size QoS badge (used in topic tree rows, etc.).
class QosTag extends StatelessWidget {
  const QosTag({super.key, required this.qos});

  final int qos;

  @override
  Widget build(BuildContext context) {
    return BadgeTag(label: 'Q$qos', color: colorFor(context, qos));
  }

  /// Returns the semantic color for a given QoS level.
  static Color colorFor(BuildContext context, int qos) => switch (qos) {
    0 => context.tokens.muted,
    1 => context.tokens.info,
    2 => context.tokens.warning,
    _ => context.tokens.muted,
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
    final c = color ?? QosTag.colorFor(context, qos);
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
