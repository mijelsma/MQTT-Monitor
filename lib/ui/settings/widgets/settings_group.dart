import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cardColor   = context.tokens.surface;
    final borderColor = context.tokens.border;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
