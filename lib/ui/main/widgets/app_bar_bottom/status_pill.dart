import 'package:flutter/material.dart';
import '../../../../services/mqtt/models/connection_status.dart';
import '../../../../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.errorDetail});

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
          // Status indicator circle
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          // Spacer
          const SizedBox(width: 5),

          // Status text
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.1),
          ),
        ],
      ),
    );
  }
}
