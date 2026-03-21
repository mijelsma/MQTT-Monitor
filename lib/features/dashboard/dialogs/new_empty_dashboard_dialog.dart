import 'package:flutter/material.dart';

/// Shows a confirmation dialog before clearing the current dashboard.
///
/// Returns `true` if the user confirms, `null` or `false` if cancelled.
Future<bool?> showNewEmptyDashboardDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('New empty dashboard'),
      content: const Text('This will clear any unsaved cards from the current dashboard. Continue?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
      ],
    ),
  );
}
