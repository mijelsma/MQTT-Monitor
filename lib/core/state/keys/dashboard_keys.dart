import '../../../models/dashboard_layout.dart';
import '../state_key.dart';

/// Defines the keys used in the app state for managing dashboard layouts.
abstract final class DashboardKeys {
  static final layouts = StateKey.fromJson<List<DashboardLayout>>('dashboard.layouts', defaultValue: const [], toJson: (list) => list.map((e) => e.toJson()).toList(), fromJson: (raw) => (raw as List).map((e) => DashboardLayout.fromJson(e as Map<String, dynamic>)).toList());

  /// Tracks which layout is active for a given broker. Stored per broker.
  static StateKey<String?> activeLayoutForBroker(String brokerId) => StateKey.nullableString('dashboard.activeLayout.$brokerId');

  static final List<StateKey> all = [layouts];
}
