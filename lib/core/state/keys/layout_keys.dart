import '../persist.dart';
import '../state_key.dart';
import 'settings_keys.dart';

/// Defines the keys used in the app state for managing monitor view layout.
///
/// All keys are persisted conditionally — only when the user has
/// "Persist Layout" enabled in Settings › UI.
abstract final class LayoutKeys {
  static final _gate = Persist.when(SettingsKeys.persistLayout);

  // Left/right topic-tree ↔ detail-sidebar split position (0.0–1.0).
  static final monitorSplitRatio = StateKey.decimal('layout.monitorSplitRatio', defaultValue: 0.5, persist: _gate);

  // Sidebar panel collapsed states.
  static final sidebarDetailCollapsed = StateKey.boolean('layout.sidebarDetailCollapsed', defaultValue: false, persist: _gate);
  static final sidebarHistoryCollapsed = StateKey.boolean('layout.sidebarHistoryCollapsed', defaultValue: true, persist: _gate);
  static final sidebarPublishCollapsed = StateKey.boolean('layout.sidebarPublishCollapsed', defaultValue: false, persist: _gate);
  static final sidebarShortcutsCollapsed = StateKey.boolean('layout.sidebarShortcutsCollapsed', defaultValue: true, persist: _gate);

  static final List<StateKey> all = [monitorSplitRatio, sidebarDetailCollapsed, sidebarHistoryCollapsed, sidebarPublishCollapsed, sidebarShortcutsCollapsed];
}
