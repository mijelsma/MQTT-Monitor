import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/keys/layout_keys.dart';
import '../../../core/state/keys/settings_keys.dart';
import '../../../core/state/state_key.dart';
import '../../../generated/l10n.dart';
import '../../../models/sidebar_panel_default.dart';
import '../../../models/topic_node_value.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../monitor_viewmodel.dart';
import 'history_panel.dart';
import 'message_detail_panel.dart';
import 'publish_panel.dart';
import 'shortcuts_panel.dart';

/// Maps the user-facing 0–100% speed setting to an animation duration.
///
/// The curve is piecewise-linear and pinned at 60% → 160 ms:
/// 0% → 500 ms (slow), 60% → 160 ms, 100% → 40 ms (fast). Values outside
/// 0–100 are clamped.
Duration sidebarAnimationDurationForSpeed(int speed) {
  final s = speed.clamp(0, 100);
  final ms = s <= 60 ? 500 - (340 / 60) * s : 340 - 3 * s;
  return Duration(milliseconds: ms.round());
}

const double _kHeaderHeight = 36;
const double _kDividerHeight = 14;

/// The right-hand sidebar showing the selected message detail, history, and publish panel.
class DetailSidebar extends StatefulWidget {
  const DetailSidebar({super.key});

  @override
  State<DetailSidebar> createState() => _DetailSidebarState();
}

class _DetailSidebarState extends State<DetailSidebar> with TickerProviderStateMixin {
  // Target collapsed state per section: [detail, history, publish, shortcuts].
  final List<bool> _collapsed = [false, true, true, true];
  // Relative weights per section when expanded (draggable dividers adjust these).
  final List<double> _ratios = [1.0, 1.0, 1.0, 1.0];

  // A single transition driver: 0 → 1 lerps every section's share from
  // [_oldShares] to [_newShares]. One controller animates the whole
  // redistribution so freed space flows smoothly into neighbouring panels.
  late final AnimationController _t;
  List<double> _oldShares = const [0, 0, 0, 0];
  List<double> _newShares = const [0, 0, 0, 0];

  /// The history value currently selected, or null if showing latest.
  TopicNodeValue? _selectedHistoryValue;
  String? _lastTopicPath;

  static final _layoutKeys = <StateKey<bool>>[LayoutKeys.sidebarDetailCollapsed, LayoutKeys.sidebarHistoryCollapsed, LayoutKeys.sidebarPublishCollapsed, LayoutKeys.sidebarShortcutsCollapsed];

