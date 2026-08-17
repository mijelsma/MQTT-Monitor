import 'dart:convert';

/// The current value stored at a leaf (or updated branch) node.
class TopicNodeValueModel {
  const TopicNodeValueModel({required this.payload, required this.seq, required this.receivedAt, this.payloadBytes, this.retain = false, this.qos = 0});

  final String payload;

  /// Original MQTT payload bytes, retained alongside decoded [payload].
  final List<int>? payloadBytes;

  /// Exact received payload length, independent of the decoded text view.
  int get payloadByteLength => payloadBytes?.length ?? utf8.encode(payload).length;
  final int seq;
  final DateTime receivedAt;
  final bool retain;
  final int qos;
}
