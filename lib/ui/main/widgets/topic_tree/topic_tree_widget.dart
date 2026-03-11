import 'package:flutter/material.dart';

import '../../../../theme/app_tokens/app_tokens.dart';
import 'topic_tree_controller.dart';
import 'topic_tree_empty_state.dart';
import 'topic_tree_row.dart';

/// The main MQTT topic tree panel.
///
/// Responsibilities:
/// - Owns a [TopicTreeController] that ingests messages from the MQTT stream.
/// - Renders a compact filter bar at the top.
/// - Renders a [ListView] of [TopicTreeRow] items; each row updates
///   independently via its own [ValueNotifier] and [AnimationController].
/// - Shows an empty state when no topics have been received yet, or when the
///   current filter matches nothing.
class TopicTreeWidget extends StatefulWidget {
  const TopicTreeWidget({super.key});

  @override
  State<TopicTreeWidget> createState() => _TopicTreeWidgetState();
}

class _TopicTreeWidgetState extends State<TopicTreeWidget> {
  late final TopicTreeController _controller;
  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TopicTreeController();
    _filterController.addListener(() => _controller.setFilter(_filterController.text));
  }

  @override
  void dispose() {
    _filterController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final rows = _controller.buildFlatList();
        final tokens = context.tokens;
        final hasFilter = _controller.filter.isNotEmpty;

        return Column(
          children: [
            // Tree body
            Expanded(
              child: rows.isEmpty
                  ? TopicTreeEmptyState(hasFilter: hasFilter)
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: rows.length,
                      separatorBuilder: (_, i) => Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: tokens.border,
                        // Indent the divider to visually align with the text.
                        indent: 10.0 + rows[i].depth * 18.0 + 27,
                        endIndent: 0,
                      ),
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        return TopicTreeRow(
                          // Stable key: preserves animation state across
                          // list rebuilds caused by filter/expand changes.
                          key: ValueKey(row.node.fullPath),
                          node: row.node,
                          depth: row.depth,
                          onToggle: () => _controller.toggleExpand(row.node),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
