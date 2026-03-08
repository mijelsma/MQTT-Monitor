import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// A bordered switch tile for toggling SSL / TLS on a broker connection.
/// Shared between [BrokerModal] and any future place that needs it.
class SslToggle extends StatelessWidget {
  const SslToggle({super.key, required this.value, required this.accent, required this.onChanged});

  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: const Text('Use SSL / TLS', style: TextStyle(fontSize: 14)),
        subtitle: Text('Encrypts the connection using TLS', style: TextStyle(fontSize: 11.5, color: tokens.textSecondary)),
        value: value,
        activeThumbColor: accent,
        activeTrackColor: accent.withValues(alpha: 0.35),
        onChanged: onChanged,
      ),
    );
  }
}
