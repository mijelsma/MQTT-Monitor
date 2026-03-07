import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../settings_section.dart';
import '../settings_item.dart';
import '../widgets/settings_sidebar_list.dart';

class SettingsNarrowLayout extends StatefulWidget {
  const SettingsNarrowLayout({
    super.key,
    required this.items,
    required this.current,
    required this.onSelect,
    required this.panel,
  });

  final List<SettingsItem> items;
  final SettingsSection current;
  final ValueChanged<SettingsSection> onSelect;
  final Widget panel;

  @override
  State<SettingsNarrowLayout> createState() => _SettingsNarrowLayoutState();
}

class _SettingsNarrowLayoutState extends State<SettingsNarrowLayout> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primary400 : AppColors.primary500;
    final contentBg = context.tokens.bg;
    final borderColor = context.tokens.border;

    // Detail view when an item is selected 
    if (_showDetail) {
      return Scaffold(
        backgroundColor: contentBg,
        appBar: AppBar(
          backgroundColor: contentBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(height: 0.5, color: borderColor),
          ),
          leading: GestureDetector(
            onTap: () => setState(() => _showDetail = false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 4),
                Icon(Icons.chevron_left_rounded, color: accent, size: 22),
                Text('Settings', style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          leadingWidth: 120,
          title: Text(
            widget.items.firstWhere((i) => i.section == widget.current).label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
        ),
        body: widget.panel,
      );
    }

    // Main list view
    return Scaffold(
      backgroundColor: contentBg,
      appBar: AppBar(
        title: null,
        backgroundColor: contentBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: borderColor),
        ),
      ),
      body: SettingsSidebarList(
        borderColor: borderColor,
        items: widget.items,
        current: widget.current,
        onSelect: (s) {
          widget.onSelect(s);
          setState(() => _showDetail = true);
        },
      ),
    );
  }
}
