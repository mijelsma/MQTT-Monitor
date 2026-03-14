import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_tokens/app_tokens.dart';
import '../monitor_viewmodel.dart';
import 'message_detail_panel.dart';

/// The right-hand sidebar showing the selected message detail.
class DetailSidebar extends StatelessWidget {
  const DetailSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final vm = context.watch<MonitorViewModel>();
    final selected = vm.selectedNode;

    return Container(
      color: tokens.bg,
      child: Column(
        children: [
          _SectionHeader(title: 'MESSAGE DETAIL', icon: Icons.info_outline_rounded),
          Expanded(
            child: selected != null ? MessageDetailPanel(key: ValueKey(selected.fullPath), node: selected) : _NoSelection(),
          ),
        ],
      ),
    );
  }
}

/// Section header for the sidebar.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: tokens.textSecondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: tokens.textSecondary),
          ),
        ],
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
