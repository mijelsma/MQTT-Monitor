import 'package:flutter/material.dart';

import '../../theme/app_tokens/app_tokens.dart';

/// A quiet, bordered grouping surface for related controls and content.
///
/// This is deliberately flatter than a Material card. Use it for a logical
/// group, not as decoration around every child widget.
class UiSurface extends StatelessWidget {
  const UiSurface({super.key, required this.child, this.padding = EdgeInsets.zero, this.backgroundColor, this.borderColor, this.radius, this.clipBehavior = Clip.antiAlias});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? radius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final surfaceRadius = BorderRadius.circular(radius ?? tokens.panelRadius);

    return Container(
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.surface,
        borderRadius: surfaceRadius,
        border: Border.all(color: borderColor ?? tokens.border, width: 0.5),
      ),
      padding: padding,
      child: child,
    );
  }
}
