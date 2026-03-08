import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// A small form-field label with an optional "optional" hint.
/// Used across all settings modals.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, this.optional = false});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        if (optional) ...[const SizedBox(width: 6), Text('optional', style: TextStyle(fontSize: 11, color: context.tokens.textSecondary))],
      ],
    );
  }
}
