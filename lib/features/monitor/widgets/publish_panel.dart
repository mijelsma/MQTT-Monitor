import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/json_highlighter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../monitor_viewmodel.dart';

/// Payload format for publish validation.
enum PayloadFormat { text, json }

/// A panel for publishing MQTT messages to a topic.
class PublishPanel extends StatefulWidget {
  const PublishPanel({super.key});

  @override
  State<PublishPanel> createState() => _PublishPanelState();
}

class _PublishPanelState extends State<PublishPanel> {
  final _topicController = TextEditingController();
  final _payloadController = _HighlightingController();
  int _qos = 0;
  bool _retain = false;
  PayloadFormat _format = PayloadFormat.text;
  _PublishFeedback? _feedback;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _payloadController.addListener(_onPayloadChanged);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  // Called whenever the payload text changes, to update validation state.
  void _onPayloadChanged() {
    if (_format == PayloadFormat.json) {
      final error = _validateJson(_payloadController.text);
      if (error != _validationError) setState(() => _validationError = error);
    } else if (_validationError != null) {
      setState(() => _validationError = null);
    }
  }

  // Validates the JSON payload and returns an error message if invalid, or `null` if valid.
  String? _validateJson(String text) {
    if (text.trim().isEmpty) return null;
    try {
      jsonDecode(text);
      return null;
    } on FormatException catch (e) {
      final offset = e.offset;
      if (offset != null && offset <= text.length) {
        // Count line and column from the offset.
        final prefix = text.substring(0, offset);
        final line = '\n'.allMatches(prefix).length + 1;
        final lastNl = prefix.lastIndexOf('\n');
        final col = lastNl == -1 ? offset + 1 : offset - lastNl;
        return 'Ln $line, Col $col — ${e.message}';
      }
      return e.message;
    }
  }

  // Handles the Publish button tap: validates input and attempts to publish via the ViewModel.
  void _publish() {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      _showFeedback(_PublishFeedback.emptyTopic);
      return;
    }

    if (_format == PayloadFormat.json && _validationError != null) {
      _showFeedback(_PublishFeedback.invalidJson);
      return;
    }

    final vm = context.read<MonitorViewModel>();
    if (!vm.isConnected) {
      _showFeedback(_PublishFeedback.notConnected);
      return;
    }

    final sent = vm.publish(topic, _payloadController.text, qos: _qos, retain: _retain);
    _showFeedback(sent ? _PublishFeedback.success : _PublishFeedback.failed);
  }

  // Shows a temporary feedback badge at the Publish button, indicating success or failure.
  void _showFeedback(_PublishFeedback fb) {
    setState(() => _feedback = fb);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _feedback = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<MonitorViewModel>();
    final connected = vm.isConnected;

    // Feed current theme into the highlighting controller.
    _payloadController.updateTheme(tokens, Theme.of(context).brightness == Brightness.dark);

    return Container(
      color: tokens.bg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Topic field ──────────────────────────────────────────────
          _TopicInput(controller: _topicController),
          const SizedBox(height: 8),

          // ── Payload header + format selector ────────────────────────
          _PayloadHeader(
            format: _format,
            onFormatChanged: (f) {
              setState(() => _format = f);
              _payloadController.highlightJson = f == PayloadFormat.json;
              _onPayloadChanged();
            },
            validationError: _validationError,
          ),
          const SizedBox(height: 6),

          // ── Payload field — expands to fill remaining space ─────────
          Expanded(
            child: _PayloadInput(controller: _payloadController, format: _format),
          ),
          const SizedBox(height: 8),

          // ── Options bar: QoS · Retain · Publish ─────────────────────
          _OptionsBar(qos: _qos, retain: _retain, connected: connected, feedback: _feedback, onQosChanged: (v) => setState(() => _qos = v), onRetainChanged: (v) => setState(() => _retain = v), onPublish: _publish),
        ],
      ),
    );
  }
}

// Topic input field
class _TopicInput extends StatelessWidget {
  const _TopicInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 12.5, color: tokens.textPrimary, fontFamily: 'SF Mono, Menlo, monospace', letterSpacing: -0.2),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 6),
          child: Icon(Icons.tag_rounded, size: 14, color: tokens.muted),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: 'Topic  e.g. home/temp',
        hintStyle: TextStyle(fontSize: 12, color: tokens.muted, fontFamily: null),
        filled: true,
        fillColor: tokens.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.primary, width: 1),
        ),
        isDense: true,
      ),
    );
  }
}

// Payload header with a label, format selector, and validation error message (if applicable).
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

// Format Selector (TEXT / JSON) with validation state feedback
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [_formatChip(context, PayloadFormat.text, 'TEXT', tokens), _formatChip(context, PayloadFormat.json, 'JSON', tokens)]),
    );
  }

  Widget _formatChip(BuildContext context, PayloadFormat value, String label, AppTokens tokens) {
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

// Payload TextField with JSON syntax highlighting. Uses a custom controller to manage the highlighted text.
class _PayloadInput extends StatefulWidget {
  const _PayloadInput({required this.controller, required this.format});

  final TextEditingController controller;
  final PayloadFormat format;

  @override
  State<_PayloadInput> createState() => _PayloadInputState();
}

// A custom TextEditingController that notifies listeners when the text changes, so we can update JSON highlighting in real-time.
class _PayloadInputState extends State<_PayloadInput> {
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
      // Move cursor to end.
      widget.controller.selection = TextSelection.collapsed(offset: pretty.length);
    } catch (_) {
      // Invalid JSON — do nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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
          // Prettify button — top-right corner, only shown for JSON format.
          if (widget.format == PayloadFormat.json) Positioned(top: 6, right: 6, child: _PrettifyButton(onPressed: _prettify)),
        ],
      ),
    );
  }
}

