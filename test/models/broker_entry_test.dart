import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/mqtt_protocol_version.dart';

void main() {
  test('persists the per-broker MQTT protocol version', () {
    const broker = BrokerEntry(
      id: 'broker-1',
      name: 'MQTT 5 broker',
      host: 'broker.example.com',
      protocolVersion: MqttProtocolVersion.v5,
    );

    final restored = BrokerEntry.fromJson(broker.toJson());

    expect(restored.protocolVersion, MqttProtocolVersion.v5);
  });

  test('old profiles default to MQTT 3.1.1', () {
    final restored = BrokerEntry.fromJson({
      'id': 'legacy',
      'name': 'Legacy broker',
      'host': 'localhost',
    });

    expect(restored.protocolVersion, MqttProtocolVersion.v311);
  });
}
