import 'dart:async';

import '../../core/ui/ui_preferences_repository.dart';
import '../../core/ui/workspace_layout_repository.dart';
import '../../models/sidebar_panel_default.dart';
import '../../shared/widgets/workspace_panel_controller.dart';

/// Owns the detail sidebar's collapse state and persisted layout mapping.
class DetailSidebarController extends WorkspacePanelController {
  /// Creates sidebar state from the configured startup behavior.
  DetailSidebarController(WorkspaceLayoutRepository layout, UiPreferencesRepository preferences)
    : super(
        initialCollapsed: [for (var index = 0; index < WorkspaceLayoutRepository.defaultCollapsed.length; index++) _resolveInitialCollapsed(layout, preferences, index)],
        onCollapsedChanged: (index, collapsed) {
          unawaited(layout.setCollapsed(index, collapsed));
        },
      );

  static bool _resolveInitialCollapsed(WorkspaceLayoutRepository layout, UiPreferencesRepository preferences, int index) {
    final defaults = [preferences.defaultSidebarDetail, preferences.defaultSidebarHistory, preferences.defaultSidebarPublish, preferences.defaultSidebarShortcuts];
    switch (defaults[index]) {
      case SidebarPanelDefault.collapsed:
        return true;
      case SidebarPanelDefault.expanded:
        return false;
      case SidebarPanelDefault.lastStatus:
        return layout.collapsed[index];
    }
  }
}
