import 'dart:convert';

import '../../models/broker_entry.dart';
import '../history/history_policy_rules.dart';
import '../mqtt/mqtt_topic_filter.dart';

/// Encodes and strictly validates the persisted broker-profile collection.
class BrokerProfileCodec {
  /// Creates a stateless broker-profile codec.
  const BrokerProfileCodec();

  /// Decodes [raw] into validated profiles or throws a [FormatException].
  List<BrokerEntry> decode(Object? raw) {
    // If there is no raw data, return an empty list of brokers.
    if (raw == null) return const [];

    // Ensure the raw data is a JSON string.
    if (raw is! String) {
      throw const FormatException('Broker profiles must be stored as JSON text.');
    }

    // Decode the JSON string into a Dart object.
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Broker profile data must contain a JSON list.');
    }

    // Decode each broker profile
    final brokers = <BrokerEntry>[];
    final ids = <String>{};
    final credentialReferences = <String>{};
    final certificatePaths = <String>{};
    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];

      // Ensure each item is a JSON object.
      if (item is! Map) {
        throw FormatException('Broker profile ${index + 1} is not a JSON object.');
      }

      // Validate required fields and convert to a BrokerEntry.
      final json = Map<String, dynamic>.from(item);
      _validateRequiredString(json, 'id', index);
      _validateRequiredString(json, 'name', index);
      _validateRequiredString(json, 'host', index);
      _rejectPlaintextPassword(json, index);
      _validateOptionalString(json, 'passwordReference', index);
      _validateSubscriptions(json, index);

      // Ensure IDs are unique and decode the profile.
      final broker = BrokerEntry.fromJson(json);
      if (!ids.add(broker.id)) {
        throw FormatException('Broker profile IDs must be unique. Duplicate ID at profile ${index + 1}.');
      }
      final credentialReference = broker.passwordReference;
      if (credentialReference != null && !credentialReferences.add(credentialReference)) {
        throw FormatException('Broker credential references must be unique. Duplicate reference at profile ${index + 1}.');
      }
      for (final filePath in _certificatePaths(broker)) {
        if (!certificatePaths.add(filePath)) {
          throw FormatException('Broker certificate paths must be unique. Duplicate path at profile ${index + 1}.');
        }
      }

      // Add the validated profile to the list.
      brokers.add(broker);
    }
    return List.unmodifiable(brokers);
  }

  /// Encodes [brokers] as JSON and verifies the result can be decoded.
  String encode(Iterable<BrokerEntry> brokers) {
    // Encode the list of brokers to JSON.
    final encoded = jsonEncode(brokers.map((broker) => broker.toJson()).toList(growable: false));

    // Verify that the encoded JSON can be decoded back into a valid list of brokers.
    decode(encoded);

    // Return the encoded JSON string.
    return encoded;
  }

  /// Ensures a required JSON [key] contains a non-empty string.
  void _validateRequiredString(Map<String, dynamic> json, String key, int index) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Broker profile ${index + 1} has an invalid $key.');
    }
  }

  /// Rejects profile payloads that contain an unsupported plaintext password.
  void _rejectPlaintextPassword(Map<String, dynamic> json, int index) {
    if (json.containsKey('password')) {
      throw FormatException('Broker profile ${index + 1} contains an unsupported plaintext password.');
    }
  }

  /// Validates an optional string [key] when it is present.
  void _validateOptionalString(Map<String, dynamic> json, String key, int index) {
    final value = json[key];
    if (value != null && (value is! String || value.trim().isEmpty)) {
      throw FormatException('Broker profile ${index + 1} has an invalid $key.');
    }
  }

  /// Validates the complete current subscription representation.
  void _validateSubscriptions(Map<String, dynamic> brokerJson, int brokerIndex) {
    final raw = brokerJson['subscriptions'];
    if (raw is! List) {
      throw FormatException('Broker profile ${brokerIndex + 1} has invalid subscriptions.');
    }
    final ids = <String>{};
    final filters = <String>{};
    for (var index = 0; index < raw.length; index++) {
      final value = raw[index];
      if (value is! Map) {
        throw FormatException('Subscription ${index + 1} in broker profile ${brokerIndex + 1} is not a JSON object.');
      }
      final json = Map<String, dynamic>.from(value);
      final id = json['id'];
      if (id is! String || id.trim().isEmpty || !ids.add(id)) {
        throw FormatException('Subscription ${index + 1} in broker profile ${brokerIndex + 1} has an invalid or duplicate ID.');
      }
      final topic = json['topic'];
      if (topic is! String || MqttTopicFilter.validate(topic) != null) {
        throw FormatException('Subscription ${index + 1} in broker profile ${brokerIndex + 1} has an invalid topic filter.');
      }
      if (!filters.add(topic)) {
        throw FormatException('Broker profile ${brokerIndex + 1} contains duplicate topic filters.');
      }
      final qos = json['qos'];
      if (qos is! int || qos < 0 || qos > 2) {
        throw FormatException('Subscription ${index + 1} in broker profile ${brokerIndex + 1} has an invalid QoS.');
      }
      _validateOptionalString(json, 'name', brokerIndex);
      final history = json['history'];
      if (history is! Map) {
        throw FormatException('Subscription ${index + 1} in broker profile ${brokerIndex + 1} has no history policy.');
      }
      final policy = Map<String, dynamic>.from(history);
      if (policy['enabled'] is! bool) {
        throw FormatException('Subscription ${index + 1} in broker profile ${brokerIndex + 1} has an invalid history state.');
      }
      final retention = policy['retention'];
      if (retention is! int || !HistoryPolicyRules.isValidRetention(retention, maximum: HistoryPolicyRules.maximumMaximumRetention)) {
        throw FormatException('Subscription ${index + 1} in broker profile ${brokerIndex + 1} has invalid history retention.');
      }
    }
  }

  /// Returns every non-null certificate path referenced by [broker].
  Iterable<String> _certificatePaths(BrokerEntry broker) sync* {
    final certificates = broker.clientCertificates;
    if (certificates.rootCaPath != null) yield certificates.rootCaPath!;
    if (certificates.clientPrivateKeyPath != null) {
      yield certificates.clientPrivateKeyPath!;
    }
    if (certificates.clientCertificatePath != null) {
      yield certificates.clientCertificatePath!;
    }
  }
}
