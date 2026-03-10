import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n.dart';
import '../../state/app_state.dart';
import '../../state/keys/app_keys.dart';
import '../../theme/app_colors.dart';
import 'panels/about_panel.dart';
import 'panels/language_panel.dart';
import 'panels/ui_panel.dart';
import 'panels/brokers_panel.dart';
import 'settings_section.dart';
import 'settings_item.dart';
import 'layouts/settings_wide_layout.dart';
import 'layouts/settings_narrow_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  List<SettingsItem> _items(BuildContext context) {
    final s = S.of(context);
    return [
      (section: SettingsSection.brokers, label: s.sectionBrokers, icon: Icons.dns_rounded, gradient: AppColors.brokerGradient),
      (section: SettingsSection.ui, label: s.sectionUI, icon: Icons.palette_outlined, gradient: AppColors.uiGradient),
      (section: SettingsSection.language, label: s.sectionLanguage, icon: Icons.language_rounded, gradient: AppColors.languageGradient),
      (section: SettingsSection.about, label: s.sectionAbout, icon: Icons.info_outline_rounded, gradient: AppColors.aboutGradient),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateManager>();
    final current = state.read(AppKeys.activeSettingsSection);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    void select(SettingsSection s) => context.read<AppStateManager>().write(AppKeys.activeSettingsSection, s);

    Widget panel() => switch (current) {
      SettingsSection.brokers => const BrokersPanel(),
      SettingsSection.ui => const UiPanel(),
      SettingsSection.language => const LanguagePanel(),
      SettingsSection.about => const AboutPanel(),
    };

    final items = _items(context);

    if (isWide) {
      return SettingsWideLayout(items: items, current: current, onSelect: select, panel: panel());
    } else {
      return SettingsNarrowLayout(items: items, current: current, onSelect: select, panel: panel());
    }
  }
}
