import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';

class UiNavigationRow extends StatelessWidget {
  const UiNavigationRow({super.key, required this.label, required this.onTap, this.subtitle, this.icon, this.iconColor});

  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: (iconColor ?? tokens.primary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 18, color: iconColor ?? tokens.primary),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary))],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
