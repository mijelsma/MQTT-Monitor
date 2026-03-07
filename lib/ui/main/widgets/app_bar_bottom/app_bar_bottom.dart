import 'package:flutter/material.dart';
import 'status_pill.dart';

class AppBarBottom extends StatelessWidget {
  const AppBarBottom({super.key, this.isConnected = false, this.messageCount = 10312, this.messageRate = 0});

  final bool isConnected;
  final int messageCount;
  final int messageRate;

  @override
  Widget build(BuildContext context) {
    const brokerUrl = 'mqtt://127.0.0.1:1883';
    final cs = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant, letterSpacing: -0.1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bottom bar divider
        Container(height: .5, color: Theme.of(context).dividerColor),

        // Bottom bar content
        BottomAppBar(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Status pill
              StatusPill(isConnected: isConnected),

              // Spacer
              const SizedBox(width: 8),

              // Broker URL
              Expanded(
                child: Text(brokerUrl, style: labelStyle, overflow: TextOverflow.ellipsis),
              ),

              // Message count and rate
              Text('$messageCount msgs · $messageRate/s', style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }
}
