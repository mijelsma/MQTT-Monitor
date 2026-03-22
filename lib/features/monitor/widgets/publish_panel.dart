import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../shared/widgets/payload_editor.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../monitor_viewmodel.dart';

/// A panel for publishing MQTT messages to a topic.
class PublishPanel extends StatefulWidget {
  const PublishPanel({super.key});

  @override
  State<PublishPanel> createState() => _PublishPanelState();
}

class _PublishPanelState extends State<PublishPanel> {
  final _topicController = TextEditingController();
  final _payloadController = HighlightingController();
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

    return Container(
      color: tokens.bg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Topic field ──────────────────────────────────────────────
          _TopicInput(controller: _topicController),
          const SizedBox(height: 8),

          // ── Payload editor (shared widget) ──────────────────────────
          Expanded(
            child: PayloadEditor(
              controller: _payloadController,
              format: _format,
              onFormatChanged: (f) {
                setState(() => _format = f);
                _payloadController.highlightJson = f == PayloadFormat.json;
                _onPayloadChanged();
              },
              validationError: _validationError,
            ),
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
        hintText: S.of(context).publishTopicHint,
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
                S.of(context).publishRetain,
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
      _PublishFeedback.success => (Icons.check_circle_rounded, AppColors.success500, S.of(context).publishSent),
      _PublishFeedback.failed => (Icons.error_rounded, AppColors.error500, S.of(context).publishFailed),
      _PublishFeedback.notConnected => (Icons.cloud_off_rounded, AppColors.warning500, S.of(context).publishOffline),
      _PublishFeedback.emptyTopic => (Icons.warning_rounded, AppColors.warning500, S.of(context).publishNoTopic),
      _PublishFeedback.invalidJson => (Icons.warning_rounded, AppColors.error400, S.of(context).publishBadJson),
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
