import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n.dart';
import '../../../state/app_state.dart';
import '../../../state/keys/settings_keys.dart';
import '../../../theme/app_colors.dart';
import '../models/broker_entry.dart';
import '../modals/broker_modal.dart';
import '../../elements/ui_empty_state.dart';
import '../../elements/ui_panel_scaffold.dart';
import '../../elements/ui_section.dart';
import '../../elements/ui_sortable_row.dart';

class BrokersPanel extends StatelessWidget {
  const BrokersPanel({super.key});

  Future<void> _openAdd(BuildContext context) async {
    final state = context.read<AppStateManager>();
    final entry = await showBrokerModal(context);
    if (entry == null) return;
    final updated = [...state.read(SettingsKeys.brokers), entry];
    state.write(SettingsKeys.brokers, updated);
  }

  Future<void> _openEdit(BuildContext context, BrokerEntry broker) async {
    final state = context.read<AppStateManager>();
    final updated = await showBrokerModal(context, broker: broker, onDelete: () => _delete(context, broker.id));
    if (updated == null) return;
    final brokers = [...state.read(SettingsKeys.brokers)];
    final i = brokers.indexWhere((b) => b.id == updated.id);
    if (i != -1) brokers[i] = updated;
    state.write(SettingsKeys.brokers, brokers);
  }

  void _delete(BuildContext context, String id) {
    final state = context.read<AppStateManager>();
    final updated = state.read(SettingsKeys.brokers).where((b) => b.id != id).toList();
    state.write(SettingsKeys.brokers, updated);
  }

  void _reorder(BuildContext context, int oldIndex, int newIndex) {
    final state = context.read<AppStateManager>();
    final brokers = [...state.read(SettingsKeys.brokers)];
    if (newIndex > oldIndex) newIndex--;
    final item = brokers.removeAt(oldIndex);
    brokers.insert(newIndex, item);
    state.write(SettingsKeys.brokers, brokers);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brokers = context.watch<AppStateManager>().read(SettingsKeys.brokers);

    final s = S.of(context);

    return UiPanelScaffold(
      title: s.brokersPanelTitle,
      description: s.brokersPanelDescription,
      children: [
        // Connections section
        if (brokers.isEmpty)
          UiEmptyState(icon: Icons.dns_outlined, title: s.brokersPanelNoBrokersTitle, message: s.brokersPanelNoBrokersMessage)
        else
          UiSection(
            label: s.brokersPanelSectionConnections,
            sortable: true,
            onReorder: (o, n) => _reorder(context, o, n),
            children: [
              for (int i = 0; i < brokers.length; i++)
                UiSortableRow(
                  key: ValueKey(brokers[i].id),
                  index: i,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.brokerGradient),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.dns_rounded, size: 18, color: Colors.white),
                  ),
                  title: brokers[i].name,
                  subtitle: brokers[i].displayAddress,
                  onTap: () => _openEdit(context, brokers[i]),
                  onDelete: () => _delete(context, brokers[i].id),
                ),
            ],
          ),

        // Add broker button
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
