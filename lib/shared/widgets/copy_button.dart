import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format_helpers.dart';
import '../../generated/l10n.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// A small icon button that copies [text] to the clipboard and briefly
/// shows a checkmark to confirm the action.
class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.text, this.size = 16}) : _isPayload = false;

  const CopyButton.payload({super.key, required this.text, this.size = 16}) : _isPayload = true;

  final String text;
  final double size;
  final bool _isPayload;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;
  bool _hovering = false;

  void _copy() async {
    final text = widget._isPayload ? formatPayloadForClipboard(widget.text) : widget.text;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = _copied
        ? tokens.success
        : _hovering
        ? tokens.textPrimary
        : tokens.textTertiary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: IconButton(
        onPressed: _copy,
        tooltip: S.maybeOf(context)?.copy ?? 'Copy',
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(4),
        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, key: ValueKey(_copied), size: widget.size, color: color),
        ),
      ),
    );
  }
}
