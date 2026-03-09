import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../settings_section.dart';
import '../settings_item.dart';
import '../widgets/settings_sidebar.dart';

class SettingsWideLayout extends StatelessWidget {
  const SettingsWideLayout({super.key, required this.items, required this.current, required this.onSelect, required this.panel});

  final List<SettingsItem> items;
  final SettingsSection current;
  final ValueChanged<SettingsSection> onSelect;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    final sidebarBg = context.tokens.surface;
    final contentBg = context.tokens.bg;
    final borderColor = context.tokens.border;

    return Scaffold(
      backgroundColor: contentBg,
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 300,
            child: SettingsSidebar(bg: sidebarBg, borderColor: borderColor, items: items, current: current, onSelect: onSelect),
          ),

          // Divider
          Container(width: 0.5, color: borderColor),

          // Content
          Expanded(
            child: Column(
              children: [
                Container(height: 0.5, color: borderColor),
                Expanded(child: panel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
