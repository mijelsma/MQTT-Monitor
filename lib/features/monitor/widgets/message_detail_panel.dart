import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/history/services/message_history_service.dart';
import '../../../core/history/repositories/history_preferences_repository.dart';
import '../../../core/dashboard/repositories/dashboard_preferences_repository.dart';
import '../../../core/dashboard/repositories/dashboard_repository.dart';
import '../../../generated/l10n.dart';
import '../../../core/dashboard/models/graph_card_model.dart';
import '../../../core/monitor/models/topic_tree_node_model.dart';
import '../../../core/monitor/models/topic_node_value_model.dart';
import '../../../shared/format_helpers.dart';
import '../../../shared/widgets/copy_button.dart';
import '../../../shared/widgets/json_highlighter.dart';
import '../../../shared/widgets/qos_tag.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_inline_notice.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../view_models/monitor_view_model.dart';
import '../controllers/monitor_workspace_controller.dart';
import 'comparison_section.dart';

/// Shows the details of the currently selected MQTT message.
///
/// When [selectedHistory] is provided, shows that historical message
/// instead of the latest. Also displays a comparison section when
/// the historical message differs from the latest.
class MessageDetailPanel extends StatelessWidget {
  const MessageDetailPanel({super.key, required this.node, this.selectedHistory, this.onClearSelection});

  final TopicTreeNodeModel node;

  /// A historical value selected from the history panel, or null for latest.
  final TopicNodeValueModel? selectedHistory;

  /// Called when the user wants to return to viewing the latest message.
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TopicNodeValueModel?>(
      valueListenable: node.valueNotifier,
      builder: (context, latestValue, _) {
        final displayValue = selectedHistory ?? latestValue;
        if (displayValue == null) {
          return _EmptyDetail(topic: node.fullPath);
        }
        return _DetailContent(node: node, value: displayValue, latestValue: latestValue, isHistorical: selectedHistory != null, onClearSelection: onClearSelection);
      },
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopicHeader(topic: topic),
            const SizedBox(height: 24),
            UiEmptyState.compact(icon: Icons.hourglass_empty_rounded, title: S.of(context).detailWaitingForMessages),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.node, required this.value, this.latestValue, this.isHistorical = false, this.onClearSelection});

  final TopicTreeNodeModel node;
  final TopicNodeValueModel value;
  final TopicNodeValueModel? latestValue;
  final bool isHistorical;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    // Find the message immediately before the selected one in history.
    TopicNodeValueModel? previousValue;
    if (isHistorical) {
      final history = context.read<MessageHistoryService>().getHistory(node.fullPath);
      final idx = history.indexWhere((v) => v.seq == value.seq);
      if (idx > 0) previousValue = history[idx - 1];
    }
    final showComparison = previousValue != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHistorical) ...[_HistoricalBanner(seq: value.seq, onShowLatest: onClearSelection), const SizedBox(height: 12)],
          _TopicHeader(
            topic: node.fullPath,
            onDelete: isHistorical
                ? null
                : () {
                    context.read<MonitorWorkspaceController>().deleteTopic(node);
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(SnackBar(content: Text(S.of(context).detailTopicDeleted), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
                  },
          ),
          const SizedBox(height: 16),
          _PropertiesCard(
            value: value,
            topic: node.fullPath,
            isHistorical: isHistorical,
            onClearRetained: isHistorical
                ? null
                : () async {
                    final vm = context.read<MonitorViewModel>();
                    final result = await vm.clearRetainedMessage(node.fullPath);
                    if (!context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(SnackBar(content: Text(result.wasSent ? S.of(context).detailRetainedCleared : S.of(context).detailRetainedClearFailed), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
                  },
          ),
          const SizedBox(height: 16),
          _PayloadCard(payload: value.payload, topic: node.fullPath, isHistorical: isHistorical),
          if (showComparison) ...[const SizedBox(height: 16), ComparisonSection(selected: value, previous: previousValue)],
        ],
      ),
    );
  }
}

