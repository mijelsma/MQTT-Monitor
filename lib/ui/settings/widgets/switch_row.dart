import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import 'settings_row.dart';


class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.label, required this.subtitle, required this.value, required this.onChanged, this.isLast = true, this.accent});

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? context.tokens.primary;

    return SettingsRow(
      isLast: isLast,
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: context.tokens.textSecondary)),
        activeThumbColor: resolvedAccent,
        activeTrackColor: resolvedAccent.withValues(alpha: 0.35),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
