import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'spacers.dart';

class UiEmptyState extends StatelessWidget {
  const UiEmptyState({super.key, required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: context.tokens.textTertiary),
            const VSpacer(12),
            Text(title, style: theme.textTheme.bodyMedium),
            const VSpacer(4),
            Text(message, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
