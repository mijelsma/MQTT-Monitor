import 'package:flutter/material.dart';

import '../../theme/app_tokens/app_tokens.dart';
import '../../theme/ui_layout.dart';

/// Accessible interactive header for a collapsible workspace panel.
class WorkspacePanelHeader extends StatefulWidget {
  /// Creates a panel header.
  const WorkspacePanelHeader({super.key, required this.title, required this.icon, required this.collapsed, required this.onToggle, required this.animationDuration});

  /// User-facing panel title.
  final String title;

  /// Leading icon.
  final IconData icon;

  /// Whether the associated panel is collapsed.
  final bool collapsed;

  /// Invoked by pointer, keyboard, or accessibility activation.
  final VoidCallback onToggle;

  /// Duration of the disclosure-arrow animation.
  final Duration animationDuration;

  @override
  State<WorkspacePanelHeader> createState() => _WorkspacePanelHeaderState();
}

class _WorkspacePanelHeaderState extends State<WorkspacePanelHeader> {
  bool _hovering = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final layout = context.uiLayout;
    return Semantics(
      button: true,
      header: true,
      expanded: !widget.collapsed,
      label: widget.title,
      onTap: widget.onToggle,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            canRequestFocus: true,
            onTap: widget.onToggle,
            onHover: (value) => setState(() => _hovering = value),
            onFocusChange: (value) => setState(() => _focused = value),
            mouseCursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: layout.isCompact ? 8 : 10),
              decoration: BoxDecoration(
                color: _hovering || _focused ? tokens.elevated : tokens.surface,
                border: Border(
                  bottom: BorderSide(color: tokens.border, width: 0.5),
                  left: BorderSide(color: _focused ? tokens.primary : Colors.transparent, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: widget.collapsed ? tokens.elevated : tokens.selectedBg, borderRadius: BorderRadius.circular(7)),
                    child: Icon(widget.icon, size: 13, color: widget.collapsed ? tokens.textTertiary : tokens.primary),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: tokens.textSecondary),
                    ),
                  ),
                  AnimatedRotation(
                    turns: widget.collapsed ? -0.25 : 0,
                    duration: widget.animationDuration,
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.expand_more_rounded, size: 16, color: tokens.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
