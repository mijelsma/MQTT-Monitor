import 'dart:async';

import '../../../core/ui/repositories/ui_preferences_repository.dart';
import '../../../core/ui/repositories/workspace_layout_repository.dart';
import '../../../core/ui/models/sidebar_panel_default_model.dart';
import '../../../shared/controllers/workspace_panel_controller.dart';

enum PayloadViewMode { text, bytes }

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

  PayloadViewMode _payloadViewMode = PayloadViewMode.text;

  /// Session-only payload display mode. This is deliberately not persisted.
  PayloadViewMode get payloadViewMode => _payloadViewMode;

  void setPayloadViewMode(PayloadViewMode value) {
    if (_payloadViewMode == value) return;
    _payloadViewMode = value;
    notifyListeners();
  }

  static bool _resolveInitialCollapsed(WorkspaceLayoutRepository layout, UiPreferencesRepository preferences, int index) {
    final defaults = [preferences.defaultSidebarDetail, preferences.defaultSidebarHistory, preferences.defaultSidebarPublish, preferences.defaultSidebarShortcuts];
    switch (defaults[index]) {
      case SidebarPanelDefaultModel.collapsed:
        return true;
      case SidebarPanelDefaultModel.expanded:
        return false;
      case SidebarPanelDefaultModel.lastStatus:
        return layout.collapsed[index];
    }
  }
}
