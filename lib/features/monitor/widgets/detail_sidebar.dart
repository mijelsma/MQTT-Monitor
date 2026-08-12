import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/keys/settings_keys.dart';
import '../../../generated/l10n.dart';
import '../../../models/topic_node_value.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/workspace_panel_layout.dart';
import '../../../shared/widgets/workspace_panel_section.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../detail_sidebar_controller.dart';
import '../monitor_workspace_controller.dart';
import 'history_panel.dart';
import 'message_detail_panel.dart';
import 'publish_panel.dart';
import 'shortcuts_panel.dart';

/// The right-hand sidebar showing detail, history, publishing, and shortcuts.
class DetailSidebar extends StatefulWidget {
  /// Creates the detail sidebar.
  const DetailSidebar({super.key});

  @override
  State<DetailSidebar> createState() => _DetailSidebarState();
}

class _DetailSidebarState extends State<DetailSidebar> {
  TopicNodeValue? _selectedHistoryValue;
  String? _lastTopicPath;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.watch<MonitorWorkspaceController>();
    final panelController = context.read<DetailSidebarController>();
    final animationsEnabled = context.select<AppStateManager, bool>(
      (state) => state.read(SettingsKeys.sidebarAnimationsEnabled),
    );
    final animationSpeed = context.select<AppStateManager, int>(
      (state) => state.read(SettingsKeys.sidebarAnimationSpeed),
    );
    final selected = workspace.selectedNode;

    if (selected?.fullPath != _lastTopicPath) {
      _lastTopicPath = selected?.fullPath;
      _selectedHistoryValue = null;
    }

    final strings = S.of(context);
    final detailContent = selected != null
        ? MessageDetailPanel(
            key: ValueKey(selected.fullPath),
            node: selected,
            selectedHistory: _selectedHistoryValue,
            onClearSelection: () {
              setState(() => _selectedHistoryValue = null);
            },
          )
        : const _NoSelection();
    final historyContent = selected != null
        ? HistoryPanel(
            key: ValueKey('history_${selected.fullPath}'),
            node: selected,
            selectedValue: _selectedHistoryValue,
            onSelect: (value) {
              setState(() => _selectedHistoryValue = value);
            },
          )
        : const _NoSelection();

    return Container(
      key: const Key('detail-sidebar-layout'),
      color: tokens.bg,
      child: WorkspacePanelLayout(
        controller: panelController,
        animationDuration: workspacePanelAnimationDurationForSpeed(
          animationSpeed,
        ),
        animationsEnabled: animationsEnabled,
        dividerSemanticLabelBuilder: (first, second) =>
            _dividerSemanticLabel(strings, first, second),
        sections: [
          WorkspacePanelSection(
            title: strings.sidebarMessageDetail,
            icon: Icons.info_outline_rounded,
            body: detailContent,
            toggleKey: const Key('detail-section-toggle'),
            contentKey: const Key('detail-content-clip'),
          ),
          WorkspacePanelSection(
            title: strings.sidebarHistory,
            icon: Icons.history_rounded,
            body: historyContent,
            toggleKey: const Key('history-section-toggle'),
            contentKey: const Key('history-content-clip'),
          ),
          WorkspacePanelSection(
            title: strings.sidebarPublish,
            icon: Icons.send_rounded,
            body: const PublishPanel(),
            toggleKey: const Key('publish-section-toggle'),
            contentKey: const Key('publish-content-clip'),
          ),
          WorkspacePanelSection(
            title: strings.sidebarShortcuts,
            icon: Icons.bolt_rounded,
            body: const ShortcutsPanel(),
            toggleKey: const Key('shortcuts-section-toggle'),
            contentKey: const Key('shortcuts-content-clip'),
          ),
        ],
      ),
    );
  }
}

String _dividerSemanticLabel(S strings, int first, int second) {
  return switch ((first, second)) {
    (0, 1) => strings.sidebarResizeDetailHistory,
    (0, 2) => strings.sidebarResizeDetailPublish,
    (0, 3) => strings.sidebarResizeDetailShortcuts,
    (1, 2) => strings.sidebarResizeHistoryPublish,
    (1, 3) => strings.sidebarResizeHistoryShortcuts,
    (2, 3) => strings.sidebarResizePublishShortcuts,
    _ => throw StateError('Unsupported sidebar divider pair: $first, $second'),
  };
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return UiEmptyState.compact(
      icon: Icons.touch_app_rounded,
      title: S.of(context).sidebarNoSelectionTitle,
      message: S.of(context).sidebarNoSelectionSubtitle,
    );
  }
}
