import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../settings_section.dart';
import '../settings_item.dart';

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
      separatorBuilder: (_, __) => const SizedBox(height: 2),
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
              border: isSelected ? Border.all(color: borderColor, width: 0.5) : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.gradient,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: item.gradient.first.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(item.icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
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
