import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';

class UiSwitchRow extends StatelessWidget {
  const UiSwitchRow({super.key, required this.label, required this.subtitle, required this.value, required this.onChanged, this.accent, this.bordered = false});

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accent;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedAccent = accent ?? tokens.primary;

    final tile = SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: tokens.textSecondary)),
      value: value,
      activeThumbColor: resolvedAccent,
      activeTrackColor: resolvedAccent.withValues(alpha: 0.35),
      onChanged: onChanged,
    );

    if (!bordered) return tile;
    return Container(
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: tile,
    );
  }
}
