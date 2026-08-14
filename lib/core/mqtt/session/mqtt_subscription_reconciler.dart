import '../../../core/broker/models/subscription_entry_model.dart';
import '../interfaces/mqtt_protocol_adapter_interface.dart';

/// Reconciles broker-owned desired subscriptions with one live adapter.
class MqttSubscriptionReconciler {
  MqttProtocolAdapterInterface? _adapter;
  Map<String, SubscriptionEntryModel> _desired = const {};
  final Map<String, SubscriptionEntryModel> _applied = {};
  bool _connected = false;

  /// Attaches a fresh adapter generation and its initial desired state.
  void attach(MqttProtocolAdapterInterface adapter, Iterable<SubscriptionEntryModel> subscriptions) {
    _adapter = adapter;
    _desired = _byId(subscriptions);
    _applied.clear();
    _connected = false;
  }

  /// Updates desired state without replacing the active MQTT session.
  void update(Iterable<SubscriptionEntryModel> subscriptions) {
    _desired = _byId(subscriptions);
    if (_connected) _reconcile();
  }

  /// Restores every desired filter after an initial or automatic connection.
  void onConnected() {
    final adapter = _adapter;
    if (adapter == null || !adapter.isConnected) return;
    if (!_connected) _applied.clear();
    _connected = true;
    _reconcile();
  }

  /// Marks package subscriptions unavailable until the next connection.
  void onDisconnected() {
    _connected = false;
    _applied.clear();
  }

  /// Releases all state owned by the detached adapter generation.
  void detach() {
    _adapter = null;
    _desired = const {};
    _applied.clear();
    _connected = false;
  }

  void _reconcile() {
    final adapter = _adapter;
    if (adapter == null || !adapter.isConnected) return;

    for (final entry in _applied.entries.toList(growable: false)) {
      final desired = _desired[entry.key];
      if (desired != null && _sameProtocolState(entry.value, desired)) {
        continue;
      }
      if (adapter.unsubscribe(entry.value.topic)) {
        _applied.remove(entry.key);
      }
    }

    for (final entry in _desired.entries) {
      if (_applied.containsKey(entry.key)) continue;
      if (adapter.subscribe(entry.value.topic, qos: entry.value.qos)) {
        _applied[entry.key] = entry.value;
      }
    }
  }

  Map<String, SubscriptionEntryModel> _byId(Iterable<SubscriptionEntryModel> subscriptions) {
    return Map.unmodifiable({for (final subscription in subscriptions) subscription.id: subscription});
  }

  bool _sameProtocolState(SubscriptionEntryModel left, SubscriptionEntryModel right) {
    return left.topic == right.topic && left.qos == right.qos;
  }
}
