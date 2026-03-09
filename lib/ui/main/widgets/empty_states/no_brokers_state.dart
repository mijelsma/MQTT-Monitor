import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../state/app_state.dart';
import '../../../../state/keys/app_keys.dart';
import '../../../../state/keys/settings_keys.dart';
import '../../../../theme/app_colors.dart';
import '../../../settings/modals/broker_modal.dart';
import 'empty_state_shell.dart';

class NoBrokersState extends StatelessWidget {
  const NoBrokersState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateShell(
      gradientColors: AppColors.brokerGradient,
      icon: Icons.dns_rounded,
      title: 'No brokers configured',
      subtitle: 'Add an MQTT broker to start monitoring messages.',
      action: FilledButton.icon(onPressed: () => _addBroker(context), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add Broker')),
    );
  }

  Future<void> _addBroker(BuildContext context) async {
    final state = context.read<AppStateManager>();
    final entry = await showBrokerModal(context);
    if (entry == null) return;
    final updated = [...state.read(SettingsKeys.brokers), entry];
    state.write(SettingsKeys.brokers, updated);
    state.write(AppKeys.activeBrokerId, entry.id);
  }
}
