import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/models/broker_entry.dart';
import 'package:mqtt_monitor/models/client_certificate_config.dart';
import 'package:mqtt_monitor/models/mqtt_protocol_version.dart';

void main() {
  test('persists the per-broker MQTT protocol version', () {
    const broker = BrokerEntry(id: 'broker-1', name: 'MQTT 5 broker', host: 'broker.example.com', protocolVersion: MqttProtocolVersion.v5);

    final restored = BrokerEntry.fromJson(broker.toJson());

    expect(restored.protocolVersion, MqttProtocolVersion.v5);
  });

  test('profiles without explicit transport defaults decode safely', () {
    final restored = BrokerEntry.fromJson({'id': 'legacy', 'name': 'Legacy broker', 'host': 'localhost'});

    expect(restored.protocolVersion, MqttProtocolVersion.v311);
    expect(restored.validateCertificates, isFalse);
  });

  test('persists app-private certificate references', () {
    const broker = BrokerEntry(
      id: 'secure',
      name: 'Secure broker',
      host: 'secure.example.com',
      clientCertificates: ClientCertificateConfig(rootCaPath: '/private/ca.pem', clientPrivateKeyPath: '/private/key.pem', clientCertificatePath: '/private/cert.pem'),
    );

    final json = broker.toJson();
    final restored = BrokerEntry.fromJson(json);

    expect(json.toString(), isNot(contains('BEGIN PRIVATE KEY')));
    expect(restored.clientCertificates.rootCaPath, '/private/ca.pem');
    expect(restored.clientCertificates.clientPrivateKeyPath, '/private/key.pem');
    expect(restored.clientCertificates.clientCertificatePath, '/private/cert.pem');
  });
}
