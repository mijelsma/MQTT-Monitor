import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/app_state.dart';
import '../../../../state/keys/settings_keys.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens/app_tokens.dart';
import '../../../settings/modals/broker_modal.dart';
import '../../../settings/models/broker_entry.dart';
import 'empty_state_shell.dart';

class NoSubscriptionsState extends StatelessWidget {
  const NoSubscriptionsState({super.key, required this.broker});

  final BrokerEntry broker;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return EmptyStateShell(
      gradientColors: AppColors.subscriptionsGradient,
      icon: Icons.topic_outlined,
      title: 'No topics subscribed',
      subtitle: "Broker is configured but has no topic subscriptions yet.",
      action: OutlinedButton.icon(
        onPressed: () => _openBrokerEditor(context),
        icon: Icon(Icons.edit_rounded, size: 16, color: tokens.primary),
        label: Text('Manage Subscriptions', style: TextStyle(color: tokens.primary)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: tokens.primary.withValues(alpha: 0.4))),
      ),
    );
  }

  Future<void> _openBrokerEditor(BuildContext context) async {
    final state = context.read<AppStateManager>();

    final updated = await showBrokerModal(
      context,
      broker: broker,
      // Delete: remove this broker from the list and close the modal.
      onDelete: () => _deleteBroker(state),
    );

    // Modal was dismissed without saving.
    if (updated == null) return;

    // Update the broker with new values from the modal.
    _updateBroker(state, updated);
  }

  // Helper to delete the broker from settings.
  void _deleteBroker(AppStateManager state) {
    final brokers = state.read(SettingsKeys.brokers);
    state.write(SettingsKeys.brokers, brokers.where((b) => b.id != broker.id).toList());
  }

  // Helper to update the broker in settings with new values.
  void _updateBroker(AppStateManager state, BrokerEntry updated) {
    final brokers = [...state.read(SettingsKeys.brokers)];
    final index = brokers.indexWhere((b) => b.id == updated.id);
    if (index == -1) return; // shouldn't happen, but just in case
    brokers[index] = updated;
    state.write(SettingsKeys.brokers, brokers);
  }
}
