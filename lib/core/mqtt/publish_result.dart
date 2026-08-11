import '../../models/mqtt_protocol_version.dart';
import 'mqtt_reason.dart';

/// The real outcome of a publish, after the broker had a chance to
/// acknowledge it.
///
/// The MQTT protocol can only truly confirm a delivered publish in a narrow
/// set of cases; everything else is "sent, but the protocol did not (or could
/// not) prove delivery". The UI uses [kind] to decide whether to show a
/// confident green check, a grey "acknowledged" check, or a red failure with
/// a parsed reason.
enum PublishResultKind {
  /// The protocol confirmed success: MQTT 5 PUBACK/PUBREC with reason code 0.
  delivered,

  /// The protocol reported a failure: MQTT 5 PUBACK/PUBREC with reason code
  /// >= 0x80, or a local publish error. [reason] is the parsed reason label.
  failed,

  /// The publish was handed to the broker but the protocol gives us no
  /// proof of delivery. This covers every QoS 0 publish and every
  /// MQTT 3.1.1 publish — including those whose PUBACK came back, since
  /// 3.1.1 PUBACK carries no failure reason and brokers may still
  /// silently drop messages that violate the ACL.
  noConfirmation,

  /// The publish was accepted by the local client but no PUBACK/PUBREC
  /// arrived within the configured timeout. Surfaced as a distinct state
  /// so the user can tell "still in flight" apart from "broker never
  /// answered".
  timedOut,
}

/// A protocol-level result for a single publish, returned by
/// [MqttService.publish] once the broker has had a chance to respond (or
/// has had a reasonable time to).
class PublishResult {
  const PublishResult({required this.kind, this.reason, this.reasonCode, this.reasonString});

  /// Builds a "no confirmation" result, optionally enriched with a short
  /// human-readable explanation of *why* delivery is unconfirmed.
  factory PublishResult.unconfirmed(MqttProtocolVersion version, int qos) {
    final explanation = switch ((version, qos)) {
      (MqttProtocolVersion.v311, 0) => 'No ack at QoS 0 (MQTT 3.1.1).',
      (MqttProtocolVersion.v311, _) => 'No failure reason in MQTT 3.1.1 PUBACK — broker may still drop silently.',
      (MqttProtocolVersion.v5, 0) => 'No ack at QoS 0.',
      (MqttProtocolVersion.v5, _) => 'No failure reason available.',
    };
    return PublishResult(kind: PublishResultKind.noConfirmation, reason: explanation);
  }

  /// Builds a "delivered" result for MQTT 5 QoS 1/2 with reason code 0.
  factory PublishResult.delivered({String? reasonString, int? reasonCode}) => PublishResult(kind: PublishResultKind.delivered, reasonString: reasonString, reasonCode: reasonCode);

  /// Builds a "failed" result from an MQTT 5 reason code and optional
  /// reason string. The reason is parsed via [mqttReasonCodeLabel] so the
  /// user never sees a bare integer, but the integer is still shown
  /// alongside the label so the user can correlate with broker logs.
  factory PublishResult.failed({required int reasonCode, String? reasonString}) {
    final label = mqttReasonCodeLabel(reasonCode);
    final detail = reasonString?.trim().isNotEmpty == true ? reasonString!.trim() : null;
    return PublishResult(kind: PublishResultKind.failed, reason: detail == null ? '$label ($reasonCode)' : '$label ($reasonCode) — $detail', reasonCode: reasonCode, reasonString: reasonString);
  }

  /// Builds a "failed" result from a local error (e.g. the local client
  /// threw while serializing the publish).
  factory PublishResult.localFailure(String message) => PublishResult(kind: PublishResultKind.failed, reason: message);

  /// Builds a "timed out" result.
  factory PublishResult.timedOut(MqttProtocolVersion version, int qos) {
    return PublishResult(
      kind: PublishResultKind.timedOut,
      reason: switch ((version, qos)) {
        (MqttProtocolVersion.v5, _) => 'No PUBACK/PUBREC from broker within the timeout.',
        (_, 0) => 'No ack at QoS 0.',
        _ => 'No PUBACK from broker within the timeout.',
      },
    );
  }

  final PublishResultKind kind;

  /// Human-readable explanation. For failures, includes both the parsed
  /// reason label and the broker's reason string when available.
  final String? reason;

  /// Raw MQTT 5 reason code (0x00–0xFF), or null for local/timeout cases.
  final int? reasonCode;

  /// Broker-supplied reason string (MQTT 5 only), or null.
  final String? reasonString;

  bool get isDelivered => kind == PublishResultKind.delivered;
  bool get isFailure => kind == PublishResultKind.failed;
  bool get isUnconfirmed => kind == PublishResultKind.noConfirmation;
  bool get isTimedOut => kind == PublishResultKind.timedOut;
}
