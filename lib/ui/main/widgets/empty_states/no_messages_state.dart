import 'package:flutter/material.dart';
import '../../../../generated/l10n.dart';
import '../../../../theme/app_colors.dart';
import 'empty_state_shell.dart';

class NoMessagesState extends StatelessWidget {
  const NoMessagesState({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EmptyStateShell(gradientColors: AppColors.messagesGradient, icon: Icons.inbox_rounded, title: s.noMessagesTitle, subtitle: s.noMessagesSubtitle);
  }
}