// ── Topic header ────────────────────────────────────────────────────────

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({required this.topic, this.onDelete});

  final String topic;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.tag_rounded, size: 14, color: tokens.primary.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              topic,
              style: TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 12.5, fontWeight: FontWeight.w600, color: tokens.textPrimary, letterSpacing: -0.2),
            ),
          ),
          const SizedBox(width: 8),
          CopyButton(text: topic, size: 14),
          if (onDelete != null) ...[const SizedBox(width: 4), _DeleteTopicButton(onDelete: onDelete!)],
        ],
      ),
    );
  }
}

// ── Properties card ─────────────────────────────────────────────────────

class _PropertiesCard extends StatelessWidget {
  const _PropertiesCard({required this.value, required this.topic, this.isHistorical = false, this.onClearRetained});

  final TopicNodeValueModel value;
  final String topic;
  final bool isHistorical;
  final VoidCallback? onClearRetained;

  static const _labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  double _measureLabels(List<String> labels) {
    double max = 0;
    for (final text in labels) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: _labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width > max) max = tp.width;
      tp.dispose();
    }
    return max;
  }

  /// Computes a human-readable rate string from the last N messages.
  String? _computeRate(BuildContext context) {
    if (isHistorical) return null;
    final history = context.read<MessageHistoryService>().getHistory(topic);
    if (history.length < 2) return null;

    final sampleSize = context.read<HistoryPreferencesRepository>().rateSampleSize;

    // Take the last N messages (or fewer if not enough yet).
    final count = history.length < sampleSize ? history.length : sampleSize;
    final recent = history.sublist(history.length - count);

    final span = recent.last.receivedAt.difference(recent.first.receivedAt);
    if (span.inMilliseconds <= 0) return null;

    // Average interval = total span / (count - 1) gaps.
    final avgMs = span.inMilliseconds / (recent.length - 1);

    // Sub-second: show "X messages per second" instead.
    if (avgMs < 1000) {
      final perSecond = 1000 / avgMs;
      final label = perSecond >= 10 ? perSecond.round().toString() : perSecond.toStringAsFixed(1);
      return S.of(context).detailRatePerSecond(label);
    }

    final avgDuration = Duration(milliseconds: avgMs.round());
    return S.of(context).detailRateValue(formatDurationHuman(avgDuration, context));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final timeStr = formatTimestamp(value.receivedAt);
    final sizeStr = formatByteSize(value.payload);
    final rateStr = _computeRate(context);

    final labels = [S.of(context).detailQoS, S.of(context).detailRetained, S.of(context).detailReceived, S.of(context).detailSize, S.of(context).detailMessages, if (rateStr != null) S.of(context).detailRate];
    final labelWidth = _measureLabels(labels);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: Column(
        children: [
          _PropertyRow(
            icon: Icons.swap_vert_rounded,
            iconColor: QosTag.colorFor(context, value.qos),
            label: S.of(context).detailQoS,
            labelWidth: labelWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                QosTag(qos: value.qos),
                const SizedBox(width: 6),
                Text(qosLabel(value.qos), style: TextStyle(fontSize: 11, color: tokens.textTertiary)),
              ],
            ),
          ),
          _divider(tokens),
          _PropertyRow(
            icon: Icons.push_pin_rounded,
            iconColor: value.retain ? tokens.warning : tokens.muted,
            label: S.of(context).detailRetained,
            labelWidth: labelWidth,
            child: value.retain
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        S.of(context).detailYes,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.warning),
                      ),
                      if (onClearRetained != null) ...[const SizedBox(width: 8), _ClearRetainedButton(onTap: onClearRetained!)],
                    ],
                  )
                : Text(S.of(context).detailNo, style: TextStyle(fontSize: 12, color: tokens.textTertiary)),
          ),
          _divider(tokens),
          _PropertyRow(
            icon: Icons.schedule_rounded,
            iconColor: tokens.textTertiary,
            label: S.of(context).detailReceived,
            labelWidth: labelWidth,
            child: Text(
              timeStr,
              style: TextStyle(fontSize: 12, color: tokens.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          _divider(tokens),
          _PropertyRow(
            icon: Icons.straighten_rounded,
            iconColor: tokens.textTertiary,
            label: S.of(context).detailSize,
            labelWidth: labelWidth,
            child: Text(sizeStr, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
          ),
          _divider(tokens),
          _PropertyRow(
            icon: Icons.numbers_rounded,
            iconColor: tokens.primary.withValues(alpha: 0.6),
            label: S.of(context).detailMessages,
            labelWidth: labelWidth,
            child: Text(
              '#${value.seq}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.primary, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          if (rateStr != null) ...[
            _divider(tokens),
            _PropertyRow(
              icon: Icons.speed_rounded,
              iconColor: tokens.textTertiary,
              label: S.of(context).detailRate,
              labelWidth: labelWidth,
              child: Text(rateStr, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider(AppTokens tokens) {
    return Divider(height: 0.5, thickness: 0.5, color: tokens.border, indent: 36);
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.icon, required this.iconColor, required this.label, required this.labelWidth, required this.child});

  final IconData icon;
  final Color iconColor;
  final String label;
  final double labelWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 10),
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: tokens.textTertiary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Inline action buttons ───────────────────────────────────────────────

class _DeleteTopicButton extends StatefulWidget {
  const _DeleteTopicButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  State<_DeleteTopicButton> createState() => _DeleteTopicButtonState();
}

class _DeleteTopicButtonState extends State<_DeleteTopicButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Tooltip(
      message: S.of(context).detailDeleteTopic,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onDelete,
          behavior: HitTestBehavior.opaque,
          child: Icon(Icons.delete_outline_rounded, size: 14, color: _hovering ? tokens.error : tokens.textTertiary),
        ),
      ),
    );
  }
}

class _ClearRetainedButton extends StatefulWidget {
  const _ClearRetainedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ClearRetainedButton> createState() => _ClearRetainedButtonState();
}

class _ClearRetainedButtonState extends State<_ClearRetainedButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Tooltip(
      message: S.of(context).detailClearRetained,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _hovering ? tokens.warning.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tokens.warning.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded, size: 11, color: tokens.warning),
                const SizedBox(width: 3),
                Text(
                  S.of(context).detailClearRetained,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: tokens.warning),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Payload card ────────────────────────────────────────────────────────

class _PayloadCard extends StatefulWidget {
  const _PayloadCard({required this.payload, required this.topic, this.isHistorical = false});

  final String payload;
  final String topic;
  final bool isHistorical;

  @override
  State<_PayloadCard> createState() => _PayloadCardState();
}

class _PayloadCardState extends State<_PayloadCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isJson = JsonHighlighter.isJson(widget.payload);
    final showPin = !widget.isHistorical;
    // Try this before classifying the payload as JSON: a bare number (or a
    // JSON string containing one) is valid JSON too and should be pinnable.
    final numericParts = showPin ? parseNumericPayload(widget.payload) : null;
    final isNumeric = numericParts != null;
    final formatLabel = isJson ? 'JSON' : 'TEXT';
    final formatColor = isJson ? tokens.success : tokens.textTertiary;

    // Build the main payload content widget.
    Widget content;
    if (isNumeric) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _PinnableValue(payload: widget.payload, topic: widget.topic, unit: numericParts.$2),
      );
    } else if (isJson && showPin) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: JsonHighlighter(source: widget.payload, selectable: false, onPin: (keyPath, label) => _onPin(context, widget.topic, keyPath, label)),
      );
    } else {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: JsonHighlighter(source: widget.payload, selectable: false),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.expand_more_rounded, size: 16, color: tokens.textTertiary),
                ),
                const SizedBox(width: 4),
                Icon(Icons.code_rounded, size: 13, color: tokens.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'PAYLOAD',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: tokens.textTertiary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: formatColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    formatLabel,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: formatColor, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.isHistorical ? tokens.warning.withValues(alpha: 0.6) : tokens.border, width: widget.isHistorical ? 1.5 : 0.5),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: SelectionArea(key: const Key('payload-selection-area'), child: content),
                ),
                Positioned(top: 0, right: 0, child: CopyButton.payload(text: widget.payload, size: 14)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Small inline widget for a bare numeric payload with a pin icon.
class _PinnableValue extends StatefulWidget {
  const _PinnableValue({required this.payload, required this.topic, this.unit});

  final String payload;
  final String topic;
  final String? unit;

  @override
  State<_PinnableValue> createState() => _PinnableValueState();
}

class _PinnableValueState extends State<_PinnableValue> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = _hovering ? tokens.primary : tokens.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () => _onPin(context, widget.topic, null, null, unit: widget.unit),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.push_pin_rounded, size: 12, color: color),
            ),
          ),
        ),
        JsonHighlighter(source: widget.payload, selectable: false),
      ],
    );
  }
}

