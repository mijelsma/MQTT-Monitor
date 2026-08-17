import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/mqtt/publish_result.dart';
import '../../../core/publishing/publish_command.dart';
import '../../../core/publishing/publish_command_result.dart';
import '../../../generated/l10n.dart';
import '../../../shared/widgets/feedback_badge.dart';
import '../../../shared/widgets/ui_compact_segment.dart';
import '../../../shared/widgets/payload_editor.dart';
import '../../../theme/accent_contrast.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../view_models/monitor_view_model.dart';
import '../publish_command_feedback.dart';
import '../controllers/publish_draft_controller.dart';

/// A panel for publishing MQTT messages to a topic.
class PublishPanel extends StatefulWidget {
  const PublishPanel({super.key});

  @override
  State<PublishPanel> createState() => _PublishPanelState();
}

class _PublishPanelState extends State<PublishPanel> with FeedbackMixin<PublishPanel> {
  // Handles the Publish button tap: validates input and attempts to publish via the ViewModel.
  Future<void> _publish() async {
    final draft = context.read<PublishDraftController>();
    final vm = context.read<MonitorViewModel>();
    final result = await vm.execute(
      PublishCommand(topicTemplate: draft.topicController.text, payload: draft.payloadController.text, payloadIsJson: draft.format == PayloadFormat.json, qos: draft.qos, retain: draft.retain),
      onDispatch: () => showFeedback(PublishFeedbackKind.sending, autoDismiss: const Duration(minutes: 1)),
    );
    if (!mounted) return;
    _applyCommandResult(result);
  }

  void _applyCommandResult(PublishCommandResult result) {
    final transport = result.transportResult;
    if (transport != null) {
      _applyResult(transport);
      return;
    }
    final feedback = feedbackForCommandFailure(context, result.failure!, result.detail);
    showFeedback(feedback.kind, detail: feedback.detail);
  }

  void _applyResult(PublishResult result) {
    final info = feedbackForResult(context, result);
    showFeedback(info.kind, detail: info.detail, autoDismiss: result.isUnconfirmed ? const Duration(minutes: 1) : const Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<MonitorViewModel>();
    final draft = context.watch<PublishDraftController>();
    final connected = vm.isConnected;

    return Container(
      color: tokens.bg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Topic field ──────────────────────────────────────────────
          _TopicInput(controller: draft.topicController),
          const SizedBox(height: 8),

          // ── Payload editor (shared widget) ──────────────────────────
          Expanded(
            child: PayloadEditor(controller: draft.payloadController, format: draft.format, onFormatChanged: draft.setFormat, validationError: draft.validationError),
          ),
          const SizedBox(height: 8),

          // ── Options bar: QoS · Retain · Publish ─────────────────────
          _OptionsBar(qos: draft.qos, retain: draft.retain, connected: connected, feedback: feedback, feedbackDetail: feedbackDetail, onQosChanged: draft.setQos, onRetainChanged: draft.setRetain, onPublish: _publish),
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
      key: const Key('publish-topic-field'),
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

// Publish options bar containing QoS selector, Retain toggle, and Publish button, along with any feedback badge.
class _OptionsBar extends StatelessWidget {
  const _OptionsBar({required this.qos, required this.retain, required this.connected, required this.feedback, required this.feedbackDetail, required this.onQosChanged, required this.onRetainChanged, required this.onPublish});

  final int qos;
  final bool retain;
  final bool connected;
  final PublishFeedbackKind? feedback;
  final String? feedbackDetail;
  final ValueChanged<int> onQosChanged;
  final ValueChanged<bool> onRetainChanged;
  final Future<void> Function() onPublish;

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
        if (feedback != null) ...[Flexible(child: _buildFeedbackBadge(context)), const SizedBox(width: 8)],

        const Spacer(),

        // Publish button
        _PublishChip(connected: connected, onPressed: onPublish),
      ],
    );
  }

  Widget _buildFeedbackBadge(BuildContext context) {
    final s = S.of(context);
    final label = switch (feedback!) {
      PublishFeedbackKind.sending => s.publishSending,
      PublishFeedbackKind.delivered => s.publishDelivered,
      PublishFeedbackKind.acknowledged => s.publishAcknowledged,
      PublishFeedbackKind.failed => s.publishFailed,
      PublishFeedbackKind.timedOut => s.publishTimedOut,
      PublishFeedbackKind.offline => s.publishOffline,
      PublishFeedbackKind.emptyTopic => s.publishNoTopic,
      PublishFeedbackKind.invalidJson => s.publishBadJson,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: FeedbackBadge(kind: feedback!, label: label, detail: feedbackDetail),
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
    return UiCompactSegment<int>(
      value: value,
      onChanged: onChanged,
      optionKey: (value) => Key('publish-qos-$value'),
      options: const [
        UiCompactSegmentOption(value: 0, label: 'Q0'),
        UiCompactSegmentOption(value: 1, label: 'Q1'),
        UiCompactSegmentOption(value: 2, label: 'Q2'),
      ],
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
    final color = value ? tokens.warning : tokens.muted;
    return GestureDetector(
      key: const Key('publish-retain-toggle'),
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: value ? tokens.warning.withValues(alpha: 0.10) : tokens.inputFill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: value ? tokens.warning.withValues(alpha: 0.4) : tokens.border, width: 0.5),
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

// A compact Publish button with an icon. Highlights when hovered and disabled when not connected.
class _PublishChip extends StatefulWidget {
  const _PublishChip({required this.connected, required this.onPressed});

  final bool connected;
  final Future<void> Function() onPressed;

  @override
  State<_PublishChip> createState() => _PublishChipState();
}

// A compact Publish button with an icon. Highlights when hovered and disabled when not connected.
class _PublishChipState extends State<_PublishChip> {
  bool _hovering = false;
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = widget.connected && !_busy;
    final bg = enabled ? accentFillForWhiteForeground(tokens.primary) : tokens.muted.withValues(alpha: 0.3);
    final fg = enabled ? tokens.onPrimary : tokens.textTertiary;
    final hoverBg = enabled ? Color.lerp(bg, Colors.black, 0.08)! : bg;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: enabled && _hovering ? hoverBg : bg, borderRadius: BorderRadius.circular(7)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy) SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, valueColor: AlwaysStoppedAnimation<Color>(fg))) else Icon(Icons.send_rounded, size: 13, color: fg),
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
