import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/history/message_history_service.dart';
import '../../../models/topic_node.dart';
import '../../../models/topic_node_value.dart';
import '../../../shared/format_helpers.dart';
import '../../../shared/widgets/copy_button.dart';
import '../../../shared/widgets/qos_tag.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Panel showing the message history for a selected topic.
///
/// Displays a reverse-chronological list of received messages.
/// Selection is communicated to the parent via [onSelect].
class HistoryPanel extends StatefulWidget {
  const HistoryPanel({super.key, required this.node, this.selectedValue, this.onSelect});

  final TopicTreeNode node;

  /// The currently selected history value (managed by parent).
  final TopicNodeValue? selectedValue;

  /// Called when a history row is tapped. Pass the value, or null to deselect.
  final ValueChanged<TopicNodeValue?>? onSelect;

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _trackNewest = true;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onUserScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onUserScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onUserScroll() {
    if (_isAnimating) return;
    if (_scrollController.offset <= 1) {
      _trackNewest = true;
    } else {
      _trackNewest = false;
    }
  }

  void _scrollToTopIfNeeded() {
    if (!_scrollController.hasClients || !_trackNewest) return;
    if (_scrollController.offset <= 0) return;
    _isAnimating = true;
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 150), curve: Curves.easeOut).then((_) {
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final historyService = context.read<MessageHistoryService>();
    final isExtended = historyService.isIncreased(widget.node.fullPath);

    return ValueListenableBuilder<TopicNodeValue?>(
      valueListenable: widget.node.valueNotifier,
      builder: (context, currentValue, _) {
        final history = historyService.getHistory(widget.node.fullPath);

        if (history.isEmpty) {
          return _EmptyHistory(tokens: tokens);
        }

        // Keep newest on top when user hasn't scrolled away.
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTopIfNeeded());

        return Column(
          children: [
            // Monitoring status bar
            _MonitoringBar(
              topic: widget.node.fullPath,
              isExtended: isExtended,
              historyCount: history.length,
              onToggle: () {
                historyService.toggleIncreased(widget.node.fullPath);
                setState(() {});
              },
              onClear: () {
                historyService.clearTopics([widget.node.fullPath]);
                widget.onSelect?.call(null);
                setState(() {});
              },
            ),
            // History list — newest first
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: history.length,
                separatorBuilder: (_, _) => Divider(height: 0.5, thickness: 0.5, color: tokens.border, indent: 12, endIndent: 12),
                itemBuilder: (context, index) {
                  // Reverse: index 0 = newest.
                  final reverseIndex = history.length - 1 - index;
                  final value = history[reverseIndex];
                  final isSelected = widget.selectedValue?.seq == value.seq;
                  final isLatest = reverseIndex == history.length - 1;

                  return _HistoryRow(
                    value: value,
                    isSelected: isSelected,
                    isLatest: isLatest,
                    tokens: tokens,
                    onTap: () {
                      widget.onSelect?.call(isSelected ? null : value);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.tokens});

  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 28, color: tokens.muted),
            const SizedBox(height: 10),
            Text('No history yet', style: TextStyle(fontSize: 12, color: tokens.textTertiary)),
            const SizedBox(height: 4),
            Text(
              'Messages will appear here\nas they arrive',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: tokens.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Monitoring status bar ───────────────────────────────────────────────

class _MonitoringBar extends StatefulWidget {
  const _MonitoringBar({required this.topic, required this.isExtended, required this.historyCount, required this.onToggle, required this.onClear});

  final String topic;
  final bool isExtended;
  final int historyCount;
  final VoidCallback onToggle;
  final VoidCallback onClear;

  @override
  State<_MonitoringBar> createState() => _MonitoringBarState();
}

class _MonitoringBarState extends State<_MonitoringBar> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = widget.isExtended ? AppColors.success500 : tokens.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isExtended ? AppColors.success500.withValues(alpha: 0.06) : tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            '${widget.historyCount}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tokens.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(width: 4),
          Text('stored', style: TextStyle(fontSize: 11, color: tokens.textTertiary)),
          const SizedBox(width: 8),
          _ClearButton(onTap: widget.onClear),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              onTap: widget.onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isExtended ? AppColors.success500.withValues(alpha: _hovering ? 0.18 : 0.1) : (_hovering ? tokens.elevated : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: widget.isExtended ? AppColors.success500.withValues(alpha: 0.3) : tokens.border, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.isExtended ? Icons.trending_up_rounded : Icons.trending_flat_rounded, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      widget.isExtended ? 'Increased' : 'Standard',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clear history button ────────────────────────────────────────────────

class _ClearButton extends StatefulWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.error500.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _hovering ? AppColors.error500.withValues(alpha: 0.3) : tokens.border, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_sweep_rounded, size: 12, color: _hovering ? AppColors.error500 : tokens.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Clear',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _hovering ? AppColors.error500 : tokens.textTertiary, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── History row ─────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.value, required this.isSelected, required this.isLatest, required this.tokens, required this.onTap});

  final TopicNodeValue value;
  final bool isSelected;
  final bool isLatest;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeStr = formatTimestamp(value.receivedAt, verbose: true);
    final payloadPreview = truncate(value.payload, 60);

    final bg = isSelected ? tokens.primary.withValues(alpha: 0.08) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: isSelected ? Border(left: BorderSide(color: tokens.primary, width: 2)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sequence number
            SizedBox(
              width: 32,
              child: Text(
                '#${value.seq}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isLatest ? tokens.primary : tokens.textTertiary, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
            // Payload preview + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tokens.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      const SizedBox(width: 8),
                      _MiniQos(qos: value.qos),
                      if (value.retain) ...[const SizedBox(width: 6), Icon(Icons.push_pin_rounded, size: 9, color: AppColors.warning500)],
                      if (isLatest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: tokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
                          child: Text(
                            'LATEST',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: tokens.primary, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    payloadPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, fontFamily: 'SF Mono, Menlo, monospace', color: tokens.textPrimary),
                  ),
                ],
              ),
            ),
            CopyButton(text: value.payload, size: 13),
            if (isSelected) Icon(Icons.chevron_right_rounded, size: 16, color: tokens.primary),
          ],
        ),
      ),
    );
  }
}

// ── Tiny QoS indicator ──────────────────────────────────────────────────

class _MiniQos extends StatelessWidget {
  const _MiniQos({required this.qos});

  final int qos;

  @override
  Widget build(BuildContext context) {
    final color = QosTag.colorFor(qos);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(3)),
      child: Text(
        'Q$qos',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
