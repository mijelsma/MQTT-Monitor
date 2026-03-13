import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/mqtt/connection_status.dart';
import '../monitor_viewmodel.dart';

class ConnectionButton extends StatelessWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();
    final brokers = vm.brokers;
    final connectionStatus = vm.connectionStatus;

    if (brokers.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    const borderRadius = BorderRadius.all(Radius.circular(8));

    final (icon, onTap) = switch (connectionStatus) {
      ConnectionStatus.connected || ConnectionStatus.connecting => (Icons.link_off_rounded, vm.disconnect as VoidCallback?),
      _ => (Icons.link_rounded, vm.reconnect as VoidCallback?),
    };

    final iconColor = onTap != null ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.35);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: cs.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}
