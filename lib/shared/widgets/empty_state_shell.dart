import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';
import '../../theme/ui_layout.dart';
import 'spacers.dart';

class EmptyStateShell extends StatelessWidget {
  const EmptyStateShell({super.key, required this.gradientColors, required this.icon, required this.title, required this.subtitle, this.action});

  final List<Color> gradientColors;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final layout = context.uiLayout;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: gradientColors.first.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(tokens.panelRadius),
                border: Border.all(color: gradientColors.first.withValues(alpha: 0.18), width: 0.5),
              ),
              child: Icon(icon, size: 28, color: gradientColors.first),
            ),
            VSpacer(layout.sectionGap),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
              textAlign: TextAlign.center,
            ),
            VSpacer(10),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[VSpacer(24), action!],
          ],
        ),
      ),
    );
  }
}
