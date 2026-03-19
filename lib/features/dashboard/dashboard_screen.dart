import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/state/keys/app_keys.dart';
import '../../models/dashboard_layout.dart';
import '../../shared/widgets/empty_state_shell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';
import '../settings/modals/layout_modal.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_section.dart';
import 'dashboard_view_model.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/save_preset_dialog.dart';
import 'widgets/variable_bar.dart';

class GraphDashboardScreen extends StatelessWidget {
  const GraphDashboardScreen({super.key, required this.brokerId, required this.brokerName});

  final String brokerId;
  final String brokerName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => DashboardViewModel(state: ctx.read<AppStateManager>(), brokerId: brokerId),
      child: _DashboardView(brokerName: brokerName, brokerId: brokerId),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.brokerName, required this.brokerId});

  final String brokerName;
  final String brokerId;

  void _showSaveLayoutDialog(BuildContext context, DashboardViewModel vm) async {
    final result = await showSaveLayoutDialog(context, brokerName: brokerName, brokerId: vm.brokerId);
    if (result == null) return;
    await vm.saveLayout(title: result.title, brokerIds: result.brokerIds, colorIndex: result.colorIndex);
  }

  void _newEmptyDashboard(BuildContext context, DashboardViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New empty dashboard'),
        content: const Text('This will clear all cards from the current dashboard. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirm != true) return;
    await vm.clearDashboard();
  }

  void _editLayout(BuildContext context, DashboardViewModel vm, DashboardLayout layout) async {
    final updated = await showLayoutModal(context, layout: layout, brokers: vm.brokers, onDelete: () => vm.deleteLayout(layout.id));
    if (updated == null) return;
    await vm.updateLayoutMetadata(updated);
  }

  void _openSettingsAt(BuildContext context, SettingsSection section) {
    context.read<AppStateManager>().write(AppKeys.activeSettingsSection, section);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<DashboardViewModel>();

    return Scaffold(
      appBar: DashboardAppBar(
        brokerName: brokerName,
        onSaveLayout: () => _showSaveLayoutDialog(context, vm),
        onNewEmpty: () => _newEmptyDashboard(context, vm),
        onEditLayout: (layout) => _editLayout(context, vm, layout),
        onManageDashboards: () => _openSettingsAt(context, SettingsSection.dashboard),
        onManageVariables: () => _openSettingsAt(context, SettingsSection.variables),
      ),
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          VariableBar(vm: vm),
          Expanded(
            child: EmptyStateShell(icon: Icons.bar_chart_rounded, gradientColors: AppColors.messagesGradient, title: 'No graphs yet', subtitle: 'Pin a numeric value from the topic viewer\nto start tracking it here.'),
          ),
        ],
      ),
    );
  }
}