  static final _defaultKeys = <StateKey<SidebarPanelDefault>>[SettingsKeys.defaultSidebarDetail, SettingsKeys.defaultSidebarHistory, SettingsKeys.defaultSidebarPublish, SettingsKeys.defaultSidebarShortcuts];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateManager>();
    _collapsed[0] = _resolveInitialCollapsed(state, 0);
    _collapsed[1] = _resolveInitialCollapsed(state, 1);
    _collapsed[2] = _resolveInitialCollapsed(state, 2);
    _collapsed[3] = _resolveInitialCollapsed(state, 3);
    _t = AnimationController(vsync: this, value: 1.0, duration: const Duration(milliseconds: 200));
    _oldShares = _computeShares();
    _newShares = _oldShares;
  }

  /// Resolves the initial collapsed state for a panel using its
  /// per-panel default setting (collapsed / expanded / lastStatus).
  bool _resolveInitialCollapsed(AppStateManager state, int i) {
    final setting = state.read(_defaultKeys[i]);
    switch (setting) {
      case SidebarPanelDefault.collapsed:
        return true;
      case SidebarPanelDefault.expanded:
        return false;
      case SidebarPanelDefault.lastStatus:
        return state.read(_layoutKeys[i]);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  /// Fraction of the content area each section should occupy when settled.
  List<double> _computeShares() {
    double sum = 0;
    for (var i = 0; i < 4; i++) {
      if (!_collapsed[i]) sum += _ratios[i];
    }
    if (sum <= 0) return const [0, 0, 0, 0];
    return [for (var i = 0; i < 4; i++) !_collapsed[i] ? _ratios[i] / sum : 0.0];
  }

  /// Current animated shares, interpolated between old and new by [_t].
  List<double> _currentShares() {
    final t = _t.value;
    return [for (var i = 0; i < 4; i++) _oldShares[i] + (_newShares[i] - _oldShares[i]) * t];
  }

  void _toggle(int i) {
    final state = context.read<AppStateManager>();
    final animationsEnabled = state.read(SettingsKeys.sidebarAnimationsEnabled);
    final duration = sidebarAnimationDurationForSpeed(state.read(SettingsKeys.sidebarAnimationSpeed));

    // Continue from wherever the animation currently is.
    _oldShares = _currentShares();

    final newCollapsed = !_collapsed[i];
    if (!newCollapsed) {
      // Expanding: give the panel a fair share relative to the other open panels.
      final others = <double>[];
      for (var j = 0; j < 4; j++) {
        if (j != i && !_collapsed[j]) others.add(_ratios[j]);
      }
      _ratios[i] = others.isEmpty ? 1.0 : (others.reduce((a, b) => a + b) / others.length);
    }
    _collapsed[i] = newCollapsed;
    state.write(_layoutKeys[i], newCollapsed);
    _newShares = _computeShares();

    if (animationsEnabled) {
      _t.value = 0;
      _t.animateTo(1.0, duration: duration, curve: Curves.easeOutCubic);
    } else {
      _oldShares = List<double>.of(_newShares);
      _t.value = 1.0;
    }
    setState(() {});
  }

  void _onDividerDrag(int i, int j, DragUpdateDetails details, double contentHeight) {
    double sumRatio = 0;
    for (var k = 0; k < 4; k++) {
      if (!_collapsed[k]) sumRatio += _ratios[k];
    }
    final h = contentHeight <= 0 ? 1.0 : contentHeight;
    final deltaRatio = details.delta.dy * sumRatio / h;
    final sum = _ratios[i] + _ratios[j];
    final newI = (_ratios[i] + deltaRatio).clamp(sum * 0.15, sum * 0.85);
    setState(() {
      _ratios[i] = newI;
      _ratios[j] = sum - newI;
      _oldShares = _computeShares();
      _newShares = _oldShares;
      _t.value = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<MonitorViewModel>();
    final animationsEnabled = context.select<AppStateManager, bool>((state) => state.read(SettingsKeys.sidebarAnimationsEnabled));
    final animationSpeed = context.select<AppStateManager, int>((state) => state.read(SettingsKeys.sidebarAnimationSpeed));
    final duration = sidebarAnimationDurationForSpeed(animationSpeed);
    final selected = vm.selectedNode;

    // Clear history selection when topic changes.
    if (selected?.fullPath != _lastTopicPath) {
      _lastTopicPath = selected?.fullPath;
      _selectedHistoryValue = null;
    }

    final s = S.of(context);
    final detailContent = selected != null ? MessageDetailPanel(key: ValueKey(selected.fullPath), node: selected, selectedHistory: _selectedHistoryValue, onClearSelection: () => setState(() => _selectedHistoryValue = null)) : const _NoSelection();
    final historyContent = selected != null ? HistoryPanel(key: ValueKey('history_${selected.fullPath}'), node: selected, selectedValue: _selectedHistoryValue, onSelect: (value) => setState(() => _selectedHistoryValue = value)) : const _NoSelection();

    final contents = <Widget>[detailContent, historyContent, const PublishPanel(), const ShortcutsPanel()];
    final titles = <String>[s.sidebarMessageDetail, s.sidebarHistory, s.sidebarPublish, s.sidebarShortcuts];
    final icons = <IconData>[Icons.info_outline_rounded, Icons.history_rounded, Icons.send_rounded, Icons.bolt_rounded];
    final sectionKeys = <Key>[const Key('detail-section-toggle'), const Key('history-section-toggle'), const Key('publish-section-toggle'), const Key('shortcuts-section-toggle')];
    final contentKeys = <Key>[const Key('detail-content-clip'), const Key('history-content-clip'), const Key('publish-content-clip'), const Key('shortcuts-content-clip')];

    return Container(
      key: const Key('detail-sidebar-layout'),
      color: tokens.bg,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return _buildBody(constraints, contents, titles, icons, sectionKeys, contentKeys, duration, animationsEnabled);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BoxConstraints constraints, List<Widget> contents, List<String> titles, List<IconData> icons, List<Key> sectionKeys, List<Key> contentKeys, Duration duration, bool animationsEnabled) {
    final maxHeight = constraints.maxHeight;

    // Count dividers based on the TARGET state so the content height stays
    // stable during the animation (dividers snap out at toggle time).
    int targetDividers = 0;
    for (var i = 0; i < 3; i++) {
      if (_newShares[i] > 0 && _newShares[i + 1] > 0) targetDividers++;
    }
    final available = math.max(0.0, maxHeight - 4 * _kHeaderHeight - targetDividers * _kDividerHeight);

    var shares = _currentShares();
    var total = shares.fold<double>(0.0, (a, b) => a + b);
    if (total > 1.0) {
      shares = [for (final v in shares) v / total];
      total = 1.0;
    }

    final children = <Widget>[];
    for (var i = 0; i < 4; i++) {
      children.add(
        SizedBox(
          height: _kHeaderHeight,
          child: _SectionHeader(key: sectionKeys[i], title: titles[i], icon: icons[i], collapsed: _collapsed[i], onToggle: () => _toggle(i)),
        ),
      );

      final windowH = shares[i] * available;
      // A panel is shown when either its previous or target share is
      // non-zero. When the panel is *settled* (not transitioning between
      // visible and hidden) we render the content at its actual visible
      // height ([windowH]) so the panel's internal layout — e.g. Publish's
      // Expanded payload editor + pinned action bar — always matches what
      // the user sees. No "thinks it's bigger than it is" drift, and no
      // need to nudge the divider to snap it back to the right size.
      //
      // While a panel is *appearing* or *disappearing* (one share is zero
      // and the other is not) [windowH] passes through tiny values that
      // would overflow a column with fixed-height children. In that brief
      // transition we fall back to an OverflowBox laid out at the larger of
      // the old/new shares so the column has room to lay out normally; the
      // ClipRect just reveals more/less of it as [windowH] animates.
      final wasVisible = _oldShares[i] > 0;
      final willBeVisible = _newShares[i] > 0;
      final transitioningVisibility = wasVisible != willBeVisible;
      final settledCollapsed = _t.value >= 1.0 && !willBeVisible;

      if (settledCollapsed || (!wasVisible && !willBeVisible)) {
        children.add(const SizedBox.shrink());
      } else if (transitioningVisibility) {
        final fullH = math.max(_oldShares[i], _newShares[i]) * available;
        children.add(
          SizedBox(
            height: windowH,
            child: ClipRect(
              key: contentKeys[i],
              child: OverflowBox(alignment: Alignment.topCenter, minHeight: fullH, maxHeight: fullH, child: contents[i]),
            ),
          ),
        );
      } else {
        children.add(
          SizedBox(
            height: windowH,
            child: ClipRect(
              key: contentKeys[i],
              child: contents[i],
            ),
          ),
        );
      }

      if (i < 3 && _newShares[i] > 0 && _newShares[i + 1] > 0) {
        children.add(
          SizedBox(
            height: _kDividerHeight,
            child: _SidebarDivider(onDragUpdate: (d) => _onDividerDrag(i, i + 1, d, available)),
          ),
        );
      }
    }

    // Absorbs any leftover space (e.g. when fewer panels are open, or during
    // the collapse of the last open panel) so the headers stay pinned to top.
    children.add(const Spacer());

    return Column(children: children);
  }
}

/// Draggable divider between two adjacent expanded sections.
class _SidebarDivider extends StatefulWidget {
  const _SidebarDivider({required this.onDragUpdate});

  final ValueChanged<DragUpdateDetails> onDragUpdate;

  @override
  State<_SidebarDivider> createState() => _SidebarDividerState();
}

class _SidebarDividerState extends State<_SidebarDivider> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final lineColor = _hovering ? tokens.primary.withValues(alpha: 0.6) : tokens.border;
    final gripColor = _hovering ? tokens.primary.withValues(alpha: 0.8) : tokens.border;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: widget.onDragUpdate,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: double.infinity, height: 1, color: lineColor),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: gripColor, borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible section header for the sidebar.
class _SectionHeader extends StatefulWidget {
  const _SectionHeader({super.key, required this.title, required this.icon, required this.collapsed, required this.onToggle});

  final String title;
  final IconData icon;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final animationsEnabled = context.select<AppStateManager, bool>((state) => state.read(SettingsKeys.sidebarAnimationsEnabled));
    final animationSpeed = context.select<AppStateManager, int>((state) => state.read(SettingsKeys.sidebarAnimationSpeed));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering ? tokens.elevated : tokens.surface,
            border: Border(bottom: BorderSide(color: tokens.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: tokens.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: tokens.textSecondary),
                ),
              ),
              AnimatedRotation(
                turns: widget.collapsed ? -0.25 : 0,
                duration: animationsEnabled ? sidebarAnimationDurationForSpeed(animationSpeed) : Duration.zero,
                curve: Curves.easeOutCubic,
                child: Icon(Icons.expand_more_rounded, size: 16, color: tokens.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return UiEmptyState.compact(icon: Icons.touch_app_rounded, title: S.of(context).sidebarNoSelectionTitle, message: S.of(context).sidebarNoSelectionSubtitle);
  }
}
