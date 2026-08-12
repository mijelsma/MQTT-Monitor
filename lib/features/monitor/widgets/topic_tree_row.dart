import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/monitor/topic_node_metrics.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/keys/settings_keys.dart';
import '../../../shared/widgets/count_pill.dart';
import '../../../models/topic_node.dart';
import '../../../models/topic_node_value.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// A single row in the topic tree.
///
/// Subscribes directly to the node's [ValueNotifier]s for surgical updates —
/// only this row rebuilds when its node receives a message.
///
/// A brief highlight pulse (fade-out overlay) is driven by a per-row
/// [AnimationController] that fires on every new pulse tick.
class TopicTreeRow extends StatefulWidget {
  const TopicTreeRow({super.key, required this.node, required this.depth, required this.metrics, required this.onToggle, this.onSelect, this.selected = false});

  final TopicTreeNode node;
  final int depth;
  final ValueListenable<TopicNodeMetrics> metrics;
  final VoidCallback onToggle;
  final VoidCallback? onSelect;
  final bool selected;

  @override
  State<TopicTreeRow> createState() => _TopicTreeRowState();
}

class _TopicTreeRowState extends State<TopicTreeRow> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  TopicNodeValue? _currentValue;
  late TopicNodeMetrics _currentMetrics;

  static const double _kPeakAlpha = 0.28;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 750), value: 1.0);
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeOut);

    _currentValue = widget.node.valueNotifier.value;
    _currentMetrics = widget.metrics.value;

    widget.node.pulseNotifier.addListener(_onPulse);
    widget.node.valueNotifier.addListener(_onValueChanged);
    widget.metrics.addListener(_onMetricsChanged);
    _pulse.addListener(_onAnimTick);
  }

  @override
  void didUpdateWidget(TopicTreeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.metrics, widget.metrics)) return;
    oldWidget.metrics.removeListener(_onMetricsChanged);
    _currentMetrics = widget.metrics.value;
    widget.metrics.addListener(_onMetricsChanged);
  }

  void _onPulse() {
    if (!mounted) return;
    if (!AppStateManager.instance.read(SettingsKeys.showActivity)) return;
    _pulse.duration = Duration(milliseconds: AppStateManager.instance.read(SettingsKeys.pulseFadeMs));
    _pulse.forward(from: 0.0);
  }

  void _onValueChanged() {
    if (mounted) {
      setState(() => _currentValue = widget.node.valueNotifier.value);
    }
  }

  void _onMetricsChanged() {
    if (mounted) setState(() => _currentMetrics = widget.metrics.value);
  }

  void _onAnimTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.node.pulseNotifier.removeListener(_onPulse);
    widget.node.valueNotifier.removeListener(_onValueChanged);
    widget.metrics.removeListener(_onMetricsChanged);
    _pulse.removeListener(_onAnimTick);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final node = widget.node;

    final pulseAlpha = (1.0 - _pulseAnim.value) * _kPeakAlpha;

    final hideHighlight = AppStateManager.instance.read(SettingsKeys.disableSelectionHighlight);
    final effectiveSelected = widget.selected && !hideHighlight;

    return InkWell(
      onTap: () {
        if (node.isBranch) widget.onToggle();
        widget.onSelect?.call();
      },
      splashColor: tokens.primary.withValues(alpha: 0.07),
      highlightColor: effectiveSelected ? tokens.selectedBg : Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveSelected ? tokens.selectedBg : tokens.primary.withValues(alpha: pulseAlpha),
          border: effectiveSelected ? Border(left: BorderSide(color: tokens.primary, width: 2.5)) : null,
        ),
        padding: EdgeInsets.fromLTRB(effectiveSelected ? 7.5 + widget.depth * 18.0 : 10.0 + widget.depth * 18.0, 9, 14, 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Branch chevron or leaf dot
            SizedBox(
              width: 18,
              height: 18,
              child: node.isBranch
                  ? AnimatedRotation(
                      turns: node.isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeInOut,
                      child: Icon(Icons.chevron_right_rounded, size: 15, color: tokens.textTertiary),
                    )
                  : Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: _currentValue != null ? tokens.primary.withValues(alpha: 0.6) : tokens.muted, shape: BoxShape.circle),
                      ),
                    ),
            ),
            const SizedBox(width: 4),

            Expanded(
              child: Text.rich(
                TextSpan(
                  text: node.segment,
                  style: TextStyle(fontSize: 13, fontWeight: node.isBranch ? FontWeight.w600 : FontWeight.w400, color: node.isBranch ? tokens.textPrimary : tokens.textSecondary, height: 1.3),
                  children: _currentValue != null
                      ? [
                          TextSpan(
                            text: ' = ',
                            style: TextStyle(fontSize: 12, color: tokens.textTertiary, fontWeight: FontWeight.w300, height: 1.3),
                          ),
                          TextSpan(
                            text: _currentValue!.payload,
                            style: TextStyle(fontSize: 13, color: tokens.primary, fontWeight: FontWeight.w500, height: 1.3),
                          ),
                        ]
                      : null,
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Badges (branches) or value (leaves)
            if (node.isBranch) ...[
              if (_currentValue != null) const SizedBox(width: 6),
              CountPill(count: _currentMetrics.topicCount, label: 'topics', color: tokens.textSecondary),
              const SizedBox(width: 4),
              CountPill(count: _currentMetrics.messageCount, label: 'msgs', color: tokens.primary),
            ] else if (_currentValue != null) ...[
              const SizedBox(width: 6),
              CountPill(count: _currentMetrics.messageCount, label: 'msgs', color: tokens.primary),
            ],
          ],
        ),
      ),
    );
  }
}
