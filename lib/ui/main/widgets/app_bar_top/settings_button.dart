import 'package:flutter/material.dart';
import '../../../settings/settings_screen.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const borderRadius = BorderRadius.all(Radius.circular(8));

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: cs.surface,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
            ),
            child: Icon(Icons.tune_rounded, size: 18, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
