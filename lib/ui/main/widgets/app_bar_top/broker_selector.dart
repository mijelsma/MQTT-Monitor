import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../state/app_state.dart';
import '../../../../state/keys/app_keys.dart';
import '../../../../state/keys/settings_keys.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens/app_tokens.dart';
import '../../../settings/models/broker_entry.dart';

class BrokerSelector extends StatelessWidget {
  const BrokerSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateManager>();
    final brokers = state.read(SettingsKeys.brokers);
    final activeBrokerId = state.read(AppKeys.activeBrokerId);

    // Resolve the active broker ID: use stored value if it still exists,
    String? effectiveId;
    if (activeBrokerId != null && brokers.any((b) => b.id == activeBrokerId)) {
      effectiveId = activeBrokerId;
    } else if (brokers.isNotEmpty) {
      effectiveId = brokers.first.id;
    }

    BrokerEntry? activeBroker;
    if (effectiveId != null) {
      activeBroker = brokers.firstWhere((b) => b.id == effectiveId, orElse: () => brokers.first);
    }

    final accent = context.tokens.primary;
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      onSelected: (id) => context.read<AppStateManager>().write(AppKeys.activeBrokerId, id),
      offset: const Offset(0, 42),
      enabled: brokers.isNotEmpty,
      itemBuilder: (_) => [for (final broker in brokers) _buildMenuItem(context, broker, broker.id == effectiveId, accent)],

      // Trigger button
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Connection status dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: AppColors.success500, shape: BoxShape.circle),
            ),

            // Spacer
            const SizedBox(width: 5),

            // Selected broker name
            Text(
              activeBroker?.name ?? 'No Broker',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface, letterSpacing: -0.1),
            ),

            // Spacer
            const SizedBox(width: 3),

            // Expand icon
            Icon(Icons.unfold_more_rounded, size: 13, color: cs.onSurfaceVariant),
          ],
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
          // Broker icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.brokerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.dns_rounded, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),

          // Broker name and URL
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

          // Selected checkmark
          if (isSelected) Icon(Icons.check_rounded, size: 14, color: accent),
        ],
      ),
    );
  }
}
