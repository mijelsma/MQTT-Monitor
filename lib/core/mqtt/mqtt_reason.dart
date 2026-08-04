import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;

import '../../models/mqtt_protocol_version.dart';

const mqtt311BrokerDisconnectMessage =
    'Disconnected by broker (no reason available — this is a limitation of MQTT 3.1.1). '
    'Consider switching to MQTT 5 for detailed error messages, if your broker supports it.';

enum MqttPacketKind { puback, pubrec, suback, unsuback, disconnect, connack }

/// A protocol-level broker notice that can be shown without exposing package
/// packet types to the UI.
class MqttReasonNotice {
  const MqttReasonNotice({required this.packet, required this.reasonCodes, this.reasonString});

  final MqttPacketKind packet;
  final List<int> reasonCodes;
  final String? reasonString;

  bool get hasFailure => reasonCodes.any((code) => code >= 0x80);

  String get message {
    final supplied = reasonString?.trim();
    final details = supplied != null && supplied.isNotEmpty ? supplied : reasonCodes.map(mqttReasonCodeLabel).join(', ');
    return '${packet.name.toUpperCase()}: $details';
  }

  /// Converts the MQTT 5 package's decoded packet into an app-level notice.
  /// Returns null for packet types that carry no user-facing reason metadata.
  static MqttReasonNotice? fromMqtt5Message(mqtt5.MqttMessage message) {
    if (message is mqtt5.MqttPublishAckMessage) {
      return MqttReasonNotice(packet: MqttPacketKind.puback, reasonCodes: [_publishCode(message.reasonCode)], reasonString: message.reasonString);
    }
    if (message is mqtt5.MqttPublishReceivedMessage) {
      return MqttReasonNotice(packet: MqttPacketKind.pubrec, reasonCodes: [_publishCode(message.reasonCode)], reasonString: message.reasonString);
    }
    if (message is mqtt5.MqttSubscribeAckMessage) {
      return MqttReasonNotice(packet: MqttPacketKind.suback, reasonCodes: message.reasonCodes.map(_subscribeCode).toList(), reasonString: message.reasonString);
    }
    if (message is mqtt5.MqttUnsubscribeAckMessage) {
      return MqttReasonNotice(packet: MqttPacketKind.unsuback, reasonCodes: message.reasonCodes.map(_subscribeCode).toList(), reasonString: message.reasonString);
    }
    if (message is mqtt5.MqttDisconnectMessage) {
      return MqttReasonNotice(packet: MqttPacketKind.disconnect, reasonCodes: [_disconnectCode(message.reasonCode)], reasonString: message.reasonString);
    }
    if (message is mqtt5.MqttConnectAckMessage) {
      return MqttReasonNotice(packet: MqttPacketKind.connack, reasonCodes: [_connectCode(message.variableHeader?.reasonCode)], reasonString: message.reasonString);
    }
    return null;
  }

  static int _publishCode(mqtt5.MqttPublishReasonCode? code) => mqtt5.MqttPublishReasonCodeSupport.mqttPublishReasonCode.asInt(code) ?? 0xff;

  static int _subscribeCode(mqtt5.MqttSubscribeReasonCode? code) => mqtt5.MqttSubscribeReasonCodeSupport.mqttSubscribeReasonCode.asInt(code) ?? 0xff;

  static int _disconnectCode(mqtt5.MqttDisconnectReasonCode? code) => mqtt5.MqttDisconnectReasonCodeSupport.mqttDisconnectReasonCode.asInt(code) ?? 0xff;

  static int _connectCode(mqtt5.MqttConnectReasonCode? code) => mqtt5.MqttConnectReasonCodeSupport.mqttConnectReasonCode.asInt(code) ?? 0xff;
}

String brokerDisconnectMessage(MqttProtocolVersion version) => switch (version) {
  MqttProtocolVersion.v311 => mqtt311BrokerDisconnectMessage,
  MqttProtocolVersion.v5 => 'Disconnected from broker.',
};

/// Human-readable MQTT 5 reason-code labels shared across packet families.
String mqttReasonCodeLabel(int code) => switch (code) {
  0x00 => 'Success',
  0x01 => 'Granted QoS 1',
  0x02 => 'Granted QoS 2',
  0x04 => 'Disconnect with Will Message',
  0x10 => 'No matching subscribers',
  0x11 => 'No subscription existed',
  0x18 => 'Continue authentication',
  0x19 => 'Re-authenticate',
  0x80 => 'Unspecified error',
  0x81 => 'Malformed packet',
  0x82 => 'Protocol error',
  0x83 => 'Implementation-specific error',
  0x84 => 'Unsupported protocol version',
  0x85 => 'Client identifier not valid',
  0x86 => 'Bad username or password',
  0x87 => 'Not authorized',
  0x88 => 'Server unavailable',
  0x89 => 'Server busy',
  0x8a => 'Banned',
  0x8b => 'Server shutting down',
  0x8c => 'Bad authentication method',
  0x8d => 'Keep Alive timeout',
  0x8e => 'Session taken over',
  0x8f => 'Topic filter invalid',
  0x90 => 'Topic name invalid',
  0x91 => 'Packet identifier in use',
  0x92 => 'Packet identifier not found',
  0x93 => 'Receive Maximum exceeded',
  0x94 => 'Topic Alias invalid',
  0x95 => 'Packet too large',
  0x96 => 'Message rate too high',
  0x97 => 'Quota exceeded',
  0x98 => 'Administrative action',
  0x99 => 'Payload format invalid',
  0x9a => 'Retain not supported',
  0x9b => 'QoS not supported',
  0x9c => 'Use another server',
  0x9d => 'Server moved',
  0x9e => 'Shared subscriptions not supported',
  0x9f => 'Connection rate exceeded',
  0xa0 => 'Maximum connect time',
  0xa1 => 'Subscription identifiers not supported',
  0xa2 => 'Wildcard subscriptions not supported',
  _ => 'Unknown reason code $code (0x${code.toRadixString(16).padLeft(2, '0').toUpperCase()})',
};
