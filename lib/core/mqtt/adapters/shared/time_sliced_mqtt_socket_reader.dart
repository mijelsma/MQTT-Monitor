import 'dart:async';
import 'dart:typed_data';

import 'time_sliced_mqtt_packet_decoder.dart';

/// Reads one socket chunk at a time while MQTT packets are decoded in bounded
/// event-loop slices. Pausing the socket provides backpressure between chunks.
class TimeSlicedMqttSocketReader<T> {
  TimeSlicedMqttSocketReader({required Stream<Uint8List> input, required T Function(Uint8List packet) decodePacket, required void Function(T message) onMessage, required void Function(Object error) onError, required void Function() onDone, required String protocolLabel}) {
    _decoder = TimeSlicedMqttPacketDecoder<T>(decodePacket: decodePacket, onMessage: onMessage, onInputDrained: _resumeInput, onError: onError, protocolLabel: protocolLabel);
    subscription = input.listen(_onData, onError: onError, onDone: onDone);
  }

  late final StreamSubscription<Uint8List> subscription;
  late final TimeSlicedMqttPacketDecoder<T> _decoder;
  bool _disposed = false;

  void _onData(Uint8List data) {
    if (_disposed || data.isEmpty) return;
    subscription.pause();
    _decoder.addChunk(data);
  }

  void _resumeInput() {
    if (!_disposed && subscription.isPaused) subscription.resume();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _decoder.dispose();
  }
}
