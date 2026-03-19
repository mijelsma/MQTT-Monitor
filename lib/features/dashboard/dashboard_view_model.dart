import 'package:flutter/foundation.dart';

import '../../core/state/app_state.dart';
import '../../core/state/keys/dashboard_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/dashboard_layout.dart';
import '../../models/environment_variable.dart';

/// ViewModel for the graph dashboard screen.
///
/// Manages dashboard layout selection, environment variables, and will later
/// handle card management and MQTT data feeding.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required AppStateManager state, required this.brokerId}) : _state = state {
    _state.load(DashboardKeys.layouts);
    _state.load(DashboardKeys.activeLayoutForBroker(brokerId));
    _state.load(SettingsKeys.environmentVariables);
    _state.load(SettingsKeys.environmentVariableValues);
    _state.addListener(_onStateChanged);
  }

  final AppStateManager _state;
  final String brokerId;

  void _onStateChanged() => notifyListeners();

  /// Returns all layouts visible to this broker (global + broker-scoped).
  List<DashboardLayout> get layouts {
    final all = _state.read(DashboardKeys.layouts);
    return all.where((l) => l.isGlobal || l.brokerIds.contains(brokerId)).toList();
  }

  /// The ID of the currently active layout (or null for the default scratch pad).
  String? get activeLayoutId => _state.read(DashboardKeys.activeLayoutForBroker(brokerId));

  /// The currently active layout, if any.
  DashboardLayout? get activeLayout {
    final id = activeLayoutId;
    if (id == null) return null;
    final all = _state.read(DashboardKeys.layouts);
    return all.where((l) => l.id == id).firstOrNull;
  }

  /// Switches to a different layout.
  Future<void> selectLayout(String layoutId) async {
    await _state.write(DashboardKeys.activeLayoutForBroker(brokerId), layoutId);
    notifyListeners();
  }

  /// Saves the current dashboard as a new layout.
  Future<void> saveLayout({required String title, List<String> brokerIds = const [], int colorIndex = 0}) async {
    final id = 'layout_${DateTime.now().millisecondsSinceEpoch}';
    final layout = DashboardLayout(id: id, title: title, brokerIds: brokerIds, colorIndex: colorIndex);

    final all = List<DashboardLayout>.from(_state.read(DashboardKeys.layouts));
    all.add(layout);
    await _state.write(DashboardKeys.layouts, all);

    // Activate the newly saved layout.
    await _state.write(DashboardKeys.activeLayoutForBroker(brokerId), id);
    notifyListeners();
  }

  /// Clears all cards and deactivates any layout (back to scratch pad).
  Future<void> clearDashboard() async {
    await _state.write(DashboardKeys.activeLayoutForBroker(brokerId), null);
    notifyListeners();
  }

  /// Deletes a layout.
  Future<void> deleteLayout(String layoutId) async {
    final all = List<DashboardLayout>.from(_state.read(DashboardKeys.layouts));
    all.removeWhere((l) => l.id == layoutId);
    await _state.write(DashboardKeys.layouts, all);

    // Clear active if it was the deleted one.
    if (activeLayoutId == layoutId) {
      await _state.write(DashboardKeys.activeLayoutForBroker(brokerId), null);
    }
    notifyListeners();
  }

  /// Updates a layout's metadata (title, color, scope) without changing its cards.
  Future<void> updateLayoutMetadata(DashboardLayout updated) async {
    final all = List<DashboardLayout>.from(_state.read(DashboardKeys.layouts));
    final idx = all.indexWhere((l) => l.id == updated.id);
    if (idx < 0) return;
    all[idx] = updated;
    await _state.write(DashboardKeys.layouts, all);
    notifyListeners();
  }

  /// Returns the list of configured brokers (for scope selection in dialogs).
  List<BrokerEntry> get brokers {
    _state.load(SettingsKeys.brokers);
    return _state.read(SettingsKeys.brokers);
  }

  /// The defined environment variables visible to this broker (global + broker-scoped).
  List<EnvironmentVariable> get environmentVariables {
    final all = _state.read(SettingsKeys.environmentVariables);
    return all.where((v) => v.isGlobal || v.brokerIds.contains(brokerId)).toList();
  }

  /// Current values for each environment variable.
  Map<String, String> get variableValues {
    return _state.read(SettingsKeys.environmentVariableValues);
  }

  /// Sets the value for a single environment variable.
  void setVariableValue(String name, String value) {
    final values = Map<String, String>.from(variableValues);
    values[name] = value;
    _state.write(SettingsKeys.environmentVariableValues, values);
    notifyListeners();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }
}
