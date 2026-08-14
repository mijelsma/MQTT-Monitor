import 'dart:async';
import 'dart:typed_data';

/// Frames MQTT wire packets and decodes them in bounded event-loop slices.
///
/// MQTT 3.1.1 and MQTT 5 share the same fixed-header remaining-length format,
/// so the buffering and scheduling policy has one implementation while each
/// protocol package remains responsible for decoding its own message type.
class TimeSlicedMqttPacketDecoder<T> {
  TimeSlicedMqttPacketDecoder({required this.decodePacket, required this.onMessage, required this.onInputDrained, required this.onError, required this.protocolLabel, this.maximumPacketsPerSlice = 250, this.maximumSliceDuration = const Duration(milliseconds: 4), Timer Function(Duration duration, void Function() callback)? timerFactory})
    : assert(maximumPacketsPerSlice > 0),
      _timerFactory = timerFactory ?? Timer.new;

  final T Function(Uint8List packet) decodePacket;
  final void Function(T message) onMessage;
  final void Function() onInputDrained;
  final void Function(Object error) onError;
  final String protocolLabel;
  final int maximumPacketsPerSlice;
  final Duration maximumSliceDuration;
  final Timer Function(Duration duration, void Function() callback) _timerFactory;

  Uint8List _buffer = Uint8List(0);
  int _offset = 0;
  Timer? _drainTimer;
  bool _disposed = false;

  /// Adds the next socket chunk. The producer should remain paused until
  /// [onInputDrained] reports that another chunk is needed.
  void addChunk(List<int> bytes) {
    if (_disposed || bytes.isEmpty) return;
    final unread = _buffer.length - _offset;
    if (unread == 0) {
      _buffer = Uint8List.fromList(bytes);
      _offset = 0;
    } else {
      final joined = Uint8List(unread + bytes.length)
        ..setRange(0, unread, _buffer, _offset)
        ..setRange(unread, unread + bytes.length, bytes);
      _buffer = joined;
      _offset = 0;
    }
    _scheduleDrain();
  }

  void _scheduleDrain() {
    _drainTimer ??= _timerFactory(Duration.zero, _drainSlice);
  }

  void _drainSlice() {
    _drainTimer = null;
    if (_disposed) return;
    final stopwatch = Stopwatch()..start();
    var processed = 0;
    try {
      while (processed < maximumPacketsPerSlice && stopwatch.elapsed < maximumSliceDuration) {
        final packetLength = _packetLengthAt(_offset);
        if (packetLength == null) {
          _compactUnread();
          onInputDrained();
          return;
        }
        final end = _offset + packetLength;
        if (end > _buffer.length) {
          _compactUnread();
          onInputDrained();
          return;
        }
        final packet = Uint8List.sublistView(_buffer, _offset, end);
        final message = decodePacket(packet);
        _offset = end;
        processed++;
        onMessage(message);
      }
    } on Object catch (error) {
      _buffer = Uint8List(0);
      _offset = 0;
      onError(error);
      return;
    }

    if (_offset < _buffer.length) {
      _scheduleDrain();
      return;
    }
    _buffer = Uint8List(0);
    _offset = 0;
    onInputDrained();
  }

  int? _packetLengthAt(int start) {
    if (_buffer.length - start < 2) return null;
    var multiplier = 1;
    var remainingLength = 0;
    var cursor = start + 1;
    for (var byteCount = 0; byteCount < 4; byteCount++) {
      if (cursor >= _buffer.length) return null;
      final byte = _buffer[cursor++];
      remainingLength += (byte & 0x7f) * multiplier;
      if ((byte & 0x80) == 0) {
        return cursor - start + remainingLength;
      }
      multiplier *= 128;
    }
    throw FormatException('Malformed $protocolLabel remaining-length field.');
  }

  void _compactUnread() {
    if (_offset == 0) return;
    _buffer = Uint8List.fromList(Uint8List.sublistView(_buffer, _offset));
    _offset = 0;
  }

  /// Cancels pending parsing and releases buffered network input.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _drainTimer?.cancel();
    _drainTimer = null;
    _buffer = Uint8List(0);
    _offset = 0;
  }
}
