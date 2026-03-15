import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/resizable_split.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../monitor_viewmodel.dart';
import 'message_detail_panel.dart';
import 'publish_panel.dart';

/// The right-hand sidebar showing the selected message detail and publish panel.
class DetailSidebar extends StatefulWidget {
  const DetailSidebar({super.key});

  @override
  State<DetailSidebar> createState() => _DetailSidebarState();
}

class _DetailSidebarState extends State<DetailSidebar> {
  bool _detailCollapsed = false;
  bool _publishCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<MonitorViewModel>();
    final selected = vm.selectedNode;

    final detailContent = selected != null ? MessageDetailPanel(key: ValueKey(selected.fullPath), node: selected) : _NoSelection();

    // Both collapsed — show just the headers stacked.
    if (_detailCollapsed && _publishCollapsed) {
      return Container(
        color: tokens.bg,
        child: Column(
          children: [
            _SectionHeader(title: 'MESSAGE DETAIL', icon: Icons.info_outline_rounded, collapsed: true, onToggle: () => setState(() => _detailCollapsed = false)),
            _SectionHeader(title: 'PUBLISH', icon: Icons.send_rounded, collapsed: true, onToggle: () => setState(() => _publishCollapsed = false)),
            const Spacer(),
          ],
        ),
      );
    }

    // Only publish collapsed — detail takes full space.
    if (_publishCollapsed) {
      return Container(
        color: tokens.bg,
        child: Column(
          children: [
            _SectionHeader(title: 'MESSAGE DETAIL', icon: Icons.info_outline_rounded, collapsed: false, onToggle: () => setState(() => _detailCollapsed = true)),
            Expanded(child: detailContent),
            _SectionHeader(title: 'PUBLISH', icon: Icons.send_rounded, collapsed: true, onToggle: () => setState(() => _publishCollapsed = false)),
          ],
        ),
      );
    }

    // Only detail collapsed — publish takes full space.
    if (_detailCollapsed) {
      return Container(
        color: tokens.bg,
        child: Column(
          children: [
            _SectionHeader(title: 'MESSAGE DETAIL', icon: Icons.info_outline_rounded, collapsed: true, onToggle: () => setState(() => _detailCollapsed = false)),
            _SectionHeader(title: 'PUBLISH', icon: Icons.send_rounded, collapsed: false, onToggle: () => setState(() => _publishCollapsed = true)),
            const Expanded(child: PublishPanel()),
          ],
        ),
      );
    }

    // Both expanded — resizable vertical split.
    // The whole sidebar is scrollable per-section: the detail panel already
    // uses SingleChildScrollView internally, and the publish panel fills
    // its Expanded allocation with an expanding text field.
    return Container(
      color: tokens.bg,
      child: ResizableSplit(
        axis: Axis.vertical,
        initialRatio: 0.55,
        minRatio: 0.2,
        maxRatio: 0.8,
        first: Column(
          children: [
            _SectionHeader(title: 'MESSAGE DETAIL', icon: Icons.info_outline_rounded, collapsed: false, onToggle: () => setState(() => _detailCollapsed = true)),
            Expanded(child: detailContent),
          ],
        ),
        second: Column(
          children: [
            _SectionHeader(title: 'PUBLISH', icon: Icons.send_rounded, collapsed: false, onToggle: () => setState(() => _publishCollapsed = true)),
            const Expanded(child: PublishPanel()),
          ],
        ),
      ),
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
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: tokens.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(Icons.touch_app_rounded, size: 28, color: tokens.muted),
            ),
            const SizedBox(height: 14),
            Text('Select a topic to inspect', style: TextStyle(fontSize: 13, color: tokens.textTertiary)),
            const SizedBox(height: 4),
            Text(
              'Choose a topic from the tree\nto view message details',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: tokens.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
