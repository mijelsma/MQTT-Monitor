import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../models/topic_node_value.dart';
import '../../../shared/widgets/resizable_split.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../monitor_viewmodel.dart';
import 'history_panel.dart';
import 'message_detail_panel.dart';
import 'publish_panel.dart';
import 'shortcuts_panel.dart';

/// The right-hand sidebar showing the selected message detail, history, and publish panel.
class DetailSidebar extends StatefulWidget {
  const DetailSidebar({super.key});

  @override
  State<DetailSidebar> createState() => _DetailSidebarState();
}

class _DetailSidebarState extends State<DetailSidebar> {
  bool _detailCollapsed = false;
  bool _historyCollapsed = true;
  bool _publishCollapsed = false;
  bool _shortcutsCollapsed = true;

  /// The history value currently selected, or null if showing latest.
  TopicNodeValue? _selectedHistoryValue;
  String? _lastTopicPath;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<MonitorViewModel>();
    final selected = vm.selectedNode;

    // Clear history selection when topic changes.
    if (selected?.fullPath != _lastTopicPath) {
      _lastTopicPath = selected?.fullPath;
      _selectedHistoryValue = null;
    }

    final detailContent = selected != null ? MessageDetailPanel(key: ValueKey(selected.fullPath), node: selected, selectedHistory: _selectedHistoryValue, onClearSelection: () => setState(() => _selectedHistoryValue = null)) : const _NoSelection();
    final historyContent = selected != null ? HistoryPanel(key: ValueKey('history_${selected.fullPath}'), node: selected, selectedValue: _selectedHistoryValue, onSelect: (value) => setState(() => _selectedHistoryValue = value)) : const _NoSelection();

    // Fixed-order section definitions — order never changes.
    final s = S.of(context);
    final sections = [
      (collapsed: _detailCollapsed, title: s.sidebarMessageDetail, icon: Icons.info_outline_rounded, content: detailContent, toggle: () => setState(() => _detailCollapsed = !_detailCollapsed)),
      (collapsed: _historyCollapsed, title: s.sidebarHistory, icon: Icons.history_rounded, content: historyContent, toggle: () => setState(() => _historyCollapsed = !_historyCollapsed)),
      (collapsed: _publishCollapsed, title: s.sidebarPublish, icon: Icons.send_rounded, content: const PublishPanel(), toggle: () => setState(() => _publishCollapsed = !_publishCollapsed)),
      (collapsed: _shortcutsCollapsed, title: s.sidebarShortcuts, icon: Icons.bolt_rounded, content: const ShortcutsPanel(), toggle: () => setState(() => _shortcutsCollapsed = !_shortcutsCollapsed)),
    ];

    // ── Build layout keeping headers in strict visual order ──
    //
    // Group sections into "chunks": each chunk is zero-or-more collapsed
    // sections followed by one expanded section. Any trailing collapsed
    // sections form a separate tail group.
    //
    // Collapsed headers that appear *between* expanded sections are placed
    // inside the ResizableSplit (grouped with the next expanded panel) so
    // that visual ordering is always DETAIL → HISTORY → PUBLISH.

    final chunks = <({List<int> collapsedBefore, int expandedIndex})>[];
    var pendingCollapsed = <int>[];

    for (var i = 0; i < sections.length; i++) {
      if (sections[i].collapsed) {
        pendingCollapsed.add(i);
      } else {
        chunks.add((collapsedBefore: pendingCollapsed, expandedIndex: i));
        pendingCollapsed = <int>[];
      }
    }
    final trailingCollapsed = pendingCollapsed;

    Widget headerFor(int i, {required bool collapsed}) => _SectionHeader(title: sections[i].title, icon: sections[i].icon, collapsed: collapsed, onToggle: sections[i].toggle);

    final children = <Widget>[];

    if (chunks.isEmpty) {
      // All sections collapsed.
      for (var i = 0; i < sections.length; i++) {
        children.add(headerFor(i, collapsed: true));
      }
      children.add(const Spacer());
    } else if (chunks.length == 1) {
      // Exactly one expanded section.
      final chunk = chunks[0];

      // Collapsed headers before the expanded one.
      for (final ci in chunk.collapsedBefore) {
        children.add(headerFor(ci, collapsed: true));
      }

      // The expanded section itself.
      children.add(
        Expanded(
          child: Column(
            children: [
              headerFor(chunk.expandedIndex, collapsed: false),
              Expanded(child: ClipRect(child: sections[chunk.expandedIndex].content)),
            ],
          ),
        ),
      );

      // Trailing collapsed headers.
      for (final ci in trailingCollapsed) {
        children.add(headerFor(ci, collapsed: true));
      }
    } else {
      // 2+ expanded sections — use ResizableSplit.
      //
      // Leading collapsed headers (before the first expanded section) go
      // *above* the split. Collapsed headers between expanded sections go
      // *inside* the split, grouped with the following expanded panel.
      // Trailing collapsed headers go *below* the split.

      // Leading collapsed.
      for (final ci in chunks[0].collapsedBefore) {
        children.add(headerFor(ci, collapsed: true));
      }

      // Build one widget per chunk for the ResizableSplit.
      final panes = <Widget>[];
      for (var i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        // First chunk's collapsed headers are already rendered above.
        final collapsedBefore = i == 0 ? <int>[] : chunk.collapsedBefore;
        panes.add(
          Column(
            children: [
              for (final ci in collapsedBefore) headerFor(ci, collapsed: true),
              headerFor(chunk.expandedIndex, collapsed: false),
              Expanded(child: ClipRect(child: sections[chunk.expandedIndex].content)),
            ],
          ),
        );
      }

      Widget body;
      if (panes.length == 2) {
        body = ResizableSplit(axis: Axis.vertical, initialRatio: 0.5, minRatio: 0.2, maxRatio: 0.8, first: panes[0], second: panes[1]);
      } else {
        body = ResizableSplit(
          axis: Axis.vertical,
          initialRatio: 0.4,
          minRatio: 0.15,
          maxRatio: 0.6,
          first: panes[0],
          second: ResizableSplit(axis: Axis.vertical, initialRatio: 0.5, minRatio: 0.2, maxRatio: 0.8, first: panes[1], second: panes[2]),
        );
      }

      children.add(Expanded(child: body));

      // Trailing collapsed.
      for (final ci in trailingCollapsed) {
        children.add(headerFor(ci, collapsed: true));
      }
    }

    return Container(
      color: tokens.bg,
      child: Column(children: children),
    );
  }
}

/// Collapsible section header for the sidebar.
class _SectionHeader extends StatefulWidget {
  const _SectionHeader({required this.title, required this.icon, required this.collapsed, required this.onToggle});

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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: tokens.textSecondary),
                ),
              ),
              AnimatedRotation(
                turns: widget.collapsed ? -0.25 : 0,
                duration: const Duration(milliseconds: 200),
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
