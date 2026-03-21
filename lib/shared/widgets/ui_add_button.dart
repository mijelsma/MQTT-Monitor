import 'package:flutter/material.dart';

/// Full-width add button used across settings panels (brokers, dashboard, etc.).
class UiAddButton extends StatelessWidget {
  const UiAddButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(label),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), textStyle: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}
