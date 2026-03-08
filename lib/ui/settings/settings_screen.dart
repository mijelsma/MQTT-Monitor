import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'panels/about_panel.dart';
import 'panels/language_panel.dart';
import 'panels/ui_panel.dart';
import 'panels/brokers_panel.dart';
import 'settings_section.dart';
import 'settings_item.dart';
import 'layouts/settings_wide_layout.dart';
import 'layouts/settings_narrow_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsSection _current = SettingsSection.about;

  // Settings items
  static final _items = <SettingsItem>[
    (section: SettingsSection.brokers, label: 'Brokers', icon: Icons.dns_rounded, gradient: AppColors.brokerGradient),
    (section: SettingsSection.ui, label: 'User Interface', icon: Icons.palette_outlined, gradient: AppColors.uiGradient),
    (section: SettingsSection.language, label: 'Language', icon: Icons.language_rounded, gradient: AppColors.languageGradient),
    (section: SettingsSection.about, label: 'About', icon: Icons.info_outline_rounded, gradient: AppColors.aboutGradient),
  ];

  Widget _buildPanel() => switch (_current) {
    SettingsSection.brokers => const BrokersPanel(),
    SettingsSection.ui => const UiPanel(),
    SettingsSection.language => const LanguagePanel(),
    SettingsSection.about => const AboutPanel(),
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return SettingsWideLayout(items: _items, current: _current, onSelect: (s) => setState(() => _current = s), panel: _buildPanel());
    } else {
      return SettingsNarrowLayout(items: _items, current: _current, onSelect: (s) => setState(() => _current = s), panel: _buildPanel());
    }
  }
}
