import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;
import 'package:mqtt_monitor/core/mqtt/mqtt_reason.dart';
import 'package:mqtt_monitor/core/mqtt/models/mqtt_protocol_version_model.dart';

void main() {
  group('MqttReasonNotice', () {
    mqtt5.MqttMessage parse(List<int> bytes) => mqtt5.MqttMessage.createFrom(mqtt5.MqttByteBuffer.fromList(bytes))!;

    test('parses a reason code and broker reason string from a PUBACK', () {
      final packet = mqtt5.MqttPublishAckMessage().withMessageIdentifier(7).withReasonCode(mqtt5.MqttPublishReasonCode.notAuthorized);
      packet.variableHeader!.reasonString = 'Publish denied by policy';

      final notice = MqttReasonNotice.fromMqtt5Message(packet);

      expect(notice?.packet, MqttPacketKind.puback);
      expect(notice?.reasonCodes, [135]);
      expect(notice?.reasonString, 'Publish denied by policy');
      expect(notice?.message, 'PUBACK: Publish denied by policy');
      expect(notice?.hasFailure, isTrue);
    });

    test('parses a PUBREC reason when no reason string is present', () {
      final packet = mqtt5.MqttPublishReceivedMessage().withMessageIdentifier(9).withReasonCode(mqtt5.MqttPublishReasonCode.quotaExceeded);

      final notice = MqttReasonNotice.fromMqtt5Message(packet);

      expect(notice?.packet, MqttPacketKind.pubrec);
      expect(notice?.reasonCodes, [151]);
      expect(notice?.message, 'PUBREC: Quota exceeded');
    });

    test('parses DISCONNECT reason code and string', () {
      final packet = mqtt5.MqttDisconnectMessage().withReasonCode(mqtt5.MqttDisconnectReasonCode.notAuthorized).withReasonString('Certificate identity rejected');

      final notice = MqttReasonNotice.fromMqtt5Message(packet);

      expect(notice?.packet, MqttPacketKind.disconnect);
      expect(notice?.reasonCodes, [135]);
      expect(notice?.message, 'DISCONNECT: Certificate identity rejected');
    });

    test('parses SUBACK reason codes and broker reason string from wire bytes', () {
      final packet = parse([0x90, 0x1a, 0x00, 0x0a, 0x14, 0x1f, 0x00, 0x06, ...'reason'.codeUnits, 0x26, 0x00, 0x03, ...'abc'.codeUnits, 0x00, 0x03, ...'def'.codeUnits, 0x00, 0x8f, 0x97]);

      final notice = MqttReasonNotice.fromMqtt5Message(packet);

      expect(notice?.packet, MqttPacketKind.suback);
      expect(notice?.reasonCodes, [0, 143, 151]);
      expect(notice?.message, 'SUBACK: reason');
      expect(notice?.hasFailure, isTrue);
    });

    test('parses UNSUBACK reason codes and reason string from wire bytes', () {
      final packet = parse([0xb0, 0x1a, 0x00, 0x0a, 0x14, 0x1f, 0x00, 0x06, ...'reason'.codeUnits, 0x26, 0x00, 0x03, ...'abc'.codeUnits, 0x00, 0x03, ...'def'.codeUnits, 0x00, 0x8f, 0x97]);

      final notice = MqttReasonNotice.fromMqtt5Message(packet);

      expect(notice?.packet, MqttPacketKind.unsuback);
      expect(notice?.reasonCodes, [0, 143, 151]);
      expect(notice?.message, 'UNSUBACK: reason');
    });

    test('parses CONNACK reason code and reason string from wire bytes', () {
      final packet = parse([0x20, 0x0c, 0x00, 0x87, 0x09, 0x1f, 0x00, 0x06, ...'denied'.codeUnits]);

      final notice = MqttReasonNotice.fromMqtt5Message(packet);

      expect(notice?.packet, MqttPacketKind.connack);
      expect(notice?.reasonCodes, [135]);
      expect(notice?.message, 'CONNACK: denied');
    });
  });

  group('reason labels', () {
    test('maps known numeric codes', () {
      expect(mqttReasonCodeLabel(135), 'Not authorized');
      expect(mqttReasonCodeLabel(144), 'Topic name invalid');
    });

    test('falls back gracefully for unknown numeric codes', () {
      expect(mqttReasonCodeLabel(0xfe), 'Unknown reason code 254 (0xFE)');
    });
  });

  test('MQTT 3.1.1 disconnect explains that the protocol has no reason', () {
    expect(brokerDisconnectMessage(MqttProtocolVersionModel.v311), mqtt311BrokerDisconnectMessage);
    expect(mqtt311BrokerDisconnectMessage, contains('limitation of MQTT 3.1.1'));
    expect(mqtt311BrokerDisconnectMessage, contains('switching to MQTT 5'));
  });
}
