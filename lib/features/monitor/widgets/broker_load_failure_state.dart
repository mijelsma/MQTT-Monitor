import 'package:flutter/material.dart';

import '../../../core/broker/broker_repository_failure.dart';
import '../../../shared/widgets/empty_state_shell.dart';
import '../../../theme/app_colors.dart';

/// Shows a recoverable empty state when broker profiles cannot be loaded.
class BrokerLoadFailureState extends StatelessWidget {
  /// Creates the failure state for [failure] with a retry [onRetry] action.
  const BrokerLoadFailureState({super.key, required this.failure, required this.onRetry});

  final BrokerRepositoryFailure failure;
  final Future<void> Function() onRetry;

  /// Builds the error presentation and retry button.
  @override
  Widget build(BuildContext context) {
    return EmptyStateShell(
      gradientColors: const [AppColors.error500, AppColors.warning500],
      icon: Icons.storage_rounded,
      title: 'Broker profiles unavailable',
      subtitle: failure.message,
      action: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
    );
  }
}
