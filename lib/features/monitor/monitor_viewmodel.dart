import 'package:flutter/foundation.dart';

import '../../core/broker/broker_repository.dart';
import '../../core/broker/broker_repository_failure.dart';
import '../../core/mqtt/connection_status.dart';
import '../../core/mqtt/publish_result.dart';
import '../../core/mqtt/session/mqtt_session_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/environment_variable.dart';
import '../../models/mqtt_protocol_version.dart';
import '../../models/publish_shortcut.dart';

final _variablePlaceholderPattern = RegExp(r'\$\{([^}]+)\}');

/// Owns monitor connection, broker, publish, shortcut, and variable commands.
class MonitorViewModel extends ChangeNotifier {
  MonitorViewModel({
    required MqttSessionController mqttSession,
    required AppStateManager state,
    required BrokerRepository brokerRepository,
  }) : _mqtt = mqttSession,
       _state = state,
       _brokers = brokerRepository {
    _state.load(SettingsKeys.environmentVariables);
    _state.load(SettingsKeys.environmentVariableValues);
    _state.addListener(_onStateChanged);
    _mqtt.addListener(_onStateChanged);
    _brokers.addListener(_onStateChanged);
  }

  final MqttSessionController _mqtt;
  final AppStateManager _state;
  final BrokerRepository _brokers;

  ConnectionStatus get connectionStatus => _mqtt.connectionStatus;
  String? get connectionError => _mqtt.connectionError;
  String? get connectionErrorDetail => _mqtt.connectionErrorDetail;
  int get messageCount => _mqtt.messageCount;
  int get messageRate => _mqtt.messageRate;
  bool get showStatusBar => _state.read(SettingsKeys.showStatusBar);
  List<BrokerEntry> get brokers => _brokers.brokers;
  BrokerRepositoryFailure? get brokerFailure => _brokers.failure;
  MqttProtocolVersion? get activeProtocol => _mqtt.activeProtocol;
  BrokerEntry? get activeBroker => _brokers.activeBroker;
  bool get isConnected => connectionStatus == ConnectionStatus.connected;

  Future<void> selectBroker(String id) async => _brokers.select(id);
  Future<void> retryBrokerLoad() => _brokers.retry();
  void disconnect() => _mqtt.disconnect();
  void reconnect() => _mqtt.reconnect();

  Future<PublishResult>? publish(
    String topic,
    String payload, {
    int qos = 0,
    bool retain = false,
  }) => _mqtt.publish(topic, payload, qos: qos, retain: retain);

  bool clearRetainedMessage(String topic) =>
      _mqtt.publish(topic, '', qos: 0, retain: true) != null;

  List<PublishShortcut> get availableShortcuts {
    final brokerId = activeBroker?.id;
    return _state
        .read(SettingsKeys.shortcuts)
        .where(
          (shortcut) =>
              shortcut.isGlobal ||
              (brokerId != null && shortcut.brokerIds.contains(brokerId)),
        )
        .toList();
  }

  List<EnvironmentVariable> get environmentVariables {
    final brokerId = activeBroker?.id;
    return _state
        .read(SettingsKeys.environmentVariables)
        .where(
          (variable) =>
              variable.isGlobal ||
              (brokerId != null && variable.brokerIds.contains(brokerId)),
        )
        .toList();
  }

  Map<String, String> get variableValues =>
      _state.read(SettingsKeys.environmentVariableValues);

  void setVariableValue(String name, String value) {
    final updated = Map<String, String>.from(variableValues)..[name] = value;
    _state.write(SettingsKeys.environmentVariableValues, updated);
  }

  String resolveShortcutTopic(String topic) => topic.replaceAllMapped(
    _variablePlaceholderPattern,
    (match) => variableValues[match.group(1)!] ?? match.group(0)!,
  );

  Future<void> addBroker(BrokerEntry entry) async => _brokers.add(entry);
  Future<void> updateBroker(BrokerEntry updated) async =>
      _brokers.update(updated);
  Future<void> deleteBroker(String id) async => _brokers.delete(id);

  void _onStateChanged() => notifyListeners();

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _mqtt.removeListener(_onStateChanged);
    _brokers.removeListener(_onStateChanged);
    super.dispose();
  }
}
