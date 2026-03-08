import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';

class LinkRow extends StatelessWidget {
  const LinkRow({super.key, required this.label, required this.icon, required this.accent, required this.onTap});

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = context.tokens.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accent),
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
