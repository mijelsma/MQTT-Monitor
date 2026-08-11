import 'dart:convert';

import '../../models/broker_entry.dart';

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

      // Ensure IDs are unique and decode the profile.
      final broker = BrokerEntry.fromJson(json);
      if (!ids.add(broker.id)) {
        throw FormatException('Broker profile IDs must be unique. Duplicate ID at profile ${index + 1}.');
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
}
