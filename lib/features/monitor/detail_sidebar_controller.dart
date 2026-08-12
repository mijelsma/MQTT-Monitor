import 'dart:async';

import '../../core/state/app_state.dart';
import '../../core/state/keys/layout_keys.dart';
import '../../core/state/state_key.dart';
import '../../core/ui/ui_preferences_repository.dart';
import '../../models/sidebar_panel_default.dart';
import '../../shared/widgets/workspace_panel_controller.dart';

/// Owns the detail sidebar's collapse state and persisted layout mapping.
class DetailSidebarController extends WorkspacePanelController {
  /// Creates sidebar state from the configured startup behavior.
  DetailSidebarController(AppStateManager state, UiPreferencesRepository preferences)
    : super(
        initialCollapsed: [for (var index = 0; index < _layoutKeys.length; index++) _resolveInitialCollapsed(state, preferences, index)],
        onCollapsedChanged: (index, collapsed) {
          unawaited(state.write(_layoutKeys[index], collapsed));
        },
      );

  static final List<StateKey<bool>> _layoutKeys = [LayoutKeys.sidebarDetailCollapsed, LayoutKeys.sidebarHistoryCollapsed, LayoutKeys.sidebarPublishCollapsed, LayoutKeys.sidebarShortcutsCollapsed];

  static bool _resolveInitialCollapsed(AppStateManager state, UiPreferencesRepository preferences, int index) {
    final defaults = [preferences.defaultSidebarDetail, preferences.defaultSidebarHistory, preferences.defaultSidebarPublish, preferences.defaultSidebarShortcuts];
    switch (defaults[index]) {
      case SidebarPanelDefault.collapsed:
        return true;
      case SidebarPanelDefault.expanded:
        return false;
      case SidebarPanelDefault.lastStatus:
        return state.read(_layoutKeys[index]);
    }
  }
}
