import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/broker/broker_repository.dart';
import '../../core/history/message_history_service.dart';
import '../../core/mqtt/mqtt_service.dart';
import '../../core/state/app_state.dart';
import '../../core/state/keys/app_keys.dart';
import '../../models/dashboard_layout.dart';
import '../../shared/widgets/empty_state_shell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';
import '../settings/dialogs/create_dashboard_dialog.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_section.dart';
import 'dashboard_view_model.dart';
import 'dialogs/new_empty_dashboard_dialog.dart';
import 'dialogs/save_dashboard_dialog.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/dashboard_grid.dart';
import 'widgets/variable_bar.dart';

/// Main dashboard screen. Provides a [DashboardViewModel] to the widget tree.
class GraphDashboardScreen extends StatelessWidget {
  /// Creates a dashboard scoped to [brokerId] and labeled [brokerName].
  const GraphDashboardScreen({super.key, required this.brokerId, required this.brokerName});

  final String brokerId;
  final String brokerName;

  /// Creates the broker-aware dashboard view model and screen scaffold.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => DashboardViewModel(mqttService: ctx.read<MqttService>(), state: ctx.read<AppStateManager>(), brokerId: brokerId, historyService: ctx.read<MessageHistoryService>(), brokerRepository: ctx.read<BrokerRepository>()),
      child: _DashboardScaffold(brokerName: brokerName),
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({required this.brokerName});

  final String brokerName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<DashboardViewModel>();

    return Scaffold(
      appBar: DashboardAppBar(
        onSaveLayout: () => _showSaveDialog(context, vm),
        onUpdateLayout: () => vm.updateActiveLayout(),
        onDiscardChanges: () => vm.discardChanges(),
        onNewEmpty: () => _showNewEmptyDialog(context, vm),
        onEditLayout: (layout) => _showEditLayoutDialog(context, vm, layout),
        onManageDashboards: () => _openSettings(context, SettingsSection.dashboard),
        onManageVariables: () => _openSettings(context, SettingsSection.variables),
        onEraseHistory: () => _confirmEraseHistory(context, vm),
        onOpenSettings: () => _openSettings(context, SettingsSection.brokers),
      ),
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          VariableBar(variables: vm.environmentVariables, values: vm.variableValues, onChanged: vm.setVariableValue),
          Expanded(child: _buildBody(vm)),
        ],
      ),
    );
  }

  Widget _buildBody(DashboardViewModel vm) {
    if (vm.cards.isEmpty) {
      return const EmptyStateShell(icon: Icons.bar_chart_rounded, gradientColors: AppColors.messagesGradient, title: 'No graphs yet', subtitle: 'Pin a numeric value from the topic viewer\nto start tracking it here.');
    }
    return DashboardGrid(vm: vm);
  }

  void _showSaveDialog(BuildContext context, DashboardViewModel vm) async {
    final result = await showSaveDashboardDialog(context, brokerName: brokerName, brokerId: vm.brokerId);
    if (result == null) return;
    await vm.saveLayout(title: result.title, brokerIds: result.brokerIds, colorIndex: result.colorIndex);
  }

  void _showNewEmptyDialog(BuildContext context, DashboardViewModel vm) async {
    final confirm = await showNewEmptyDashboardDialog(context);
    if (confirm != true) return;
    await vm.clearDashboard();
  }

  void _showEditLayoutDialog(BuildContext context, DashboardViewModel vm, DashboardLayout layout) async {
    final updated = await showCreateDashboardDialog(context, dashboard: layout, brokers: vm.brokers, onDelete: () => vm.deleteLayout(layout.id));
    if (updated == null) return;
    await vm.updateLayoutMetadata(updated);
  }

  void _confirmEraseHistory(BuildContext context, DashboardViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erase history'),
        content: const Text('This will clear all recorded history and data points for the topics in this dashboard.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error500),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    vm.clearDashboardHistory();
  }

  void _openSettings(BuildContext context, SettingsSection section) {
    context.read<AppStateManager>().write(AppKeys.activeSettingsSection, section);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }
}
