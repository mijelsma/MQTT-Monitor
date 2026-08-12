import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/mqtt/connection_status.dart';
import '../../../generated/l10n.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../../models/broker_entry.dart';
import '../monitor_viewmodel.dart';

class BrokerSelector extends StatefulWidget {
  const BrokerSelector({super.key});

  @override
  State<BrokerSelector> createState() => _BrokerSelectorState();
}

class _BrokerSelectorState extends State<BrokerSelector> {
  final _menuKey = GlobalKey<PopupMenuButtonState<String>>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();
    final brokers = vm.brokers;
    final activeBroker = vm.activeBroker;
    final connectionStatus = vm.connectionStatus;

    final tokens = context.tokens;
    final accent = tokens.primary;
    final cs = Theme.of(context).colorScheme;

    final dotColor = switch (connectionStatus) {
      ConnectionStatus.connected => tokens.success,
      ConnectionStatus.connecting => tokens.warning,
      _ => tokens.error,
    };

    const borderRadius = BorderRadius.all(Radius.circular(8));

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: cs.surface,
        child: InkWell(
          onTap: brokers.isNotEmpty ? () => _menuKey.currentState?.showButtonMenu() : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: PopupMenuButton<String>(key: _menuKey, onSelected: (id) => vm.selectBroker(id), offset: const Offset(0, 46), enabled: brokers.isNotEmpty, itemBuilder: (_) => [for (final broker in brokers) _buildMenuItem(context, broker, broker.id == activeBroker?.id, accent)], child: const SizedBox.expand()),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeBroker?.name ?? S.of(context).noBroker,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface, letterSpacing: -0.1),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.unfold_more_rounded, size: 14, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuEntry<String> _buildMenuItem(BuildContext context, BrokerEntry broker, bool isSelected, Color accent) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      value: broker.id,
      height: 52,
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.brokerGradientFor(broker.colorIndex), begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  broker.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface),
                ),
                Text(broker.displayAddress, style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (isSelected) Icon(Icons.check_rounded, size: 14, color: accent),
        ],
      ),
    );
  }
}
