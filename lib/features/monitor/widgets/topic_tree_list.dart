import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/flat_tree_row.dart';
import '../../../models/topic_node.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import 'topic_tree_row.dart';

const double _minimumTopicTreeRowHeight = 37.0;
const double _topicTreeDividerHeight = 0.5;
const double topicTreeItemExtent =
    _minimumTopicTreeRowHeight + _topicTreeDividerHeight;

/// Lazily renders the cached, flattened topic rows with a fixed item extent.
class TopicTreeList extends StatelessWidget {
  const TopicTreeList({
    super.key,
    required this.rows,
    required this.selectedNode,
    required this.onToggle,
    required this.onSelect,
  });

  final List<FlatTreeRow> rows;
  final TopicTreeNode? selectedNode;
  final ValueChanged<TopicTreeNode> onToggle;
  final ValueChanged<TopicTreeNode> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final rowHeight = math.max(
      _minimumTopicTreeRowHeight,
      18.0 + MediaQuery.textScalerOf(context).scale(13.0) * 1.3,
    );

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: rows.length,
      itemExtent: rowHeight + _topicTreeDividerHeight,
      itemBuilder: (context, index) {
        final row = rows[index];
        return KeyedSubtree(
          key: ValueKey(row.node.fullPath),
          child: Column(
            children: [
              SizedBox(
                height: rowHeight,
                child: TopicTreeRow(
                  node: row.node,
                  depth: row.depth,
                  metrics: row.metrics,
                  selected: selectedNode?.fullPath == row.node.fullPath,
                  onToggle: () => onToggle(row.node),
                  onSelect: () => onSelect(row.node),
                ),
              ),
              if (index < rows.length - 1)
                Divider(
                  height: _topicTreeDividerHeight,
                  thickness: _topicTreeDividerHeight,
                  color: tokens.border,
                  indent: 37.0 + row.depth * 18.0,
                  endIndent: 0,
                )
              else
                const SizedBox(height: _topicTreeDividerHeight),
            ],
          ),
        );
      },
    );
  }
}
