import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../shared/widgets/empty_state_shell.dart';
import '../../../theme/app_colors.dart';

class TopicTreeEmptyState extends StatelessWidget {
  const TopicTreeEmptyState({super.key, required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (hasFilter) {
      return EmptyStateShell(gradientColors: AppColors.messagesGradient, icon: Icons.search_off_rounded, title: s.filterNoMatchingTopics, subtitle: s.filterNoMatchingTopicsSubtitle);
    }

    return EmptyStateShell(gradientColors: AppColors.messagesGradient, icon: Icons.account_tree_outlined, title: s.noMessagesTitle, subtitle: s.noMessagesSubtitle);
  }
}
