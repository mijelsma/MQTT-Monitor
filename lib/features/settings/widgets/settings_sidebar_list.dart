import 'package:flutter/material.dart';

import '../../../theme/app_tokens/app_tokens.dart';
import '../settings_item.dart';
import '../settings_section.dart';

class SettingsSidebarList extends StatelessWidget {
  const SettingsSidebarList({
    super.key,
    required this.borderColor,
    required this.items,
    required this.current,
    required this.onSelect,
  });

  final Color borderColor;
  final List<SettingsItem> items;
  final SettingsSection current;
  final ValueChanged<SettingsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final selectedBg = context.tokens.selectedBg;
    final textColor = context.tokens.textPrimary;
    final mutedColor = context.tokens.textTertiary;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (_, i) {
        final item = items[i];
        final isSelected = item.section == current;

        return GestureDetector(
          onTap: () => onSelect(item.section),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: borderColor, width: 0.5)
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected ? context.tokens.primary : mutedColor,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 16, color: mutedColor),
              ],
            ),
          ),
        );
      },
    );
  }
}
