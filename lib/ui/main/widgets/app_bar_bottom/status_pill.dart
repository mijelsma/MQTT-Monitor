import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.success500 : AppColors.error500;

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
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.1),
          ),
        ],
      ),
    );
  }
}
