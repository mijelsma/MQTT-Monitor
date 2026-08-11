import '../../../models/broker_entry.dart';

/// Captures only broker fields that require an MQTT session replacement.
class MqttSessionTarget {
  /// Creates a connection target from [broker].
  MqttSessionTarget(this.broker) : _certificateJson = broker.clientCertificates.toJson(), _subscriptions = broker.subscriptions.map((subscription) => subscription.toJson()).toList(growable: false);

  final BrokerEntry broker;
  final Map<String, dynamic> _certificateJson;
  final List<Map<String, dynamic>> _subscriptions;

  /// Compares all connection, authentication, TLS, and subscription inputs.
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
        _mapsEqual(_certificateJson, other._certificateJson) &&
        _mapListsEqual(_subscriptions, other._subscriptions);
  }

  /// Produces a stable hash for quick collection use.
  @override
  int get hashCode => Object.hash(
    broker.id,
    broker.host,
    broker.port,
    broker.protocolVersion,
    broker.useSSL,
    broker.validateCertificates,
    broker.username,
    broker.password,
    broker.clientId,
    broker.randomClientIdSuffix,
    Object.hashAll(_certificateJson.entries.map((entry) => Object.hash(entry.key, entry.value))),
    Object.hashAll(_subscriptions.map((value) => Object.hashAll(value.entries.map((entry) => Object.hash(entry.key, entry.value))))),
  );

  /// Compares two flat JSON maps.
  static bool _mapsEqual(Map<String, dynamic> left, Map<String, dynamic> right) {
    if (left.length != right.length) return false;
    return left.entries.every((entry) => right[entry.key] == entry.value);
  }

  /// Compares ordered lists of flat JSON maps.
  static bool _mapListsEqual(List<Map<String, dynamic>> left, List<Map<String, dynamic>> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_mapsEqual(left[index], right[index])) return false;
    }
    return true;
  }
}
