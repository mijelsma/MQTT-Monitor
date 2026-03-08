import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';
import '../widgets/spacers.dart';

class UiField extends StatelessWidget {
  const UiField({super.key, required this.label, this.optional = false, required this.child});

  final String label;
  final bool optional;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            if (optional) ...[const SizedBox(width: 6), Text('optional', style: TextStyle(fontSize: 11, color: context.tokens.textSecondary))],
          ],
        ),
        const VSpacer(6),
        child,
      ],
    );
  }
}
