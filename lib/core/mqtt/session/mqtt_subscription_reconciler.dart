import '../../../models/subscription_entry.dart';
import '../mqtt_protocol_adapter.dart';

/// Reconciles broker-owned desired subscriptions with one live adapter.
class MqttSubscriptionReconciler {
  MqttProtocolAdapter? _adapter;
  Map<String, SubscriptionEntry> _desired = const {};
  final Map<String, SubscriptionEntry> _applied = {};
  bool _connected = false;

  /// Attaches a fresh adapter generation and its initial desired state.
  void attach(
    MqttProtocolAdapter adapter,
    Iterable<SubscriptionEntry> subscriptions,
  ) {
    _adapter = adapter;
    _desired = _byId(subscriptions);
    _applied.clear();
    _connected = false;
  }

  /// Updates desired state without replacing the active MQTT session.
  void update(Iterable<SubscriptionEntry> subscriptions) {
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

  Map<String, SubscriptionEntry> _byId(
    Iterable<SubscriptionEntry> subscriptions,
  ) {
    return Map.unmodifiable({
      for (final subscription in subscriptions) subscription.id: subscription,
    });
  }

  bool _sameProtocolState(SubscriptionEntry left, SubscriptionEntry right) {
    return left.topic == right.topic && left.qos == right.qos;
  }
}
