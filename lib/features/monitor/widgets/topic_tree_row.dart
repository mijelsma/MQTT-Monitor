import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/monitor/topic_node_metrics.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/keys/settings_keys.dart';
import '../../../shared/widgets/count_pill.dart';
import '../../../models/topic_node.dart';
import '../../../models/topic_node_value.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../topic_payload_preview.dart';

/// A single row in the topic tree.
///
/// Subscribes directly to the node's [ValueNotifier]s for surgical updates —
/// only this row rebuilds when its node receives a message.
///
/// A repaint-only overlay owns the optional activity animation so pulse ticks
/// never rebuild or lay out the row's text and badges.
class TopicTreeRow extends StatefulWidget {
  const TopicTreeRow({
    super.key,
    required this.node,
    required this.depth,
    required this.metrics,
    required this.onToggle,
    this.onSelect,
    this.selected = false,
  });

  final TopicTreeNode node;
  final int depth;
  final ValueListenable<TopicNodeMetrics> metrics;
  final VoidCallback onToggle;
  final VoidCallback? onSelect;
  final bool selected;

  @override
  State<TopicTreeRow> createState() => _TopicTreeRowState();
}

class _TopicTreeRowState extends State<TopicTreeRow> {
  TopicNodeValue? _currentValue;
  String? _payloadPreview;
  late TopicNodeMetrics _currentMetrics;

  @override
  void initState() {
    super.initState();

    _readCurrentValue();
    _currentMetrics = widget.metrics.value;

    widget.node.valueNotifier.addListener(_onValueChanged);
    widget.metrics.addListener(_onMetricsChanged);
  }

  @override
  void didUpdateWidget(TopicTreeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.node, widget.node)) {
      oldWidget.node.valueNotifier.removeListener(_onValueChanged);
      widget.node.valueNotifier.addListener(_onValueChanged);
      _readCurrentValue();
    }
    if (!identical(oldWidget.metrics, widget.metrics)) {
      oldWidget.metrics.removeListener(_onMetricsChanged);
      _currentMetrics = widget.metrics.value;
      widget.metrics.addListener(_onMetricsChanged);
    }
  }

  void _onValueChanged() {
    if (mounted) {
      setState(_readCurrentValue);
    }
  }

  void _readCurrentValue() {
    _currentValue = widget.node.valueNotifier.value;
    _payloadPreview = _currentValue == null
        ? null
        : buildTopicPayloadPreview(_currentValue!.payload);
  }

  void _onMetricsChanged() {
    if (mounted) setState(() => _currentMetrics = widget.metrics.value);
  }

  @override
  void dispose() {
    widget.node.valueNotifier.removeListener(_onValueChanged);
    widget.metrics.removeListener(_onMetricsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final node = widget.node;

    final hideHighlight = AppStateManager.instance.read(
      SettingsKeys.disableSelectionHighlight,
    );
    final effectiveSelected = widget.selected && !hideHighlight;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: _TopicPulseOverlay(node: node, color: tokens.primary),
        ),
        InkWell(
          onTap: () {
            if (node.isBranch) widget.onToggle();
            widget.onSelect?.call();
          },
          splashColor: tokens.primary.withValues(alpha: 0.07),
          highlightColor: effectiveSelected
              ? tokens.selectedBg
              : Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: effectiveSelected ? tokens.selectedBg : Colors.transparent,
              border: effectiveSelected
                  ? Border(left: BorderSide(color: tokens.primary, width: 2.5))
                  : null,
            ),
            padding: EdgeInsets.fromLTRB(
              effectiveSelected
                  ? 7.5 + widget.depth * 18.0
                  : 10.0 + widget.depth * 18.0,
              9,
              14,
              9,
            ),
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
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: tokens.textTertiary,
                          ),
                        )
                      : Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _currentValue != null
                                  ? tokens.primary.withValues(alpha: 0.6)
                                  : tokens.muted,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 4),

                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: node.segment,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: node.isBranch
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: node.isBranch
                            ? tokens.textPrimary
                            : tokens.textSecondary,
                        height: 1.3,
                      ),
                      children: _currentValue != null
                          ? [
                              TextSpan(
                                text: ' = ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.textTertiary,
                                  fontWeight: FontWeight.w300,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: _payloadPreview,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tokens.primary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
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
                  CountPill(
                    count: _currentMetrics.topicCount,
                    label: 'topics',
                    color: tokens.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  CountPill(
                    count: _currentMetrics.messageCount,
                    label: 'msgs',
                    color: tokens.primary,
                  ),
                ] else if (_currentValue != null) ...[
                  const SizedBox(width: 6),
                  CountPill(
                    count: _currentMetrics.messageCount,
                    label: 'msgs',
                    color: tokens.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicPulseOverlay extends StatefulWidget {
  const _TopicPulseOverlay({required this.node, required this.color})
    : super(key: const ValueKey('topic-pulse-overlay'));

  final TopicTreeNode node;
  final Color color;

  @override
  State<_TopicPulseOverlay> createState() => _TopicPulseOverlayState();
}

class _TopicPulseOverlayState extends State<_TopicPulseOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    widget.node.pulseNotifier.addListener(_onPulse);
  }

  @override
  void didUpdateWidget(_TopicPulseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.node, widget.node)) return;
    oldWidget.node.pulseNotifier.removeListener(_onPulse);
    widget.node.pulseNotifier.addListener(_onPulse);
    _disposeAnimation();
  }

  void _onPulse() {
    if (!mounted) return;
    if (!AppStateManager.instance.read(SettingsKeys.showActivity)) return;

    if (_controller == null) {
      final controller = AnimationController(
        vsync: this,
        value: 1.0,
        debugLabel: 'TopicTreeRow pulse: ${widget.node.fullPath}',
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      );
      setState(() {
        _controller = controller;
        _animation = animation;
      });
    }

    final controller = _controller!;
    controller.duration = Duration(
      milliseconds: AppStateManager.instance.read(SettingsKeys.pulseFadeMs),
    );
    controller.forward(from: 0.0);
  }

  void _disposeAnimation() {
    _animation = null;
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    widget.node.pulseNotifier.removeListener(_onPulse);
    _disposeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _animation;
    if (animation == null) return const SizedBox.expand();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TopicPulsePainter(
            animation: animation,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _TopicPulsePainter extends CustomPainter {
  _TopicPulsePainter({required this.animation, required this.color})
    : super(repaint: animation);

  static const double peakAlpha = 0.28;

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (1.0 - animation.value) * peakAlpha;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_TopicPulsePainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.color != color;
}
