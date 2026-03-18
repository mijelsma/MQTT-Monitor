import 'package:flutter/foundation.dart';

import '../../core/state/app_state.dart';
import '../../core/state/keys/dashboard_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/dashboard_layout.dart';

/// ViewModel for the graph dashboard screen.
///
/// Currently manages dashboard layout selection. Card management and MQTT data
/// feeding will be added later.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required AppStateManager state, required this.brokerId}) : _state = state {
    _state.load(DashboardKeys.layouts);
    _state.load(DashboardKeys.activeLayoutForBroker(brokerId));
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

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }
}