/// Gutter showing line numbers alongside the payload editor.
class _LineNumberGutter extends StatelessWidget {
  const _LineNumberGutter({required this.lineCount, required this.textStyle});

  final int lineCount;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final digits = lineCount.toString().length;
    // Minimum width: enough for the widest number + padding.
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

// Pretty-prints the JSON payload when the user taps the prettify button. Only shown when JSON format is selected.
class _PrettifyButton extends StatefulWidget {
  const _PrettifyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PrettifyButton> createState() => _PrettifyButtonState();
}

// Prettify tooltip button with hover effects. Calls the prettify function in the payload input when tapped.
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
          message: 'Prettify JSON',
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

// Publish feedback badge shown temporarily after publishing, indicating success or failure of the publish action.
enum _PublishFeedback { success, failed, notConnected, emptyTopic, invalidJson }

// Publish options bar containing QoS selector, Retain toggle, and Publish button, along with any feedback badge.
class _OptionsBar extends StatelessWidget {
  const _OptionsBar({required this.qos, required this.retain, required this.connected, required this.feedback, required this.onQosChanged, required this.onRetainChanged, required this.onPublish});

  final int qos;
  final bool retain;
  final bool connected;
  final _PublishFeedback? feedback;
  final ValueChanged<int> onQosChanged;
  final ValueChanged<bool> onRetainChanged;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // QoS chips
        _MiniQosSelector(value: qos, onChanged: onQosChanged),
        const SizedBox(width: 6),

        // Retain pill
        _RetainPill(value: retain, onChanged: onRetainChanged),
        const SizedBox(width: 8),

        // Feedback badge (overlays between options and button)
        if (feedback != null) ...[_FeedbackBadge(feedback: feedback!), const SizedBox(width: 8)],

        const Spacer(),

        // Publish button
        _PublishChip(connected: connected, onPressed: onPublish),
      ],
    );
  }
}

// A compact QoS selector showing the three QoS levels as selectable chips. Uses a single accent color, matching the subscription modal style.
class _MiniQosSelector extends StatelessWidget {
  const _MiniQosSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = tokens.primary;
    return Container(
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final selected = value == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: selected ? accent : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  'Q$i',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: selected ? tokens.onPrimary : tokens.textSecondary),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// A toggle pill for the Retain flag. Shows an icon and label, and highlights when enabled. Calls back when toggled.
class _RetainPill extends StatelessWidget {
  const _RetainPill({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = value ? AppColors.warning500 : tokens.muted;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: value ? AppColors.warning500.withValues(alpha: 0.10) : tokens.inputFill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: value ? AppColors.warning500.withValues(alpha: 0.4) : tokens.border, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.push_pin_rounded, size: 11, color: color),
              const SizedBox(width: 4),
              Text(
                'Retain',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A badge showing feedback after a publish action. Displays an icon and text based on the feedback type.
class _FeedbackBadge extends StatelessWidget {
  const _FeedbackBadge({required this.feedback});

  final _PublishFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (feedback) {
      _PublishFeedback.success => (Icons.check_circle_rounded, AppColors.success500, 'Sent'),
      _PublishFeedback.failed => (Icons.error_rounded, AppColors.error500, 'Failed'),
      _PublishFeedback.notConnected => (Icons.cloud_off_rounded, AppColors.warning500, 'Offline'),
      _PublishFeedback.emptyTopic => (Icons.warning_rounded, AppColors.warning500, 'No topic'),
      _PublishFeedback.invalidJson => (Icons.warning_rounded, AppColors.error400, 'Bad JSON'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

// A compact Publish button with an icon. Highlights when hovered and disabled when not connected.
class _PublishChip extends StatefulWidget {
  const _PublishChip({required this.connected, required this.onPressed});

  final bool connected;
  final VoidCallback onPressed;

  @override
  State<_PublishChip> createState() => _PublishChipState();
}

// A compact Publish button with an icon. Highlights when hovered and disabled when not connected.
class _PublishChipState extends State<_PublishChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = widget.connected ? tokens.primary : tokens.muted.withValues(alpha: 0.3);
    final fg = widget.connected ? tokens.onPrimary : tokens.textTertiary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: _hovering ? bg.withValues(alpha: 0.85) : bg, borderRadius: BorderRadius.circular(7)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.send_rounded, size: 13, color: fg),
              const SizedBox(width: 6),
              Text(
                'Publish',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A [TextEditingController] that applies JSON syntax highlighting when
/// [highlightJson] is `true`. It reuses the colouring logic from
/// [JsonHighlighter] so the palette matches the read-only detail panel.
class _HighlightingController extends TextEditingController {
  bool highlightJson = false;

  /// Cache: we store the context's tokens/brightness so [buildTextSpan] can
  /// use them (it has no BuildContext parameter).
  AppTokens? _tokens;
  bool _isDark = false;

  /// Call this once per build to feed the current theme into the controller.
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
