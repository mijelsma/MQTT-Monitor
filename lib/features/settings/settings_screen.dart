import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';
import 'panels/about_panel.dart';
import 'panels/brokers_panel.dart';
import 'panels/language_panel.dart';
import 'panels/monitoring_panel.dart';
import 'panels/ui_panel.dart';
import 'panels/variables_panel.dart';
import 'settings_item.dart';
import 'settings_section.dart';
import 'settings_viewmodel.dart';
import 'layouts/settings_narrow_layout.dart';
import 'layouts/settings_wide_layout.dart';
import 'panels/dashboard_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  List<SettingsItem> _items(BuildContext context) {
    final s = S.of(context);
    return [
      (section: SettingsSection.brokers, label: s.sectionBrokers, icon: Icons.dns_rounded, gradient: AppColors.brokerGradient),
      (section: SettingsSection.dashboard, label: s.sectionDashboard, icon: Icons.dashboard_rounded, gradient: AppColors.dashboardGradient),
      (section: SettingsSection.variables, label: s.sectionVariables, icon: Icons.data_object_rounded, gradient: AppColors.variablesGradient),
      (section: SettingsSection.monitoring, label: s.sectionMonitoring, icon: Icons.monitor_heart_rounded, gradient: AppColors.monitoringGradient),
      (section: SettingsSection.ui, label: s.sectionUI, icon: Icons.palette_outlined, gradient: AppColors.uiGradient),
      (section: SettingsSection.language, label: s.sectionLanguage, icon: Icons.language_rounded, gradient: AppColors.languageGradient),
      (section: SettingsSection.about, label: s.sectionAbout, icon: Icons.info_outline_rounded, gradient: AppColors.aboutGradient),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SettingsViewModel(state: ctx.read<AppStateManager>()),
      child: Builder(
        builder: (context) {
          final vm = context.watch<SettingsViewModel>();
          final current = vm.activeSection;
          final isWide = MediaQuery.sizeOf(context).width >= 600;

          void select(SettingsSection s) => vm.selectSection(s);

          Widget panel() => switch (current) {
            SettingsSection.brokers => const BrokersPanel(),
            SettingsSection.dashboard => const DashboardPanel(),
            SettingsSection.variables => const VariablesPanel(),
            SettingsSection.monitoring => const MonitoringPanel(),
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
        },
      ),
    );
  }
}
