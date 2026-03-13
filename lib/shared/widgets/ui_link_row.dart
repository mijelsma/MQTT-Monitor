import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';

class UiLinkRow extends StatelessWidget {
  const UiLinkRow({super.key, required this.label, required this.icon, required this.onTap, this.accent});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? context.tokens.primary;
    final secondary = context.tokens.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: resolvedAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: secondary),
          ],
        ),
      ),
    );
  }
}
