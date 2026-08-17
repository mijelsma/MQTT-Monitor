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
import '../../../core/ui/repositories/ui_preferences_repository.dart';
import '../../../shared/format_helpers.dart';
import '../../../shared/widgets/copy_button.dart';
import '../../../shared/widgets/json_highlighter.dart';
import '../../../shared/widgets/qos_tag.dart';
import '../../../shared/widgets/ui_compact_segment.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_inline_notice.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../view_models/monitor_view_model.dart';
import '../controllers/detail_sidebar_controller.dart';
import '../controllers/monitor_workspace_controller.dart';
import 'comparison_section.dart';

/// Shows the details of the currently selected MQTT message.
///
/// When [selectedHistory] is provided, shows that historical message
/// instead of the latest. Also displays a comparison section when
/// the historical message differs from the latest.
class MessageDetailPanel extends StatelessWidget {
  const MessageDetailPanel({super.key, required this.node, this.selectedHistory, this.payloadViewMode, this.onPayloadViewModeChanged, this.onClearSelection});

  final TopicTreeNodeModel node;

  /// A historical value selected from the history panel, or null for latest.
  final TopicNodeValueModel? selectedHistory;

  /// Optional controlled mode used by the session-owned detail sidebar.
  final PayloadViewMode? payloadViewMode;
  final ValueChanged<PayloadViewMode>? onPayloadViewModeChanged;

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
        return _DetailContent(node: node, value: displayValue, latestValue: latestValue, isHistorical: selectedHistory != null, payloadViewMode: payloadViewMode, onPayloadViewModeChanged: onPayloadViewModeChanged, onClearSelection: onClearSelection);
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
  const _DetailContent({required this.node, required this.value, this.latestValue, this.isHistorical = false, this.payloadViewMode, this.onPayloadViewModeChanged, this.onClearSelection});

  final TopicTreeNodeModel node;
  final TopicNodeValueModel value;
  final TopicNodeValueModel? latestValue;
  final bool isHistorical;
  final PayloadViewMode? payloadViewMode;
  final ValueChanged<PayloadViewMode>? onPayloadViewModeChanged;
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
          _PayloadCard(payload: value.payload, payloadBytes: value.payloadBytes, topic: node.fullPath, viewMode: payloadViewMode, onViewModeChanged: onPayloadViewModeChanged, isHistorical: isHistorical),
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
                Flexible(
                  child: Text(
                    qosLabel(value.qos),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: tokens.textTertiary),
                  ),
                ),
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
  const _PayloadCard({required this.payload, required this.topic, this.payloadBytes, this.viewMode, this.onViewModeChanged, this.isHistorical = false});

  final String payload;
  final List<int>? payloadBytes;
  final String topic;
  final PayloadViewMode? viewMode;
  final ValueChanged<PayloadViewMode>? onViewModeChanged;
  final bool isHistorical;

  @override
  State<_PayloadCard> createState() => _PayloadCardState();
}

class _PayloadCardState extends State<_PayloadCard> {
  bool _expanded = true;
  PayloadViewMode _localViewMode = PayloadViewMode.text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final viewMode = widget.viewMode ?? _localViewMode;
    final maxInlineArrayItems = context.watch<UiPreferencesRepository>().jsonInlineArrayMaxItems;
    final isJson = JsonHighlighter.isJson(widget.payload);
    final showPin = !widget.isHistorical;
    final brokerId = showPin ? context.watch<MonitorViewModel>().activeBroker?.id : null;
    final dashboard = showPin ? context.watch<DashboardRepository>() : null;
    final pinnedCards = brokerId != null && dashboard != null ? dashboard.cardsForBroker(brokerId).where((card) => card.topic == widget.topic).toList(growable: false) : const <GraphCardModel>[];
    final pinnedKeyPaths = pinnedCards.map((card) => card.jsonKeyPath).whereType<String>().toSet();
    final isRootValuePinned = pinnedCards.any((card) => card.jsonKeyPath == null);
    // Try this before classifying the payload as JSON: a bare number (or a
    // JSON string containing one) is valid JSON too and should be pinnable.
    final numericParts = showPin ? parseNumericPayload(widget.payload) : null;
    final isNumeric = numericParts != null;

