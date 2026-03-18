import 'package:flutter/material.dart';

class AppBarActionButton extends StatelessWidget {
  const AppBarActionButton({super.key, required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const borderRadius = BorderRadius.all(Radius.circular(8));

    final iconColor = onTap != null ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.35);

    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: cs.surface,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
