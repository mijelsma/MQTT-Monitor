import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format_helpers.dart';
import '../../generated/l10n.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// A small icon button that copies [text] to the clipboard and briefly
/// shows a checkmark to confirm the action.
class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.text, this.size = 16}) : _textProvider = null, _isPayload = false, maxInlineArrayItems = 1;

  const CopyButton.payload({super.key, required this.text, this.size = 16, this.maxInlineArrayItems = 1}) : _textProvider = null, _isPayload = true;

  /// Defers expensive text construction until the button is pressed.
  const CopyButton.lazy({super.key, required String Function() textProvider, this.size = 16}) : text = '', _textProvider = textProvider, _isPayload = false, maxInlineArrayItems = 1;

  final String text;
  final String Function()? _textProvider;
  final double size;
  final bool _isPayload;
  final int maxInlineArrayItems;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;
  bool _hovering = false;

  void _copy() async {
    final source = widget._textProvider?.call() ?? widget.text;
    final text = widget._isPayload ? formatPayloadForClipboard(source, maxInlineArrayItems: widget.maxInlineArrayItems) : source;
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
