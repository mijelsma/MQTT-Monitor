import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/broker_entry.dart';
import '../../../shared/widgets/empty_state_shell.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../settings/dialogs/broker_dialog.dart';
import '../monitor_viewmodel.dart';

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
    final vm = context.read<MonitorViewModel>();

    final updated = await showBrokerDialog(context, broker: broker, onDelete: () => vm.deleteBroker(broker.id));

    if (updated == null) return;
    vm.updateBroker(updated);
  }
}
