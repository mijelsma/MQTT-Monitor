import '../../../core/broker/models/broker_entry_model.dart';

/// Captures only broker fields that require an MQTT session replacement.
class MqttSessionTarget {
  /// Creates a connection target from [broker].
  MqttSessionTarget(this.broker) : _certificateJson = broker.clientCertificates.toJson();

  final BrokerEntryModel broker;
  final Map<String, dynamic> _certificateJson;

  /// Compares only inputs that require replacing the protocol client.
  @override
  bool operator ==(Object other) {
    if (other is! MqttSessionTarget) return false;
    final a = broker;
    final b = other.broker;
    return a.id == b.id &&
        a.host == b.host &&
        a.port == b.port &&
        a.protocolVersion == b.protocolVersion &&
        a.useSSL == b.useSSL &&
        a.validateCertificates == b.validateCertificates &&
        a.username == b.username &&
        a.password == b.password &&
        a.clientId == b.clientId &&
        a.randomClientIdSuffix == b.randomClientIdSuffix &&
        _mapsEqual(_certificateJson, other._certificateJson);
  }

  /// Produces a stable hash for quick collection use.
  @override
  int get hashCode => Object.hash(broker.id, broker.host, broker.port, broker.protocolVersion, broker.useSSL, broker.validateCertificates, broker.username, broker.password, broker.clientId, broker.randomClientIdSuffix, Object.hashAll(_certificateJson.entries.map((entry) => Object.hash(entry.key, entry.value))));

  /// Compares two flat JSON maps.
  static bool _mapsEqual(Map<String, dynamic> left, Map<String, dynamic> right) {
    if (left.length != right.length) return false;
    return left.entries.every((entry) => right[entry.key] == entry.value);
  }
}
