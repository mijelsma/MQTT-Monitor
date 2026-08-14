import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_tokens/app_tokens.dart';

/// Pointer- and keyboard-resizable divider between workspace panels.
class WorkspacePanelDivider extends StatefulWidget {
  /// Creates a divider.
  const WorkspacePanelDivider({super.key, required this.semanticLabel, required this.onDragUpdate, required this.onIncrease, required this.onDecrease});

  /// Accessibility label describing the panels being resized.
  final String semanticLabel;

  /// Handles pointer drag changes.
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  /// Makes the panel above the divider larger.
  final VoidCallback onIncrease;

  /// Makes the panel above the divider smaller.
  final VoidCallback onDecrease;

  @override
  State<WorkspacePanelDivider> createState() => _WorkspacePanelDividerState();
}

class _WorkspacePanelDividerState extends State<WorkspacePanelDivider> {
  final FocusNode _focusNode = FocusNode();
  bool _hovering = false;
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final active = _hovering || _focused;
    final lineColor = active ? tokens.primary.withValues(alpha: 0.6) : tokens.border;
    final gripColor = active ? tokens.primary.withValues(alpha: 0.8) : tokens.border;
    return Semantics(
      label: widget.semanticLabel,
      slider: true,
      onIncrease: widget.onIncrease,
      onDecrease: widget.onDecrease,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onIncrease();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onDecrease();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusNode.requestFocus,
            onVerticalDragStart: (_) => _focusNode.requestFocus(),
            onVerticalDragUpdate: widget.onDragUpdate,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: double.infinity, height: 1, color: lineColor),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: gripColor, borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
