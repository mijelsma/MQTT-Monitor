import 'package:flutter/material.dart';
import '../../../../services/mqtt/models/connection_status.dart';
import 'status_pill.dart';

class AppBarBottom extends StatelessWidget {
  const AppBarBottom({super.key, this.status = ConnectionStatus.disconnected, this.brokerUrl, this.errorDetail, this.messageCount = 0, this.messageRate = 0});

  final ConnectionStatus status;
  final String? brokerUrl;
  final String? errorDetail;
  final int messageCount;
  final int messageRate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant, letterSpacing: -0.1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divider
        Container(height: .5, color: Theme.of(context).dividerColor),

        BottomAppBar(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Status pill
              StatusPill(status: status, errorDetail: errorDetail),

              const SizedBox(width: 8),

              // Broker URL
              if (brokerUrl != null)
                Expanded(
                  child: Text(brokerUrl!, style: labelStyle, overflow: TextOverflow.ellipsis),
                )
              else
                const Spacer(),

              // Message stats
              Text('$messageCount msgs · $messageRate/s', style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }
}
