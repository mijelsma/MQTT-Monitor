import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_tokens/app_tokens.dart';
import '../monitor_viewmodel.dart';
import 'topic_tree_empty_state.dart';
import 'topic_tree_row.dart';

/// The main MQTT topic tree panel.
///
/// Reads the flat list from the [MonitorViewModel] and renders
/// [TopicTreeRow] items with indent-aware separators.
class TopicTree extends StatelessWidget {
  const TopicTree({super.key, required this.filterController});

  final TextEditingController filterController;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorViewModel>();
    final rows = vm.buildFlatList();
    final tokens = context.tokens;
    final hasFilter = vm.filter.isNotEmpty;

    if (rows.isEmpty) return TopicTreeEmptyState(hasFilter: hasFilter);

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: rows.length,
      separatorBuilder: (_, i) => Divider(height: 0.5, thickness: 0.5, color: tokens.border, indent: 10.0 + rows[i].depth * 18.0 + 27, endIndent: 0),
      itemBuilder: (context, i) {
        final row = rows[i];
        return TopicTreeRow(key: ValueKey(row.node.fullPath), node: row.node, depth: row.depth, onToggle: () => vm.toggleExpand(row.node));
      },
    );
  }
}
