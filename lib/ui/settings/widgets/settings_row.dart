import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.child,
    this.dividerIndent = 0,
    this.isLast = false,
  });

  final Widget child;

  /// Left indent (in logical pixels) of the row divider.
  final double dividerIndent;

    /// When `true` no trailing divider is rendered.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final separatorColor = context.tokens.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (!isLast)
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: separatorColor,
            indent: dividerIndent,
          ),
      ],
    );
  }
}