/// Tries to split a payload like "13.58 dB" into (value, unit).
/// Returns null if no leading number is found.
(double, String?)? parseNumericPayload(String raw) {
  final trimmed = raw.trim();
  // Fast path: pure number.
  final plain = double.tryParse(trimmed);
  if (plain != null) return (plain, null);

  // A standalone JSON string such as `"13.58"` is also a numeric payload.
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is String && decoded != trimmed) {
      return parseNumericPayload(decoded);
    }
  } catch (_) {
    // Not JSON; continue with the regular text-with-unit handling below.
  }

  // Match a leading number (with optional sign/decimal) followed by a unit (space optional).
  final match = RegExp(r'^([+-]?\d+\.?\d*)\s*([a-zA-Z°/%].*)$').firstMatch(trimmed);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!);
  if (value == null) return null;
  return (value, match.group(2)!.trim());
}

/// Directly pins a value to the dashboard without a dialog.
void _onPin(BuildContext context, String topic, String? keyPath, String? defaultName, {String? unit}) async {
  final vm = context.read<MonitorViewModel>();
  final brokerId = vm.activeBroker?.id;
  if (brokerId == null) return;

  final preferences = context.read<DashboardPreferencesRepository>();
  final dashboard = context.read<DashboardRepository>();
  final cards = dashboard.cardsForBroker(brokerId);

  final colorValue = preferences.cardColor;
  final dotSize = preferences.dotSize;
  final chartType = preferences.chartType;
  final interpolation = preferences.interpolation;
  final maxSamples = preferences.maximumSamples;

  final id = '${DateTime.now().millisecondsSinceEpoch}_${cards.length}';
  await dashboard.addCard(brokerId, GraphCardModel(id: id, topic: topic, jsonKeyPath: keyPath, displayName: defaultName ?? keyPath ?? topic.split('/').last, unit: unit, colorValue: colorValue, chartType: chartType, interpolation: interpolation, dotSize: dotSize, maxDataPoints: maxSamples, position: cards.length));

  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(content: Text(S.of(context).detailPinnedToDashboard), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
}

// ── Historical banner ───────────────────────────────────────────────────

class _HistoricalBanner extends StatelessWidget {
  const _HistoricalBanner({required this.seq, this.onShowLatest});

  final int seq;
  final VoidCallback? onShowLatest;

  @override
  Widget build(BuildContext context) {
    return UiInlineNotice(kind: UiNoticeKind.warning, title: S.of(context).detailViewingMessage(seq), actionLabel: onShowLatest == null ? null : S.of(context).detailShowLatest, onAction: onShowLatest, radius: 10);
  }
}
