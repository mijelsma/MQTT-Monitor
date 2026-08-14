import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/adapters/shared/time_sliced_mqtt_packet_decoder.dart';

void main() {
  test('frames fragmented and concatenated MQTT packets in order', () async {
    final packets = <Uint8List>[];
    final errors = <Object>[];
    final drains = StreamController<void>.broadcast();
    final decoder = _decoder(onPacket: packets.add, onDrained: () => drains.add(null), onError: errors.add);
    addTearDown(() {
      decoder.dispose();
      drains.close();
    });

    final first = _packet([1, 2, 3]);
    final second = _packet([4, 5]);
    decoder.addChunk(first.take(3).toList());
    await drains.stream.first.timeout(const Duration(seconds: 1));
    expect(packets, isEmpty);

    decoder.addChunk(<int>[...first.skip(3), ...second]);
    await drains.stream.first.timeout(const Duration(seconds: 1));

    expect(errors, isEmpty);
    expect(packets, [first, second]);
  });

  test('large packet burst stays linear and yields between slices', () async {
    const packetCount = 20000;
    const maximumElapsed = Duration(seconds: 8);
    const maximumHeartbeatGap = Duration(milliseconds: 250);
    final wire = BytesBuilder(copy: false);
    for (var index = 0; index < packetCount; index++) {
      wire.add(_packet([index & 0xff]));
    }

    final stopwatch = Stopwatch()..start();
    var decoded = 0;
    var heartbeatCount = 0;
    var maximumGap = Duration.zero;
    var previousHeartbeat = stopwatch.elapsed;
    final drained = Completer<void>();
    final errors = <Object>[];
    final heartbeat = Timer.periodic(Duration.zero, (_) {
      final now = stopwatch.elapsed;
      final gap = now - previousHeartbeat;
      if (gap > maximumGap) maximumGap = gap;
      previousHeartbeat = now;
      heartbeatCount++;
    });
    final decoder = _decoder(
      onPacket: (_) => decoded++,
      onDrained: () {
        if (!drained.isCompleted) drained.complete();
      },
      onError: errors.add,
    );
    addTearDown(decoder.dispose);

    decoder.addChunk(wire.takeBytes());
    await drained.future.timeout(maximumElapsed);
    stopwatch.stop();
    heartbeat.cancel();

    expect(errors, isEmpty);
    expect(decoded, packetCount);
    expect(heartbeatCount, greaterThan(20));
    expect(maximumGap, lessThan(maximumHeartbeatGap));
    expect(stopwatch.elapsed, lessThan(maximumElapsed));
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('malformed remaining length reports an error', () async {
    final packets = <Uint8List>[];
    final errorReported = Completer<Object>();
    final decoder = _decoder(onPacket: packets.add, onDrained: () {}, onError: errorReported.complete);
    addTearDown(decoder.dispose);

    decoder.addChunk(const [0x30, 0x80, 0x80, 0x80, 0x80]);
    final error = await errorReported.future.timeout(const Duration(seconds: 1));

    expect(packets, isEmpty);
    expect(error, isA<FormatException>());
  });
}

TimeSlicedMqttPacketDecoder<Uint8List> _decoder({required void Function(Uint8List packet) onPacket, required void Function() onDrained, required void Function(Object error) onError}) =>
    TimeSlicedMqttPacketDecoder<Uint8List>(decodePacket: (packet) => Uint8List.fromList(packet), onMessage: onPacket, onInputDrained: onDrained, onError: onError, protocolLabel: 'test MQTT');

Uint8List _packet(List<int> payload) => Uint8List.fromList([0x30, payload.length, ...payload]);
