import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens/app_tokens.dart';

class BrokerSelector extends StatelessWidget {
  const BrokerSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.primary;

    return PopupMenuButton<String>(
      onSelected: (_) {},
      offset: const Offset(0, 42),
      itemBuilder: (_) => [
        // Broker menu item
        PopupMenuItem<String>(
          value: 'placeholder',
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
                    Text('Local Broker', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    Text('mqtt://127.0.0.1:1883', style: TextStyle(fontSize: 10.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),

              // Selected checkmark
              Icon(Icons.check_rounded, size: 14, color: accent),
            ],
          ),
        ),
      ],

      // Trigger button
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Connection status dot
            Container(width: 5, height: 5, decoration: BoxDecoration(color: AppColors.success500, shape: BoxShape.circle)),

            // Spacer
            const SizedBox(width: 5),

            // Selected broker name
            Text('Local Broker',style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.1),),
            
            // Spacer
            const SizedBox(width: 3),

            // Expand icon
            Icon(Icons.unfold_more_rounded, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
