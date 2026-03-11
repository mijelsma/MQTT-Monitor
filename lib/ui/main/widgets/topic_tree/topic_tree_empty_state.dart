import 'package:flutter/material.dart';

import '../../../../generated/l10n.dart';
import '../../../../theme/app_colors.dart';
import '../empty_states/empty_state_shell.dart';

class TopicTreeEmptyState extends StatelessWidget {
  const TopicTreeEmptyState({super.key, required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (hasFilter) {
      return EmptyStateShell(gradientColors: AppColors.messagesGradient, icon: Icons.search_off_rounded, title: 'No matching topics', subtitle: 'Try adjusting or clearing the filter.');
    }

    return EmptyStateShell(gradientColors: AppColors.messagesGradient, icon: Icons.account_tree_outlined, title: s.noMessagesTitle, subtitle: s.noMessagesSubtitle);
  }
}
