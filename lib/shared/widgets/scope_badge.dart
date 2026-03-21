import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// A subtle pill badge that indicates whether an item is global or broker-scoped.
///
/// Used in list rows for shortcuts, variables, dashboards, etc.
class ScopeBadge extends StatelessWidget {
  const ScopeBadge({super.key, required this.isGlobal, this.brokerCount = 0});

  final bool isGlobal;
  final int brokerCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = isGlobal ? 'Global' : '$brokerCount broker${brokerCount == 1 ? '' : 's'}';
    final color = isGlobal ? tokens.primary : tokens.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.2),
      ),
    );
  }
}