    // Build the decoded-text payload content widget.
    Widget content;
    if (isNumeric) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _PinnableValue(payload: widget.payload, topic: widget.topic, unit: numericParts.$2, isPinned: isRootValuePinned),
      );
    } else if (isJson && showPin) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: JsonHighlighter(source: widget.payload, selectable: false, maxInlineArrayItems: maxInlineArrayItems, pinnedKeyPaths: pinnedKeyPaths, onPin: (keyPath, label) => _onPin(context, widget.topic, keyPath, label)),
      );
    } else {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: JsonHighlighter(source: widget.payload, selectable: false, maxInlineArrayItems: maxInlineArrayItems),
      );
    }

    final payloadBytes = widget.payloadBytes ?? utf8.encode(widget.payload);

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
                const Spacer(),
                UiCompactSegment<PayloadViewMode>(
                  value: viewMode,
                  onChanged: (value) {
                    if (widget.onViewModeChanged != null) {
                      widget.onViewModeChanged!(value);
                    } else {
                      setState(() => _localViewMode = value);
                    }
                  },
                  options: const [
                    UiCompactSegmentOption(value: PayloadViewMode.text, label: 'TEXT', semanticsLabel: 'Text payload view'),
                    UiCompactSegmentOption(value: PayloadViewMode.bytes, label: 'BYTES', semanticsLabel: 'Bytes payload view'),
                  ],
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
              color: tokens.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.isHistorical ? tokens.warning.withValues(alpha: 0.6) : tokens.border, width: widget.isHistorical ? 1.5 : 0.5),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: SelectionArea(
                    key: const Key('payload-selection-area'),
                    child: viewMode == PayloadViewMode.text ? content : _BytePayloadView(bytes: payloadBytes),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: viewMode == PayloadViewMode.text ? CopyButton.payload(text: widget.payload, size: 14, maxInlineArrayItems: maxInlineArrayItems) : CopyButton(text: formatPayloadBytesForClipboard(payloadBytes), size: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Formats raw payload bytes for copying without offsets, ASCII, or line breaks.
String formatPayloadBytesForClipboard(Iterable<int> bytes) => bytes.map((byte) => (byte & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

/// A classic hex dump: offset, hexadecimal bytes, and printable ASCII.
class _BytePayloadView extends StatelessWidget {
  const _BytePayloadView({required this.bytes});

  final List<int> bytes;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final rows = <Widget>[];
    for (var offset = 0; offset < bytes.length; offset += 16) {
      final chunk = bytes.sublist(offset, (offset + 16).clamp(0, bytes.length));
      rows.add(_BytePayloadRow(offset: offset, bytes: chunk));
    }
    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('(empty payload)', style: TextStyle(color: tokens.textTertiary)),
        ),
      );
    }
    return SingleChildScrollView(
      key: const Key('payload-byte-scroll'),
      scrollDirection: Axis.horizontal,
      child: Column(key: const Key('payload-byte-view'), crossAxisAlignment: CrossAxisAlignment.start, children: [const _BytePayloadRow.header(), ...rows]),
    );
  }
}

/// One geometrically aligned row in the byte table. Every column has a fixed
/// width, so alignment never depends on the metrics of a particular glyph.
class _BytePayloadRow extends StatelessWidget {
  const _BytePayloadRow({required this.offset, required this.bytes}) : isHeader = false;
  const _BytePayloadRow.header() : offset = 0, bytes = const [], isHeader = true;

  static const double _offsetWidth = 76;
  static const double _byteWidth = 24;
  static const double _groupGap = 8;
  static const double _asciiWidth = 150;

  final int offset;
  final List<int> bytes;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final rowIndex = offset ~/ 16;
    final style = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.55, color: tokens.textPrimary);
    final ascii = bytes.map((byte) => byte >= 32 && byte <= 126 ? String.fromCharCode(byte) : '.').join();
    return DefaultTextStyle(
      style: style,
      child: SizedBox(
        height: 22,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _offsetWidth,
              child: Text(
                isHeader ? 'OFFSET' : offset.toRadixString(16).padLeft(8, '0').toUpperCase(),
                key: isHeader ? const Key('payload-byte-offset-header') : Key('payload-byte-offset-$rowIndex'),
                style: TextStyle(color: tokens.textTertiary, fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal),
              ),
            ),
            for (var index = 0; index < 16; index++) ...[
              if (index == 8) const SizedBox(width: _groupGap),
              SizedBox(
                width: _byteWidth,
                child: Text(
                  isHeader
                      ? index.toRadixString(16).padLeft(2, '0').toUpperCase()
                      : index < bytes.length
                      ? bytes[index].toRadixString(16).padLeft(2, '0').toUpperCase()
                      : '',
                  key: isHeader ? Key('payload-byte-header-$index') : Key('payload-byte-$rowIndex-$index'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isHeader ? tokens.textTertiary : tokens.textPrimary, fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal),
                ),
              ),
            ],
            const SizedBox(width: 12),
            SizedBox(
              width: _asciiWidth,
              child: Text(
                isHeader ? 'ASCII' : ascii,
                key: isHeader ? const Key('payload-byte-ascii-header') : Key('payload-byte-ascii-$rowIndex'),
                softWrap: false,
                style: TextStyle(color: isHeader ? tokens.textTertiary : tokens.textSecondary, fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small inline widget for a bare numeric payload with a pin icon.
class _PinnableValue extends StatefulWidget {
  const _PinnableValue({required this.payload, required this.topic, required this.isPinned, this.unit});

  final String payload;
  final String topic;
  final String? unit;
  final bool isPinned;

  @override
  State<_PinnableValue> createState() => _PinnableValueState();
}

class _PinnableValueState extends State<_PinnableValue> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = widget.isPinned || _hovering ? tokens.primary : tokens.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Tooltip(
            message: widget.isPinned ? 'Remove from dashboard' : 'Pin to dashboard',
            child: GestureDetector(
              onTap: () => _onPin(context, widget.topic, null, null, unit: widget.unit),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.push_pin_rounded, size: 12, color: color),
              ),
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

/// Pins a value to the dashboard, or removes its existing dashboard graphs.
void _onPin(BuildContext context, String topic, String? keyPath, String? defaultName, {String? unit}) async {
  final vm = context.read<MonitorViewModel>();
  final brokerId = vm.activeBroker?.id;
  if (brokerId == null) return;

  final preferences = context.read<DashboardPreferencesRepository>();
  final dashboard = context.read<DashboardRepository>();
  final cards = dashboard.cardsForBroker(brokerId);

  final existing = cards.where((card) => card.topic == topic && card.jsonKeyPath == keyPath).toList(growable: false);
  if (existing.isNotEmpty) {
    final existingIds = existing.map((card) => card.id).toSet();
    final remaining = cards.where((card) => !existingIds.contains(card.id)).toList(growable: false);
    await dashboard.setCards(brokerId, [for (var index = 0; index < remaining.length; index++) remaining[index].copyWith(position: index)]);

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(const SnackBar(content: Text('Removed from dashboard'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    return;
  }

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
