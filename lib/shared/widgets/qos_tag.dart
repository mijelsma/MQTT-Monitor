import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'badge_tag.dart';

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

String qosLabel(int qos) => switch (qos) {
  0 => 'At most once',
  1 => 'At least once',
  2 => 'Exactly once',
  _ => 'Unknown',
};
