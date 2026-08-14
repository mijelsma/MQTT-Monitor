import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state_shell.dart';
import '../../../theme/app_colors.dart';
import '../../settings/dialogs/broker_dialog.dart';
import '../view_models/monitor_view_model.dart';

/// Prompts the user to create a broker when none are configured.
class NoBrokersState extends StatelessWidget {
  /// Creates the empty broker state.
  const NoBrokersState({super.key});

  /// Builds the empty state and add-broker action.
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

  /// Opens the broker dialog and persists the created profile.
  Future<void> _addBroker(BuildContext context) async {
    final vm = context.read<MonitorViewModel>();
    final entry = await showBrokerDialog(context);
    if (entry == null) return;
    await vm.addBroker(entry);
  }
}
