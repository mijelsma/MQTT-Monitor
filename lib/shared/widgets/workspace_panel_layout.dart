import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'workspace_panel_controller.dart';
import 'workspace_panel_divider.dart';
import 'workspace_panel_header.dart';
import 'workspace_panel_section.dart';

/// Maps a 0 to 100 speed setting to the workspace panel animation duration.
Duration workspacePanelAnimationDurationForSpeed(int speed) {
  final clamped = speed.clamp(0, 100);
  final milliseconds = clamped <= 60
      ? 500 - (340 / 60) * clamped
      : 340 - 3 * clamped;
  return Duration(milliseconds: milliseconds.round());
}

const double _headerHeight = 36;
const double _dividerHeight = 14;

/// Lays out collapsible, resizable workspace panels with animated redistribution.
class WorkspacePanelLayout extends StatefulWidget {
  /// Creates a panel layout.
  const WorkspacePanelLayout({
    super.key,
    required this.controller,
    required this.sections,
    required this.animationDuration,
    required this.animationsEnabled,
    required this.dividerSemanticLabelBuilder,
  });

  /// Owns collapsed and relative-size state.
  final WorkspacePanelController controller;

  /// Panels in visual order.
  final List<WorkspacePanelSection> sections;

  /// Duration used for collapse and expansion.
  final Duration animationDuration;

  /// Whether collapse and expansion animate.
  final bool animationsEnabled;

  /// Builds an accessibility label for the two panels a divider resizes.
  final String Function(int firstIndex, int secondIndex)
  dividerSemanticLabelBuilder;

  @override
  State<WorkspacePanelLayout> createState() => _WorkspacePanelLayoutState();
}

class _WorkspacePanelLayoutState extends State<WorkspacePanelLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transition;
  late List<double> _oldShares;
  late List<double> _newShares;
  late List<bool> _collapsed;

  @override
  void initState() {
    super.initState();
    assert(widget.sections.length == widget.controller.length);
    _newShares = widget.controller.shares;
    _oldShares = List<double>.of(_newShares);
    _collapsed = _collapsedSnapshot();
    _transition = AnimationController(
      vsync: this,
      value: 1,
      duration: widget.animationDuration,
    );
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(WorkspacePanelLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.sections.length == widget.controller.length);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _oldShares = widget.controller.shares;
      _newShares = List<double>.of(_oldShares);
      _collapsed = _collapsedSnapshot();
      _transition.value = 1;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _transition.dispose();
    super.dispose();
  }

  List<bool> _collapsedSnapshot() => [
    for (var index = 0; index < widget.controller.length; index++)
      widget.controller.isCollapsed(index),
  ];

  List<double> _currentShares() {
    final progress = _transition.value;
    return [
      for (var index = 0; index < _newShares.length; index++)
        _oldShares[index] + (_newShares[index] - _oldShares[index]) * progress,
    ];
  }

  void _handleControllerChanged() {
    final collapsed = _collapsedSnapshot();
    final collapseChanged = !_listsEqual(collapsed, _collapsed);
    _collapsed = collapsed;
    final target = widget.controller.shares;

    if (collapseChanged && widget.animationsEnabled) {
      _oldShares = _currentShares();
      _newShares = target;
      _transition.value = 0;
      _transition.animateTo(
        1,
        duration: widget.animationDuration,
        curve: Curves.easeOutCubic,
      );
    } else {
      _oldShares = List<double>.of(target);
      _newShares = List<double>.of(target);
      _transition.value = 1;
    }
    if (mounted) setState(() {});
  }

  bool _listsEqual(List<bool> left, List<bool> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _resize(int first, int second, double contentHeight, double pixelDelta) {
    var expandedRatioTotal = 0.0;
    for (var index = 0; index < widget.controller.length; index++) {
      if (!widget.controller.isCollapsed(index)) {
        expandedRatioTotal += widget.controller.ratioAt(index);
      }
    }
    final safeHeight = contentHeight <= 0 ? 1.0 : contentHeight;
    widget.controller.resizePair(
      first,
      second,
      pixelDelta * expandedRatioTotal / safeHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transition,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) => _buildPanels(constraints),
      ),
    );
  }

  Widget _buildPanels(BoxConstraints constraints) {
    final panelCount = widget.sections.length;
    final expandedIndices = [
      for (var index = 0; index < panelCount; index++)
        if (_newShares[index] > 0) index,
    ];
    final nextExpandedByIndex = <int, int>{
      for (var position = 0; position < expandedIndices.length - 1; position++)
        expandedIndices[position]: expandedIndices[position + 1],
    };
    final dividerCount = math.max(0, expandedIndices.length - 1);
    final chromeHeight =
        panelCount * _headerHeight + dividerCount * _dividerHeight;
    final maxHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : chromeHeight;
    final available = math.max(0.0, maxHeight - chromeHeight);
    final shares = _normalizedCurrentShares();

    final children = <Widget>[];
    for (var index = 0; index < panelCount; index++) {
      final section = widget.sections[index];
      children.add(
        SizedBox(
          height: _headerHeight,
          child: WorkspacePanelHeader(
            key: section.toggleKey,
            title: section.title,
            icon: section.icon,
            collapsed: widget.controller.isCollapsed(index),
            onToggle: () => widget.controller.toggle(index),
            animationDuration: widget.animationsEnabled
                ? widget.animationDuration
                : Duration.zero,
          ),
        ),
      );

      final visibleHeight = shares[index] * available;
      final wasVisible = _oldShares[index] > 0;
      final willBeVisible = _newShares[index] > 0;
      final transitioningVisibility = wasVisible != willBeVisible;
      final layoutHeight = transitioningVisibility
          ? math.max(_oldShares[index], _newShares[index]) * available
          : willBeVisible
          ? visibleHeight
          : math.max(available, 300.0);
      children.add(
        SizedBox(
          height: visibleHeight,
          child: ClipRect(
            key: section.contentKey,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: layoutHeight,
              maxHeight: layoutHeight,
              child: TickerMode(
                enabled: willBeVisible,
                child: ExcludeSemantics(
                  excluding: !willBeVisible,
                  child: IgnorePointer(
                    ignoring: !willBeVisible,
                    child: section.body,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final nextExpanded = nextExpandedByIndex[index];
      if (nextExpanded != null) {
        children.add(
          SizedBox(
            height: _dividerHeight,
            child: WorkspacePanelDivider(
              key: ValueKey('workspace-panel-divider-$index-$nextExpanded'),
              semanticLabel: widget.dividerSemanticLabelBuilder(
                index,
                nextExpanded,
              ),
              onDragUpdate: (details) =>
                  _resize(index, nextExpanded, available, details.delta.dy),
              onIncrease: () =>
                  _resize(index, nextExpanded, available, available * 0.05),
              onDecrease: () =>
                  _resize(index, nextExpanded, available, -available * 0.05),
            ),
          ),
        );
      }
    }

    if (maxHeight < chromeHeight) {
      return SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      );
    }
    children.add(const Spacer());
    return Column(children: children);
  }

  List<double> _normalizedCurrentShares() {
    var shares = _currentShares();
    final total = shares.fold<double>(0, (sum, share) => sum + share);
    if (total > 1) {
      shares = [for (final share in shares) share / total];
    }
    return shares;
  }
}
