import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/dashboard_layout.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../../../theme/app_colors.dart';
import '../dialogs/layout_modal.dart';
import '../settings_viewmodel.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key});

  Future<void> _openAdd(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final layout = await showLayoutModal(context, brokers: vm.brokers);
    if (layout == null) return;
    vm.addLayout(layout);
  }

  Future<void> _openEdit(BuildContext context, DashboardLayout layout) async {
    final vm = context.read<SettingsViewModel>();
    final updated = await showLayoutModal(context, layout: layout, brokers: vm.brokers, onDelete: () => vm.deleteLayout(layout.id));
    if (updated == null) return;
    vm.updateLayout(updated);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final layouts = vm.layouts;

    return UiPanelScaffold(
      title: 'Dashboard',
      description: 'Manage your saved dashboard layouts.',
      children: [
        if (layouts.isEmpty)
          const UiEmptyState(icon: Icons.dashboard_outlined, title: 'No dashboards yet', message: 'Create dashboard or save from dashboard view')
        else
          UiSection(
            label: 'Dashboards',
            sortable: true,
            onReorder: (o, n) => vm.reorderLayouts(o, n),
            children: [
              for (int i = 0; i < layouts.length; i++)
                UiSortableRow(
                  key: ValueKey(layouts[i].id),
                  index: i,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.brokerGradientFor(layouts[i].colorIndex)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(layouts[i].isGlobal ? Icons.public_rounded : Icons.dns_rounded, size: 18, color: Colors.white),
                  ),
                  title: layouts[i].title,
                  onTap: () => _openEdit(context, layouts[i]),
                  onDelete: () => vm.deleteLayout(layouts[i].id),
                ),
            ],
          ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FilledButton.icon(
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add dashboard'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), textStyle: Theme.of(context).textTheme.labelLarge),
            ),
          ),
        ),
      ],
    );
  }
}
