import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppBarBottom extends StatelessWidget {
  const AppBarBottom({
    super.key,
    this.isConnected = true,
    this.brokerUrl = 'mqtt://127.0.0.1:1883',
    this.messageCount = 10312,
    this.messageRate = 0,
  });

  final bool isConnected;
  final String brokerUrl;
  final int messageCount;
  final int messageRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = theme.bottomAppBarTheme.color ?? theme.colorScheme.primary;
    final textColor = theme.colorScheme.onPrimary;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: textColor);

    return BottomAppBar(
      color: barColor,
      elevation: theme.bottomAppBarTheme.elevation ?? 0,
      height: theme.bottomAppBarTheme.height ?? 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.success500 : AppColors.error500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${isConnected ? 'Connected' : 'Disconnected'} — $brokerUrl',
            style: labelStyle,
          ),
          const Spacer(),
          Text('${messageCount} msgs\u2002|\u20020 msg/s', style: labelStyle),
        ],
      ),
    );
  }
}
