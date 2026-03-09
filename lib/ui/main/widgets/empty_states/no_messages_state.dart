import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'empty_state_shell.dart';

class NoMessagesState extends StatelessWidget {
  const NoMessagesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateShell(
      gradientColors: AppColors.messagesGradient,
      icon: Icons.inbox_rounded,
      title: 'Waiting for messages',
      subtitle: 'No messages received yet.', //
    );
  }
}
