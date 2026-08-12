import 'package:flutter/foundation.dart';

import '../../core/broker/broker_repository.dart';
import '../../core/broker/broker_repository_failure.dart';
import '../../core/mqtt/connection_status.dart';
import '../../core/mqtt/session/mqtt_session_controller.dart';
import '../../core/publishing/publish_command.dart';
import '../../core/publishing/publish_command_result.dart';
import '../../core/publishing/publish_command_service.dart';
import '../../core/publishing/shortcut_repository.dart';
import '../../core/publishing/template_resolution.dart';
import '../../core/publishing/template_resolver.dart';
import '../../core/publishing/variable_repository.dart';
import '../../core/state/app_state.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/environment_variable.dart';
import '../../models/mqtt_protocol_version.dart';
import '../../models/publish_shortcut.dart';

/// Owns monitor connection, broker, publish, shortcut, and variable commands.
class MonitorViewModel extends ChangeNotifier {
  MonitorViewModel({required MqttSessionController mqttSession, required AppStateManager state, required BrokerRepository brokerRepository, required ShortcutRepository shortcutRepository, required VariableRepository variableRepository, required PublishCommandService publisher, required TemplateResolver templateResolver})
    : _mqtt = mqttSession,
      _state = state,
      _brokers = brokerRepository,
      _shortcuts = shortcutRepository,
      _variables = variableRepository,
      _publisher = publisher,
      _templateResolver = templateResolver {
    _state.addListener(_onStateChanged);
    _mqtt.addListener(_onStateChanged);
    _brokers.addListener(_onStateChanged);
    _shortcuts.addListener(_onStateChanged);
    _variables.addListener(_onStateChanged);
  }

  final MqttSessionController _mqtt;
  final AppStateManager _state;
  final BrokerRepository _brokers;
  final ShortcutRepository _shortcuts;
  final VariableRepository _variables;
  final PublishCommandService _publisher;
  final TemplateResolver _templateResolver;

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

  Future<PublishCommandResult> clearRetainedMessage(String topic) => execute(PublishCommand(topicTemplate: topic, payload: '', qos: 0, retain: true));

  List<PublishShortcut> get availableShortcuts {
    final brokerId = activeBroker?.id;
    return _shortcuts.shortcuts.where((shortcut) => shortcut.isGlobal || (brokerId != null && shortcut.brokerIds.contains(brokerId))).toList();
  }

  List<EnvironmentVariable> get environmentVariables {
    final brokerId = activeBroker?.id;
    return _variables.variables.where((variable) => variable.isGlobal || (brokerId != null && variable.brokerIds.contains(brokerId))).toList();
  }

  Map<String, String> get variableValues => _variables.valuesForBroker(activeBroker?.id);

  void setVariableValue(String name, String value) {
    _variables.setValue(name, value);
  }

  TemplateResolution resolveTopic(String topic) => _templateResolver.resolve(topic, variableValues);

  Future<PublishCommandResult> execute(PublishCommand command, {void Function()? onDispatch}) => _publisher.execute(command, variableValues, onDispatch: onDispatch);

  Future<void> addBroker(BrokerEntry entry) async => _brokers.add(entry);
  Future<void> updateBroker(BrokerEntry updated) async => _brokers.update(updated);
  Future<void> deleteBroker(String id) async => _brokers.delete(id);

  void _onStateChanged() => notifyListeners();

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _mqtt.removeListener(_onStateChanged);
    _brokers.removeListener(_onStateChanged);
    _shortcuts.removeListener(_onStateChanged);
    _variables.removeListener(_onStateChanged);
    super.dispose();
  }
}
