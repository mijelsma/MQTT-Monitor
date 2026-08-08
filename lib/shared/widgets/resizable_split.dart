import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// A horizontal or vertical split view with a draggable divider.
///
/// Uses flex-based layout so it never overflows.
class ResizableSplit extends StatefulWidget {
  const ResizableSplit({super.key, required this.first, required this.second, this.initialRatio = 0.5, this.minRatio = 0.2, this.maxRatio = 0.8, this.minSecondSize = 0, this.axis = Axis.horizontal, this.onRatioChanged, this.onRatioUpdate});

  final Widget first;
  final Widget second;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;

  /// Minimum width (or height for a vertical axis) of the [second] pane in
  /// pixels. Overrides [maxRatio] when the split is small enough for the
  /// ratio-based limit to leave the second pane narrower than this.
  final double minSecondSize;
  final Axis axis;

  /// Called once when the user finishes dragging the divider.
  final ValueChanged<double>? onRatioChanged;

  /// Called continuously while the user drags the divider (before
  /// [onRatioChanged]). Use this to update UI that must track the split
  /// position live, such as an overlay constrained to the left panel width.
  final ValueChanged<double>? onRatioUpdate;

  @override
  State<ResizableSplit> createState() => _ResizableSplitState();
}

class _ResizableSplitState extends State<ResizableSplit> {
  late double _ratio;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
  }

  double _clampRatio(double ratio, double totalSize) {
    var maxAllowed = widget.maxRatio;
    if (widget.minSecondSize > 0 && totalSize > 0) {
      maxAllowed = math.min(widget.maxRatio, 1 - widget.minSecondSize / totalSize);
    }
    if (maxAllowed < widget.minRatio) maxAllowed = widget.minRatio;
    return ratio.clamp(widget.minRatio, maxAllowed);
  }

  void _onDragUpdate(DragUpdateDetails details, double totalSize) {
    final delta = widget.axis == Axis.horizontal ? details.delta.dx : details.delta.dy;
    setState(() {
      _ratio = _clampRatio(_ratio + delta / totalSize, totalSize);
    });
    widget.onRatioUpdate?.call(_ratio);
  }

  void _onDragEnd(DragEndDetails _) {
    widget.onRatioChanged?.call(_ratio);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isHorizontal = widget.axis == Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = isHorizontal ? constraints.maxWidth : constraints.maxHeight;
        final ratio = _clampRatio(_ratio, totalSize);
        // Convert ratio to integer flex weights (x1000 for precision).
        final firstFlex = (ratio * 1000).round();
        final secondFlex = 1000 - firstFlex;

        final children = <Widget>[
          Expanded(flex: firstFlex, child: widget.first),
          MouseRegion(
            cursor: isHorizontal ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow,
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: isHorizontal ? (d) => _onDragUpdate(d, totalSize) : null,
              onVerticalDragUpdate: !isHorizontal ? (d) => _onDragUpdate(d, totalSize) : null,
              onHorizontalDragEnd: isHorizontal ? _onDragEnd : null,
              onVerticalDragEnd: !isHorizontal ? _onDragEnd : null,
              child: _DividerHandle(isHorizontal: isHorizontal, hovering: _hovering, borderColor: tokens.border, accentColor: tokens.primary),
            ),
          ),
          Expanded(flex: secondFlex, child: widget.second),
        ];

        if (isHorizontal) {
          return Row(children: children);
        } else {
          return Column(children: children);
        }
      },
    );
  }
}

/// The visible drag handle between the two panels.
///
/// Shows a thin line with a small grip indicator in the center.
/// Highlights on hover so the user knows it's draggable.
class _DividerHandle extends StatelessWidget {
  const _DividerHandle({required this.isHorizontal, required this.hovering, required this.borderColor, required this.accentColor});

  final bool isHorizontal;
  final bool hovering;
  final Color borderColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final lineColor = hovering ? accentColor.withValues(alpha: 0.6) : borderColor;
    final gripColor = hovering ? accentColor.withValues(alpha: 0.8) : borderColor;
    const hitArea = 14.0;
    const gripLength = 40.0;

    return SizedBox(
      width: isHorizontal ? hitArea : double.infinity,
      height: isHorizontal ? double.infinity : hitArea,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thin divider line
          AnimatedContainer(duration: const Duration(milliseconds: 150), width: isHorizontal ? 1 : double.infinity, height: isHorizontal ? double.infinity : 1, color: lineColor),
          // Grip indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isHorizontal ? 4 : gripLength,
            height: isHorizontal ? gripLength : 4,
            decoration: BoxDecoration(color: gripColor, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }
}
