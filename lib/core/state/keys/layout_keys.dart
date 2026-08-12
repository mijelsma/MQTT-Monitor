import '../state_key.dart';

/// Defines the keys used in the app state for managing monitor view layout.
///
/// Persistence is gated by [AppStateManager]'s UI-preference integration.
abstract final class LayoutKeys {
  // Left/right topic-tree ↔ detail-sidebar split position (0.0–1.0).
  static final monitorSplitRatio = StateKey.decimal('layout.monitorSplitRatio', defaultValue: 0.5);

  // Sidebar panel collapsed states.
  static final sidebarDetailCollapsed = StateKey.boolean('layout.sidebarDetailCollapsed', defaultValue: false);
  static final sidebarHistoryCollapsed = StateKey.boolean('layout.sidebarHistoryCollapsed', defaultValue: true);
  static final sidebarPublishCollapsed = StateKey.boolean('layout.sidebarPublishCollapsed', defaultValue: false);
  static final sidebarShortcutsCollapsed = StateKey.boolean('layout.sidebarShortcutsCollapsed', defaultValue: true);

  static final List<StateKey> all = [monitorSplitRatio, sidebarDetailCollapsed, sidebarHistoryCollapsed, sidebarPublishCollapsed, sidebarShortcutsCollapsed];
}
