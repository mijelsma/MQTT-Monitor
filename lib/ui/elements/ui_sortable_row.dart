import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';

class UiSortableRow extends StatelessWidget {
  const UiSortableRow({super.key, required this.leading, required this.title, this.subtitle, required this.index, required this.onTap, this.onDelete});

  final Widget leading;
  final String title;
  final String? subtitle;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.drag_indicator_rounded, size: 20, color: tokens.textTertiary),
              ),
            ),

            // Leading widget (icon chip, badge, etc.)
            leading,
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary))],
                ],
              ),
            ),

            // Delete button (optional)
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: _errorColor),
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                onPressed: onDelete,
              ),

            // Chevron
            Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }

  // Inline constant to avoid importing AppColors into this primitive.
  static const Color _errorColor = Color(0xFFEF4444);
}
