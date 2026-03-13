import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../theme/app_colors.dart';
import '../../../models/broker_entry.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../modals/broker_modal.dart';
import '../settings_viewmodel.dart';

class BrokersPanel extends StatelessWidget {
  const BrokersPanel({super.key});

  Future<void> _openAdd(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final entry = await showBrokerModal(context);
    if (entry == null) return;
    vm.addBroker(entry);
  }

  Future<void> _openEdit(BuildContext context, BrokerEntry broker) async {
    final vm = context.read<SettingsViewModel>();
    final updated = await showBrokerModal(context, broker: broker, onDelete: () => vm.deleteBroker(broker.id));
    if (updated == null) return;
    vm.updateBroker(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<SettingsViewModel>();
    final brokers = vm.brokers;
    final s = S.of(context);

    return UiPanelScaffold(
      title: s.brokersPanelTitle,
      description: s.brokersPanelDescription,
      children: [
        if (brokers.isEmpty)
          UiEmptyState(icon: Icons.dns_outlined, title: s.brokersPanelNoBrokersTitle, message: s.brokersPanelNoBrokersMessage)
        else
          UiSection(
            label: s.brokersPanelSectionConnections,
            sortable: true,
            onReorder: (o, n) => vm.reorderBrokers(o, n),
            children: [
              for (int i = 0; i < brokers.length; i++)
                UiSortableRow(
                  key: ValueKey(brokers[i].id),
                  index: i,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.brokerGradientFor(brokers[i].colorIndex)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.dns_rounded, size: 18, color: Colors.white),
                  ),
                  title: brokers[i].name,
                  subtitle: brokers[i].displayAddress,
                  onTap: () => _openEdit(context, brokers[i]),
                  onDelete: () => vm.deleteBroker(brokers[i].id),
                ),
            ],
          ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FilledButton.icon(
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(s.brokersPanelAddBroker),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), textStyle: theme.textTheme.labelLarge),
            ),
          ),
        ),
      ],
    );
  }
}
