import 'package:flutter/material.dart';

import '../../../core/mqtt/connection_status.dart';
import '../../../theme/app_colors.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key, this.status = ConnectionStatus.disconnected, this.brokerUrl, this.errorDetail, this.messageCount = 0, this.messageRate = 0});

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
        Container(height: 1.0, color: Theme.of(context).dividerColor),
        BottomAppBar(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatusPill(status: status, errorDetail: errorDetail),
              const SizedBox(width: 8),
              if (brokerUrl != null)
                Expanded(
                  child: Text(brokerUrl!, style: labelStyle, overflow: TextOverflow.ellipsis),
                )
              else
                const Spacer(),
              if (errorDetail != null && errorDetail!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Tooltip(
                    message: errorDetail!,
                    child: Text(
                      errorDetail!,
                      style: labelStyle.copyWith(color: AppColors.error500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text('$messageCount msgs · $messageRate/s', style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, this.errorDetail});

  final ConnectionStatus status;
  final String? errorDetail;

  @override
  Widget build(BuildContext context) {
    var (color, label) = switch (status) {
      ConnectionStatus.connected => (AppColors.success500, 'Connected'),
      ConnectionStatus.connecting => (AppColors.warning500, 'Connecting'),
      ConnectionStatus.disconnected => (AppColors.error500, 'Disconnected'),
      ConnectionStatus.errorHostNotFound => (AppColors.error500, 'Host not found'),
      ConnectionStatus.errorNotPermitted => (AppColors.error500, 'Not permitted'),
      ConnectionStatus.errorRefused => (AppColors.error500, 'Connection refused'),
      ConnectionStatus.errorTlsHandshake => (AppColors.error500, 'TLS failed'),
      ConnectionStatus.error => (AppColors.error500, 'Error'),
    };

    if (status == ConnectionStatus.error && errorDetail != null) {
      final trimmed = errorDetail!.length > 28 ? '${errorDetail!.substring(0, 28)}…' : errorDetail!;
      label = 'Error · $trimmed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.1),
          ),
        ],
      ),
    );
  }
}
