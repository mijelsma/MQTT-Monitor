import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/broker/models/broker_entry_model.dart';
import 'package:mqtt_monitor/core/broker/models/client_certificate_config_model.dart';
import 'package:mqtt_monitor/core/mqtt/models/mqtt_protocol_version_model.dart';

void main() {
  test('persists the per-broker MQTT protocol version', () {
    const broker = BrokerEntryModel(id: 'broker-1', name: 'MQTT 5 broker', host: 'broker.example.com', protocolVersion: MqttProtocolVersionModel.v5);

    final restored = BrokerEntryModel.fromJson(broker.toJson());

    expect(restored.protocolVersion, MqttProtocolVersionModel.v5);
  });

  test('profiles without explicit transport defaults decode safely', () {
    final restored = BrokerEntryModel.fromJson({'id': 'legacy', 'name': 'Legacy broker', 'host': 'localhost'});

    expect(restored.protocolVersion, MqttProtocolVersionModel.v311);
    expect(restored.validateCertificates, isFalse);
  });

  test('persists app-private certificate references', () {
    const broker = BrokerEntryModel(
      id: 'secure',
      name: 'Secure broker',
      host: 'secure.example.com',
      clientCertificates: ClientCertificateConfigModel(rootCaPath: '/private/ca.pem', clientPrivateKeyPath: '/private/key.pem', clientCertificatePath: '/private/cert.pem'),
    );

    final json = broker.toJson();
    final restored = BrokerEntryModel.fromJson(json);

    expect(json.toString(), isNot(contains('BEGIN PRIVATE KEY')));
    expect(restored.clientCertificates.rootCaPath, '/private/ca.pem');
    expect(restored.clientCertificates.clientPrivateKeyPath, '/private/key.pem');
    expect(restored.clientCertificates.clientCertificatePath, '/private/cert.pem');
  });
}
