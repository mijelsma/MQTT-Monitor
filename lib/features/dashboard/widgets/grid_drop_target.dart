import 'package:flutter/material.dart';

import '../../../theme/app_tokens/app_tokens.dart';

/// Invisible drop target that highlights when a card hovers over it.
class GridDropTarget extends StatelessWidget {
  const GridDropTarget({super.key, required this.width, required this.height, required this.onAccept});

  final double width;
  final double height;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isHovering ? Border.all(color: tokens.primary, width: 1.5) : null,
            color: isHovering ? tokens.primary.withValues(alpha: 0.12) : null,
          ),
        );
      },
    );
  }
}
