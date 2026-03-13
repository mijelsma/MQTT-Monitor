import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
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
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.drag_indicator_rounded, size: 20, color: tokens.textTertiary),
              ),
            ),
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary))],
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: tokens.error),
                tooltip: S.of(context).remove,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                onPressed: onDelete,
              ),
            Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
