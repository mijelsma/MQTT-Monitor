import 'package:flutter/material.dart';

import '../../../../theme/app_tokens/app_tokens.dart';
import 'topic_tree_controller.dart';
import 'topic_tree_empty_state.dart';
import 'topic_tree_row.dart';

/// The main MQTT topic tree panel.
///
/// Receives an already-created [controller] from its parent so that filtered
/// stats are accessible above this widget (e.g. in the status bar).
class TopicTreeWidget extends StatefulWidget {
  const TopicTreeWidget({super.key, required this.controller, required this.filterController, required this.scope});

  final TopicTreeController controller;
  final TextEditingController filterController;
  final SearchScope scope;

  @override
  State<TopicTreeWidget> createState() => _TopicTreeWidgetState();
}

class _TopicTreeWidgetState extends State<TopicTreeWidget> {
  @override
  void initState() {
    super.initState();
    widget.filterController.addListener(_onFilterChanged);
  }

  @override
  void didUpdateWidget(TopicTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterController != widget.filterController) {
      oldWidget.filterController.removeListener(_onFilterChanged);
      widget.filterController.addListener(_onFilterChanged);
    }
    if (oldWidget.scope != widget.scope) {
      widget.controller.setScope(widget.scope);
    }
  }

  void _onFilterChanged() => widget.controller.setFilter(widget.filterController.text);

  @override
  void dispose() {
    widget.filterController.removeListener(_onFilterChanged);
    // Controller is owned by the parent — do NOT dispose it here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final rows = widget.controller.buildFlatList();
        final tokens = context.tokens;
        final hasFilter = widget.controller.filter.isNotEmpty;

        return rows.isEmpty
            ? TopicTreeEmptyState(hasFilter: hasFilter)
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                separatorBuilder: (_, i) => Divider(height: 0.5, thickness: 0.5, color: tokens.border, indent: 10.0 + rows[i].depth * 18.0 + 27, endIndent: 0),
                itemBuilder: (context, i) {
                  final row = rows[i];
                  return TopicTreeRow(key: ValueKey(row.node.fullPath), node: row.node, depth: row.depth, onToggle: () => widget.controller.toggleExpand(row.node));
                },
              );
      },
    );
  }
}
