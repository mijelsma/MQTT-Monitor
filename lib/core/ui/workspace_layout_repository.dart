import 'package:flutter/foundation.dart';

import '../storage/preferences_store.dart';

/// Owns monitor workspace layout and its optional persistence behavior.
class WorkspaceLayoutRepository extends ChangeNotifier {
  WorkspaceLayoutRepository(this._store, {required bool persistLayout}) : _persistLayout = persistLayout;

  static const String schemaVersionKey = 'workspaceLayout.schemaVersion';
  static const int currentSchemaVersion = 1;
  static const String monitorSplitRatioKey = 'layout.monitorSplitRatio';
  static const String sidebarDetailCollapsedKey = 'layout.sidebarDetailCollapsed';
  static const String sidebarHistoryCollapsedKey = 'layout.sidebarHistoryCollapsed';
  static const String sidebarPublishCollapsedKey = 'layout.sidebarPublishCollapsed';
  static const String sidebarShortcutsCollapsedKey = 'layout.sidebarShortcutsCollapsed';
  static const double defaultMonitorSplitRatio = 0.5;
  static const List<bool> defaultCollapsed = [false, true, false, true];

  final PreferencesStore _store;
  bool _persistLayout;
  double _monitorSplitRatio = defaultMonitorSplitRatio;
  List<bool> _collapsed = List.of(defaultCollapsed);

  bool get persistLayout => _persistLayout;
  double get monitorSplitRatio => _monitorSplitRatio;
  List<bool> get collapsed => List.unmodifiable(_collapsed);

  Future<void> initialize() async {
    await _ensureSchema();
    if (!_persistLayout) {
      _monitorSplitRatio = defaultMonitorSplitRatio;
      _collapsed = List.of(defaultCollapsed);
      notifyListeners();
      return;
    }

    final split = _store.get(monitorSplitRatioKey);
    _monitorSplitRatio = split is num && split >= 0.25 && split <= 0.75 ? split.toDouble() : defaultMonitorSplitRatio;
    final keys = [sidebarDetailCollapsedKey, sidebarHistoryCollapsedKey, sidebarPublishCollapsedKey, sidebarShortcutsCollapsedKey];
    _collapsed = [for (var index = 0; index < keys.length; index++) _store.get(keys[index]) is bool ? _store.get(keys[index])! as bool : defaultCollapsed[index]];
    notifyListeners();
  }

  void setPersistenceEnabled(bool value) {
    _persistLayout = value;
  }

  Future<void> setMonitorSplitRatio(double value) async {
    final next = value.clamp(0.25, 0.75).toDouble();
    if (_monitorSplitRatio == next) return;
    _monitorSplitRatio = next;
    notifyListeners();
    if (_persistLayout) await _store.setDouble(monitorSplitRatioKey, next);
  }

  Future<void> setCollapsed(int index, bool value) async {
    RangeError.checkValidIndex(index, _collapsed, 'index');
    if (_collapsed[index] == value) return;
    _collapsed = [..._collapsed]..[index] = value;
    notifyListeners();
    if (!_persistLayout) return;
    final keys = [sidebarDetailCollapsedKey, sidebarHistoryCollapsedKey, sidebarPublishCollapsedKey, sidebarShortcutsCollapsedKey];
    await _store.setBool(keys[index], value);
  }

  Future<void> resetToDefaults() async {
    await _store.remove(monitorSplitRatioKey);
    await _store.remove(sidebarDetailCollapsedKey);
    await _store.remove(sidebarHistoryCollapsedKey);
    await _store.remove(sidebarPublishCollapsedKey);
    await _store.remove(sidebarShortcutsCollapsedKey);
    _monitorSplitRatio = defaultMonitorSplitRatio;
    _collapsed = List.of(defaultCollapsed);
    notifyListeners();
  }

  Future<void> _ensureSchema() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      await _store.setInt(schemaVersionKey, currentSchemaVersion);
    } else if (version != currentSchemaVersion) {
      throw StateError('Unsupported workspace layout schema version: $version');
    }
  }
}
