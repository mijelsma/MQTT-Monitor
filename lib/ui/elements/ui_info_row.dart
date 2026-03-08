import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';

class UiInfoRow extends StatelessWidget {
  const UiInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 14, color: context.tokens.textSecondary)),
        ],
      ),
    );
  }
}
