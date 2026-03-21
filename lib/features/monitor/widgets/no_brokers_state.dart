import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state_shell.dart';
import '../../../theme/app_colors.dart';
import '../../settings/dialogs/broker_dialog.dart';
import '../monitor_viewmodel.dart';

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
    final vm = context.read<MonitorViewModel>();
    final entry = await showBrokerDialog(context);
    if (entry == null) return;
    vm.addBroker(entry);
  }
}
