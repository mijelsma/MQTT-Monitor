import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/monitor_workspace_controller.dart';
import 'topic_tree_empty_state.dart';
import 'topic_tree_list.dart';

/// The main MQTT topic tree panel.
///
/// Reads the cached flat list from the [MonitorWorkspaceController] and renders
/// [TopicTreeRow] items with indent-aware separators.
class TopicTree extends StatelessWidget {
  const TopicTree({super.key, required this.filterController});

  final TextEditingController filterController;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorWorkspaceController>();
    final rows = vm.visibleRows;
    final hasFilter = vm.filter.isNotEmpty;
    if (rows.isEmpty) return TopicTreeEmptyState(hasFilter: hasFilter);

    return TopicTreeList(rows: rows, selectedNode: vm.selectedNode, onToggle: vm.toggleExpand, onSelect: vm.selectNode);
  }
}
