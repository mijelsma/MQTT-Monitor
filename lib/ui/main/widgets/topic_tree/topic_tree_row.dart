import 'package:flutter/material.dart';

import '../../../../state/app_state.dart';
import '../../../../state/keys/settings_keys.dart';
import '../../../../theme/app_tokens/app_tokens.dart';
import 'topic_tree_node.dart';

/// A single row in the topic tree.
///
/// **Surgical updates**: this widget subscribes directly to its node's
/// [TopicTreeNode.valueNotifier]. When a message arrives for this topic path,
/// only this one [State] object rebuilds — the parent list stays untouched.
///
/// A brief highlight pulse (fade-out overlay) is driven by a per-row
/// [AnimationController] that fires on every new [TopicNodeValue].
class TopicTreeRow extends StatefulWidget {
  const TopicTreeRow({super.key, required this.node, required this.depth, required this.onToggle});

  final TopicTreeNode node;

  /// Visual indent depth — 0 = root level, each step adds 18 px indent.
  final int depth;

  /// Called when the user taps a branch row to toggle expand/collapse.
  final VoidCallback onToggle;

  @override
  State<TopicTreeRow> createState() => _TopicTreeRowState();
}

class _TopicTreeRowState extends State<TopicTreeRow> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  TopicNodeValue? _currentValue;

  /// Peak alpha for the flash overlay.
  static const double _kPeakAlpha = 0.28;

  @override
  void initState() {
    super.initState();

    // Initialise at 1.0 → initial highlight opacity = (1 − 1) * α = 0.
    // When a value arrives, forward(from: 0) drives 0 → 1, so opacity goes
    // from _kPeakAlpha back to 0, producing a clean fade-out flash.
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 750), value: 1.0);
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeOut);

    _currentValue = widget.node.valueNotifier.value;

    // pulseNotifier ticks for every message arriving at this node OR any
    // descendant — drives the flash animation for both leaves and branches.
    widget.node.pulseNotifier.addListener(_onPulse);
    // valueNotifier is only for keeping the displayed value up-to-date.
    widget.node.valueNotifier.addListener(_onValueChanged);
    _pulse.addListener(_onAnimTick);
  }

  // The controller already rate-limits pulses to the configured pps. Rows
  // simply fire unconditionally whenever the controller says to.
  void _onPulse() {
    if (!mounted) return;
    if (!AppStateManager.instance.read(SettingsKeys.showActivity)) return;
    _pulse.duration = Duration(milliseconds: AppStateManager.instance.read(SettingsKeys.pulseFadeMs));
    _pulse.forward(from: 0.0);
  }

  void _onValueChanged() {
    if (mounted) setState(() => _currentValue = widget.node.valueNotifier.value);
  }

  void _onAnimTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.node.pulseNotifier.removeListener(_onPulse);
    widget.node.valueNotifier.removeListener(_onValueChanged);
    _pulse.removeListener(_onAnimTick);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final node = widget.node;

    // opacity = (1 - animValue) → bright at animation start, 0 at end.
    final pulseAlpha = (1.0 - _pulseAnim.value) * _kPeakAlpha;

    return InkWell(
      onTap: node.isBranch ? widget.onToggle : null,
      splashColor: tokens.primary.withValues(alpha: 0.07),
      highlightColor: tokens.selectedBg,
      child: Container(
        // Pulse overlay colour: uses primary tint from theme palette.
        color: tokens.primary.withValues(alpha: pulseAlpha),
        padding: EdgeInsets.fromLTRB(
          10.0 + widget.depth * 18.0, // adaptive left indent
          9,
          14,
          9,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Branch chevron OR leaf indicator dot
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
            // Segment label
            Text(
              node.segment,
              style: TextStyle(fontSize: 13, fontWeight: node.isBranch ? FontWeight.w600 : FontWeight.w400, color: node.isBranch ? tokens.textPrimary : tokens.textSecondary, height: 1.3),
            ),
            // Equals + value
            if (_currentValue != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text(
                  '=',
                  style: TextStyle(fontSize: 12, color: tokens.textTertiary, fontWeight: FontWeight.w300, height: 1.3),
                ),
              ),
              Expanded(
                child: Text(
                  _currentValue!.payload,
                  style: TextStyle(fontSize: 13, color: tokens.primary, fontWeight: FontWeight.w500, height: 1.3),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ] else
              const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
