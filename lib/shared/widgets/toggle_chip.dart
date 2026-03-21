import 'package:flutter/material.dart';

import '../../theme/app_tokens/app_tokens.dart';

/// A selectable pill used in segmented toggle groups.
///
/// Shows [label] text, optionally preceded by an [icon].
class ToggleChip extends StatelessWidget {
  const ToggleChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = selected ? tokens.primary : tokens.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.primary.withValues(alpha: 0.1) : tokens.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? tokens.primary : tokens.border, width: selected ? 1.5 : 0.5),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
                  ),
                ],
              )
            : Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
              ),
      ),
    );
  }
}
