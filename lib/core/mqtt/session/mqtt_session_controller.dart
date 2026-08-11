import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/mqtt_protocol_version.dart';
import '../../../models/startup_connection.dart';
import '../../broker/broker_repository.dart';
import '../../state/app_state.dart';
import '../../state/keys/settings_keys.dart';
import '../adapters/mqtt311/mqtt311_adapter.dart';
import '../adapters/mqtt5/mqtt5_adapter.dart';
import '../connection_status.dart';
import '../mqtt_connection_failure.dart';
import '../mqtt_message.dart';
import '../mqtt_protocol_adapter.dart';
import '../mqtt_protocol_event.dart';
import '../publish_result.dart';
import 'mqtt_connection_intent_store.dart';
import 'mqtt_session_state.dart';
import 'mqtt_session_target.dart';

const _unchanged = Object();

/// Owns active MQTT session intent, transitions, telemetry, and generation safety.
class MqttSessionController extends ChangeNotifier {
  /// Creates the active-session controller from settings and broker ownership.
  MqttSessionController(this._settings, this._brokers, this._intentStore, {MqttProtocolAdapterFactory? adapterFactory})
    : _adapterFactory =
          adapterFactory ??
          ((broker) => switch (broker.protocolVersion) {
            MqttProtocolVersion.v311 => Mqtt311Adapter(broker),
            MqttProtocolVersion.v5 => Mqtt5Adapter(broker),
          }),
      _connectionRequested = _intentStore.connectionRequested;

  final AppStateManager _settings;
  final BrokerRepository _brokers;
  final MqttConnectionIntentStore _intentStore;
  final MqttProtocolAdapterFactory _adapterFactory;
  final StreamController<MQTTMessage> _messages = StreamController<MQTTMessage>.broadcast();

  MqttSessionState _state = const MqttSessionState();
  MqttSessionTarget? _target;
  MqttProtocolAdapter? _adapter;
  StreamSubscription<MqttProtocolEvent>? _eventSubscription;
  StreamSubscription<MQTTMessage>? _messageSubscription;
  Timer? _rateTimer;
  int _generation = 0;
  int _rateCounter = 0;
  int _rateIntervalMs = 0;
  bool _connectionRequested;
  bool _firstSync = true;
  bool _initialized = false;
  bool _disposed = false;

  /// Returns the latest immutable session snapshot.
  MqttSessionState get state => _state;

  /// Returns the current connection status.
  ConnectionStatus get connectionStatus => _state.status;

  /// Returns the current friendly connection or protocol notice.
  String? get connectionError => _state.error;

  /// Returns optional technical detail for the current notice.
  String? get connectionErrorDetail => _state.errorDetail;

  /// Returns the number of messages received by the current session.
  int get messageCount => _state.messageCount;

  /// Returns the sampled current-session message rate.
  int get messageRate => _state.messageRate;

  /// Returns the protocol selected for the current or most recent session.
  MqttProtocolVersion? get activeProtocol => _state.activeProtocol;

  /// Returns decoded messages from the active protocol adapter.
  Stream<MQTTMessage> get messageStream => _messages.stream;

