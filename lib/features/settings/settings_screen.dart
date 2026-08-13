import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/broker/broker_repository.dart';
import '../../core/dashboard/dashboard_repository.dart';
import '../../core/dashboard/dashboard_preferences_repository.dart';
import '../../core/history/message_history_service.dart';
import '../../core/history/history_preferences_repository.dart';
import '../../core/logging/app_logger.dart';
import '../../core/mqtt/connection_preferences_repository.dart';
import '../../core/mqtt/session/mqtt_session_controller.dart';
import '../../core/publishing/shortcut_repository.dart';
import '../../core/publishing/qos_preferences_repository.dart';
import '../../core/publishing/variable_repository.dart';
import '../../core/ui/ui_preferences_repository.dart';
import '../../core/ui/workspace_layout_repository.dart';
import '../../core/update/update_preferences_repository.dart';
import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';
import 'panels/about_panel.dart';
import 'panels/advanced_panel.dart';
import 'panels/brokers_panel.dart';
import 'panels/language_panel.dart';
import 'panels/monitoring_panel.dart';
import 'panels/shortcuts_panel.dart';
import 'panels/ui_panel.dart';
import 'panels/variables_panel.dart';
import 'settings_item.dart';
import 'settings_section.dart';
import 'settings_viewmodel.dart';
import 'settings_navigation_controller.dart';
import 'layouts/settings_narrow_layout.dart';
import 'layouts/settings_wide_layout.dart';
import 'panels/dashboard_panel.dart';

/// Hosts responsive settings navigation and feature-scoped settings state.
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  List<SettingsItem> _items(BuildContext context) {
    final s = S.of(context);
    return [
      (section: SettingsSection.brokers, label: s.sectionBrokers, icon: Icons.dns_rounded, gradient: AppColors.brokerGradient),
      (section: SettingsSection.dashboard, label: s.sectionDashboard, icon: Icons.dashboard_rounded, gradient: AppColors.dashboardGradient),
      (section: SettingsSection.variables, label: s.sectionVariables, icon: Icons.data_object_rounded, gradient: AppColors.variablesGradient),
      (section: SettingsSection.shortcuts, label: s.sectionShortcuts, icon: Icons.bolt_rounded, gradient: AppColors.shortcutsGradient),
      (section: SettingsSection.monitoring, label: s.sectionMonitoring, icon: Icons.monitor_heart_rounded, gradient: AppColors.monitoringGradient),
      (section: SettingsSection.ui, label: s.sectionUI, icon: Icons.palette_outlined, gradient: AppColors.uiGradient),
      (section: SettingsSection.language, label: s.sectionLanguage, icon: Icons.language_rounded, gradient: AppColors.languageGradient),
      (section: SettingsSection.advanced, label: s.sectionAdvanced, icon: Icons.tune_rounded, gradient: AppColors.advancedGradient),
      (section: SettingsSection.about, label: s.sectionAbout, icon: Icons.info_outline_rounded, gradient: AppColors.aboutGradient),
    ];
  }

  /// Builds the broker-aware settings controller and responsive layout.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SettingsViewModel(
        navigation: ctx.read<SettingsNavigationController>(),
        connectionPreferences: ctx.read<ConnectionPreferencesRepository>(),
        dashboardPreferences: ctx.read<DashboardPreferencesRepository>(),
        historyPreferences: ctx.read<HistoryPreferencesRepository>(),
        workspaceLayout: ctx.read<WorkspaceLayoutRepository>(),
        logger: ctx.read<AppLogger>(),
        brokerRepository: ctx.read<BrokerRepository>(),
        shortcutRepository: ctx.read<ShortcutRepository>(),
        variableRepository: ctx.read<VariableRepository>(),
        qosPreferences: ctx.read<QosPreferencesRepository>(),
        uiPreferences: ctx.read<UiPreferencesRepository>(),
        updatePreferences: ctx.read<UpdatePreferencesRepository>(),
        mqttSession: ctx.read<MqttSessionController>(),
        dashboardRepository: ctx.read<DashboardRepository>(),
        historyService: ctx.read<MessageHistoryService>(),
      ),
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
            SettingsSection.shortcuts => const ShortcutsPanel(),
            SettingsSection.monitoring => const MonitoringPanel(),
            SettingsSection.ui => const UiPanel(),
            SettingsSection.language => const LanguagePanel(),
            SettingsSection.advanced => const AdvancedPanel(),
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
