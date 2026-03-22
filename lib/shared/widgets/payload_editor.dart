import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'json_highlighter.dart';

/// Payload format for the editor (plain text or JSON).
enum PayloadFormat { text, json }

/// A [TextEditingController] with optional JSON syntax highlighting.
///
/// Toggle [highlightJson] to enable/disable colouring and call
/// [updateTheme] once per build so the controller knows the current palette.
class HighlightingController extends TextEditingController {
  HighlightingController({super.text});

  bool highlightJson = false;

  AppTokens? _tokens;
  bool _isDark = false;

  /// Feed the current theme into the controller so [buildTextSpan] can
  /// apply the right colours.
  void updateTheme(AppTokens tokens, bool isDark) {
    _tokens = tokens;
    _isDark = isDark;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (!highlightJson || _tokens == null || text.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final spans = JsonHighlighter.highlight(text, _isDark, _tokens!);
    return TextSpan(style: style, children: spans);
  }
}

/// A reusable payload editor with TEXT / JSON format toggle, syntax
/// highlighting, line numbers, and a prettify button.
///
/// Used by both the publish panel and the shortcut settings dialog.
class PayloadEditor extends StatefulWidget {
  const PayloadEditor({super.key, required this.controller, required this.format, required this.onFormatChanged, this.validationError});

  final HighlightingController controller;
  final PayloadFormat format;
  final ValueChanged<PayloadFormat> onFormatChanged;
  final String? validationError;

  @override
  State<PayloadEditor> createState() => _PayloadEditorState();
}

class _PayloadEditorState extends State<PayloadEditor> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateLineCount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLineCount);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateLineCount() {
    final count = '\n'.allMatches(widget.controller.text).length + 1;
    if (count != _lineCount) setState(() => _lineCount = count);
  }

  /// Inserts two spaces at the current cursor position (Tab key).
  void _insertTab() {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    const tab = '  ';
    final newText = text.replaceRange(sel.start, sel.end, tab);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + tab.length),
    );
  }

  /// Pretty-prints the current payload as indented JSON.
  void _prettify() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    try {
      final obj = jsonDecode(text);
      final pretty = const JsonEncoder.withIndent('  ').convert(obj);
      widget.controller.text = pretty;
      widget.controller.selection = TextSelection.collapsed(offset: pretty.length);
    } catch (_) {
      // Invalid JSON — do nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    widget.controller.updateTheme(tokens, Theme.of(context).brightness == Brightness.dark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: label + format picker + validation error
        _PayloadHeader(format: widget.format, onFormatChanged: widget.onFormatChanged, validationError: widget.validationError),
        const SizedBox(height: 6),
        // Input area
        Expanded(child: _buildInput(tokens)),
      ],
    );
  }

  Widget _buildInput(AppTokens tokens) {
    const textStyle = TextStyle(fontSize: 12.5, fontFamily: 'SF Mono, Menlo, monospace', letterSpacing: -0.2, height: 1.45);

    return Container(
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line numbers gutter
              _LineNumberGutter(lineCount: _lineCount, textStyle: textStyle),
              // Editor
              Expanded(
                child: Focus(
                  focusNode: _focusNode,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
                      _insertTab();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: widget.controller,
                    scrollController: _scrollController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: textStyle.copyWith(color: tokens.textPrimary),
                    decoration: InputDecoration(
                      hintText: widget.format == PayloadFormat.json ? '{"key": "value"}' : 'Hello world',
                      hintStyle: TextStyle(fontSize: 12, color: tokens.muted),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Prettify button — top-right, only for JSON
          if (widget.format == PayloadFormat.json) Positioned(top: 6, right: 6, child: _PrettifyButton(onPressed: _prettify)),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _PayloadHeader extends StatelessWidget {
  const _PayloadHeader({required this.format, required this.onFormatChanged, this.validationError});

  final PayloadFormat format;
  final ValueChanged<PayloadFormat> onFormatChanged;
  final String? validationError;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.code_rounded, size: 12, color: tokens.textTertiary),
            const SizedBox(width: 5),
            Text(
              'PAYLOAD',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: tokens.textTertiary),
            ),
            const Spacer(),
            _FormatPicker(format: format, onChanged: onFormatChanged),
          ],
        ),
        if (validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 11, color: AppColors.error400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    validationError!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: AppColors.error400),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Format picker (TEXT / JSON) ─────────────────────────────────────────────

class _FormatPicker extends StatelessWidget {
  const _FormatPicker({required this.format, required this.onChanged});

  final PayloadFormat format;
  final ValueChanged<PayloadFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [_chip(context, PayloadFormat.text, 'TEXT', tokens), _chip(context, PayloadFormat.json, 'JSON', tokens)]),
    );
  }

  Widget _chip(BuildContext context, PayloadFormat value, String label, AppTokens tokens) {
    final selected = format == value;
    final isJson = value == PayloadFormat.json;
    final chipColor = selected ? (isJson ? AppColors.success500 : tokens.textSecondary) : tokens.muted;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: selected ? chipColor.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
        child: Text(
          label,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: chipColor),
        ),
      ),
    );
  }
}

// ─── Line number gutter ──────────────────────────────────────────────────────

class _LineNumberGutter extends StatelessWidget {
  const _LineNumberGutter({required this.lineCount, required this.textStyle});

  final int lineCount;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final digits = lineCount.toString().length;
    final gutterWidth = 12.0 + digits * 8.0;

    return Container(
      width: gutterWidth,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(right: BorderSide(color: tokens.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(lineCount, (i) {
          return SizedBox(
            height: textStyle.fontSize! * (textStyle.height ?? 1.45),
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${i + 1}',
                style: textStyle.copyWith(color: tokens.muted, fontSize: 11),
                textAlign: TextAlign.right,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Prettify button ─────────────────────────────────────────────────────────

class _PrettifyButton extends StatefulWidget {
  const _PrettifyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PrettifyButton> createState() => _PrettifyButtonState();
}

class _PrettifyButtonState extends State<_PrettifyButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Tooltip(
          message: S.of(context).publishPrettifyJson,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _hovering ? tokens.primary.withValues(alpha: 0.10) : tokens.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: tokens.border, width: 0.5),
            ),
            child: Icon(Icons.auto_fix_high_rounded, size: 13, color: _hovering ? tokens.primary : tokens.textTertiary),
          ),
        ),
      ),
    );
  }
}
