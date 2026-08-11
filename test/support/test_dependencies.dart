import 'package:mqtt_monitor/core/broker/broker_repository.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/storage/shared_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds isolated application dependencies for persistence-aware tests.
class TestDependencies {
  /// Creates a test dependency bundle from initialized owners.
  const TestDependencies({
    required this.state,
    required this.brokers,
    required this.preferences,
  });

  final AppStateManager state;
  final BrokerRepository brokers;
  final SharedPreferencesStore preferences;

  /// Resets mock preferences and initializes app and broker state.
  static Future<TestDependencies> create() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferencesStore.load();
    final state = AppStateManager.instance;
    await state.initialize(preferences: preferences);
    await state.resetAll();
    final brokers = BrokerRepository(preferences);
    await brokers.initialize();
    return TestDependencies(
      state: state,
      brokers: brokers,
      preferences: preferences,
    );
  }
}
