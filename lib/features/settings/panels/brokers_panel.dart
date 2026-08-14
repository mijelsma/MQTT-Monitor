import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../theme/app_colors.dart';
import '../../../core/broker/models/broker_entry_model.dart';
import '../../../shared/widgets/ui_add_button.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_inline_notice.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../dialogs/broker_dialog.dart';
import '../view_models/settings_view_model.dart';

/// Displays broker CRUD, reorder, and persistence-recovery controls.
class BrokersPanel extends StatelessWidget {
  /// Creates the broker settings panel.
  const BrokersPanel({super.key});

  /// Opens the broker dialog and persists a newly created profile.
  Future<void> _openAdd(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final entry = await showBrokerDialog(context);
    if (entry == null) return;
    await vm.addBroker(entry);
  }

  /// Opens the broker dialog and persists edits or deletion.
  Future<void> _openEdit(BuildContext context, BrokerEntryModel broker) async {
    final vm = context.read<SettingsViewModel>();
    final updated = await showBrokerDialog(context, broker: broker, onDelete: () async => vm.deleteBroker(broker.id));
    if (updated == null) return;
    await vm.updateBroker(updated);
  }

  /// Builds broker rows or an actionable persistence failure notice.
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final brokers = vm.brokers;
    final s = S.of(context);

    return UiPanelScaffold(
      title: s.brokersPanelTitle,
      description: s.brokersPanelDescription,
      children: [
        if (vm.brokerFailure case final failure?)
          UiInlineNotice(kind: UiNoticeKind.error, title: s.brokerProfilesUnavailable, message: failure.message, detail: failure.details, actionLabel: s.retry, onAction: vm.retryBrokerLoad, margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8))
        else if (brokers.isEmpty)
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
        if (vm.brokerFailure == null) UiAddButton(label: s.brokersPanelAddBroker, onPressed: () => _openAdd(context)),
      ],
    );
  }
}