  /// Starts broker reconciliation and rate sampling once.
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _settings.addListener(_onSettingsChanged);
    _brokers.addListener(_onBrokersChanged);
    _startRateTimer();
    _sync();
  }

  /// Publishes through the active protocol adapter when connected.
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false}) {
    return _adapter?.publish(topic, payload, qos: qos, retain: retain);
  }

  /// Subscribes through the active protocol adapter when connected.
  bool subscribe(String topic, {int qos = 0}) => _adapter?.subscribe(topic, qos: qos) ?? false;

  /// Unsubscribes through the active protocol adapter when connected.
  bool unsubscribe(String topic) => _adapter?.unsubscribe(topic) ?? false;

  /// Persists disconnected intent and tears down the current session.
  void disconnect() {
    _connectionRequested = false;
    unawaited(_intentStore.setConnectionRequested(false));
    _target = null;
    _teardown();
  }

  /// Persists connected intent and starts a fresh session for the active broker.
  void reconnect() {
    _connectionRequested = true;
    unawaited(_intentStore.setConnectionRequested(true));
    _sync(force: true);
  }

  /// Reconciles startup behavior when a broker profile changes.
  void _onBrokersChanged() => _sync();

  /// Restarts rate sampling only when its setting changed.
  void _onSettingsChanged() {
    final intervalMs = _settings.read(SettingsKeys.rateIntervalMs);
    if (intervalMs != _rateIntervalMs) _startRateTimer();
  }

  /// Resolves startup intent and applies the active broker target.
  void _sync({bool force = false}) {
    if (_disposed) return;
    final broker = _brokers.activeBroker;
    if (_firstSync) {
      _firstSync = false;
      switch (_settings.read(SettingsKeys.startupConnection)) {
        case StartupConnection.alwaysConnect:
          _connectionRequested = true;
          unawaited(_intentStore.setConnectionRequested(true));
        case StartupConnection.stayDisconnected:
          _connectionRequested = false;
          unawaited(_intentStore.setConnectionRequested(false));
        case StartupConnection.lastStatus:
          break;
      }
    }
    if (broker == null || !_connectionRequested) {
      _target = null;
      _teardown();
      return;
    }
    final target = MqttSessionTarget(broker);
    if (!force && target == _target) return;
    _target = target;
    final generation = ++_generation;
    unawaited(_startSession(target, generation));
  }

  /// Replaces the current adapter and connects [target] for [generation].
  Future<void> _startSession(MqttSessionTarget target, int generation) async {
    await _releaseAdapter();
    if (!_isCurrent(generation, target)) return;
    _resetCounters(status: ConnectionStatus.connecting, protocol: target.broker.protocolVersion);

    final adapter = _adapterFactory(target.broker);
    _adapter = adapter;
    _eventSubscription = adapter.events.listen((event) => _onProtocolEvent(adapter, generation, event));
    _messageSubscription = adapter.messages.listen((message) => _onMessage(adapter, generation, message));
    try {
      await adapter.connect();
      if (!_isCurrentAdapter(adapter, generation)) return;
      if (adapter.isConnected) {
        _emit(status: ConnectionStatus.connected, error: null, detail: null);
      }
    } on MqttConnectionFailure catch (failure) {
      if (_isCurrentAdapter(adapter, generation)) {
        _emit(status: failure.status, error: failure.message, detail: failure.detail);
      }
    } on Object catch (error) {
      if (_isCurrentAdapter(adapter, generation)) {
        _emit(status: ConnectionStatus.error, error: 'The MQTT client could not start the connection.', detail: error.runtimeType.toString());
      }
    }
  }

  /// Applies a lifecycle event only when its adapter generation is current.
  void _onProtocolEvent(MqttProtocolAdapter adapter, int generation, MqttProtocolEvent event) {
    if (!_isCurrentAdapter(adapter, generation)) return;
    switch (event.type) {
      case MqttProtocolEventType.connected:
        _emit(status: ConnectionStatus.connected, error: null, detail: null);
      case MqttProtocolEventType.reconnecting:
        _emit(status: ConnectionStatus.connecting);
      case MqttProtocolEventType.disconnected:
        _emit(status: ConnectionStatus.disconnected, error: event.message, detail: event.detail);
      case MqttProtocolEventType.notice:
        _emit(error: event.message, detail: event.detail);
      case MqttProtocolEventType.failure:
        _emit(status: event.status ?? ConnectionStatus.error, error: event.message, detail: event.detail);
    }
  }

  /// Forwards a current adapter message and updates session telemetry.
  void _onMessage(MqttProtocolAdapter adapter, int generation, MQTTMessage message) {
    if (!_isCurrentAdapter(adapter, generation)) return;
    _messages.add(message);
    _rateCounter++;
    _emit(messageCount: _state.messageCount + 1);
  }

  /// Tears down the current generation and reports a clean disconnected state.
  void _teardown() {
    ++_generation;
    unawaited(_releaseAdapter());
    _resetCounters(status: ConnectionStatus.disconnected, protocol: _state.activeProtocol);
  }

  /// Cancels controller subscriptions before disposing the active adapter.
  Future<void> _releaseAdapter() async {
    final adapter = _adapter;
    _adapter = null;
    await _eventSubscription?.cancel();
    await _messageSubscription?.cancel();
    _eventSubscription = null;
    _messageSubscription = null;
    await adapter?.dispose();
  }

  /// Returns whether [target] still owns the requested [generation].
  bool _isCurrent(int generation, MqttSessionTarget target) {
    return !_disposed && generation == _generation && target == _target && _connectionRequested;
  }

  /// Returns whether [adapter] still owns the requested [generation].
  bool _isCurrentAdapter(MqttProtocolAdapter adapter, int generation) {
    return !_disposed && generation == _generation && identical(adapter, _adapter);
  }

  /// Starts or restarts periodic message-rate sampling.
  void _startRateTimer() {
    final intervalMs = _settings.read(SettingsKeys.rateIntervalMs);
    _rateTimer?.cancel();
    _rateIntervalMs = intervalMs;
    _rateCounter = 0;
    _rateTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_disposed) return;
      final rate = (_rateCounter * 1000 / intervalMs).round();
      _rateCounter = 0;
      _emit(messageRate: rate);
    });
  }

  /// Clears counters while applying a lifecycle [status] and [protocol].
  void _resetCounters({required ConnectionStatus status, required MqttProtocolVersion? protocol}) {
    _rateCounter = 0;
    _emit(status: status, error: null, detail: null, messageCount: 0, messageRate: 0, protocol: protocol);
  }

  /// Replaces selected state fields and notifies only when values changed.
  void _emit({ConnectionStatus? status, Object? error = _unchanged, Object? detail = _unchanged, int? messageCount, int? messageRate, Object? protocol = _unchanged}) {
    final next = MqttSessionState(
      status: status ?? _state.status,
      error: identical(error, _unchanged) ? _state.error : error as String?,
      errorDetail: identical(detail, _unchanged) ? _state.errorDetail : detail as String?,
      messageCount: messageCount ?? _state.messageCount,
      messageRate: messageRate ?? _state.messageRate,
      activeProtocol: identical(protocol, _unchanged) ? _state.activeProtocol : protocol as MqttProtocolVersion?,
    );
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  /// Releases the active session and every controller-owned resource.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    _rateTimer?.cancel();
    _settings.removeListener(_onSettingsChanged);
    _brokers.removeListener(_onBrokersChanged);
    unawaited(_releaseAdapter());
    unawaited(_messages.close());
    super.dispose();
  }
}
