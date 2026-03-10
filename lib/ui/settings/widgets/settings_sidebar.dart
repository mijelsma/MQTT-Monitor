import 'package:flutter/material.dart';
import '../../../generated/l10n.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../settings_section.dart';
import '../settings_item.dart';
import 'settings_sidebar_list.dart';

class SettingsSidebar extends StatelessWidget {
  const SettingsSidebar({super.key, required this.bg, required this.borderColor, required this.items, required this.current, required this.onSelect});

  final Color bg;
  final Color borderColor;
  final List<SettingsItem> items;
  final SettingsSection current;
  final ValueChanged<SettingsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.primary;

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: accent, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              label: Text(S.of(context).back, style: const TextStyle(fontSize: 15)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              S.of(context).settings,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: context.tokens.textPrimary),
            ),
          ),
          Expanded(
            child: SettingsSidebarList(borderColor: borderColor, items: items, current: current, onSelect: onSelect),
          ),
        ],
      ),
    );
  }
}
