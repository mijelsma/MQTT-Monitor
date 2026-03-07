import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.isLast,
    required this.separatorColor,
  });

  final String label;
  final String value;
  final bool isLast;
  final Color separatorColor;

  @override
  Widget build(BuildContext context) {
    final secondary = context.tokens.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 14, color: secondary)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 0.5, thickness: 0.5, color: separatorColor),
      ],
    );
  }
}
