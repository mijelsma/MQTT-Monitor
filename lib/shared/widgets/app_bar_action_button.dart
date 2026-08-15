import 'package:flutter/material.dart';

import '../../theme/app_tokens/app_tokens.dart';
import '../../theme/ui_layout.dart';

class AppBarActionButton extends StatefulWidget {
  const AppBarActionButton({super.key, required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  State<AppBarActionButton> createState() => _AppBarActionButtonState();
}

class _AppBarActionButtonState extends State<AppBarActionButton> {
  bool _hovering = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final layout = context.uiLayout;
    final borderRadius = BorderRadius.all(Radius.circular(tokens.controlRadius));

    final enabled = widget.onTap != null;
    final active = enabled && (_hovering || _focused);
    final iconColor = enabled
        ? active
              ? tokens.primary
              : tokens.textSecondary
        : tokens.textSecondary.withValues(alpha: 0.35);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onFocusChange: (value) => setState(() => _focused = value),
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                padding: layout.toolbarButtonPadding,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: active ? tokens.selectedBg : tokens.elevated.withValues(alpha: 0.55),
                  border: Border.all(color: active ? tokens.primary.withValues(alpha: 0.22) : Colors.transparent, width: 0.5),
                ),
                child: Icon(widget.icon, size: 18, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
