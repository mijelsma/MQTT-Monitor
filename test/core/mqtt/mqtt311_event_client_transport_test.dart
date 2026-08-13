import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt3;
import 'package:mqtt_monitor/core/mqtt/adapters/mqtt311/mqtt311_event_client.dart';
import 'package:typed_data/typed_buffers.dart';

void main() {
  test('time-sliced transport receives a large local TCP burst responsively', () async {
    const packetCount = 10000;
    final burst = Uint8Buffer();
    for (var index = 0; index < packetCount; index++) {
      burst.addAll(_publishPacket('iot/device-$index/value', '$index'));
    }
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final serverTask = _serveConnections(
      server,
      onConnected: (socket, _) {
        Timer(const Duration(milliseconds: 100), () => socket.add(burst));
      },
    );
    addTearDown(() async {
      await serverTask.timeout(const Duration(seconds: 2), onTimeout: () {});
    });

    final client = Mqtt311EventClient.withPort('127.0.0.1', 'burst-test', server.port, maxConnectionAttempts: 1)..socketTimeout = 5000;
    addTearDown(client.disconnect);
    await client.connect();

    final stopwatch = Stopwatch()..start();
    final completed = Completer<void>();
    var received = 0;
    var heartbeatCount = 0;
    var maximumGap = Duration.zero;
    var previousHeartbeat = stopwatch.elapsed;
    final heartbeat = Timer.periodic(Duration.zero, (_) {
      final now = stopwatch.elapsed;
      final gap = now - previousHeartbeat;
      if (gap > maximumGap) maximumGap = gap;
      previousHeartbeat = now;
      heartbeatCount++;
    });
    final updates = client.updates!.listen((batch) {
      received += batch.length;
      if (received == packetCount && !completed.isCompleted) {
        completed.complete();
      }
    });
    addTearDown(updates.cancel);

    await completed.future.timeout(const Duration(seconds: 8));
    heartbeat.cancel();

    expect(received, packetCount);
    expect(heartbeatCount, greaterThan(20));
    expect(maximumGap, lessThan(const Duration(milliseconds: 100)));
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('time-sliced transport recreates its decoder after auto-reconnect', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final sockets = <Socket>[];
    final secondConnection = Completer<Socket>();
    final serverTask = _serveConnections(
      server,
      onConnected: (socket, count) {
        sockets.add(socket);
        if (count == 2) secondConnection.complete(socket);
      },
    );
    addTearDown(() async {
      await serverTask.timeout(const Duration(seconds: 2), onTimeout: () {});
    });

    final client = Mqtt311EventClient.withPort('127.0.0.1', 'reconnect-test', server.port, maxConnectionAttempts: 1)
      ..socketTimeout = 5000
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = false;
    addTearDown(client.disconnect);
    await client.connect();

    final received = Completer<mqtt3.MqttReceivedMessage<mqtt3.MqttMessage>>();
    final updates = client.updates!.listen((batch) {
      if (batch.isNotEmpty && !received.isCompleted) {
        received.complete(batch.single);
      }
    });
    addTearDown(updates.cancel);

    await sockets.first.close();
    final reconnectedSocket = await secondConnection.future.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    reconnectedSocket.add(_publishPacket('iot/after-reconnect', 'alive'));

    final message = await received.future.timeout(const Duration(seconds: 5));
    final publish = message.payload as mqtt3.MqttPublishMessage;
    expect(message.topic, 'iot/after-reconnect');
    expect(utf8.decode(publish.payload.message), 'alive');
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('time-sliced transport preserves incoming QoS 1 acknowledgement', () async {
    const packetIdentifier = 37;
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final pubAck = Completer<void>();
    unawaited(() async {
      await for (final socket in server) {
        var connected = false;
        socket.listen((bytes) {
          if (!connected) {
            connected = true;
            socket.add(const [0x20, 0x02, 0x00, 0x00]);
            Timer(const Duration(milliseconds: 100), () {
              socket.add(_publishPacket('iot/qos1', 'acknowledge-me', qos: mqtt3.MqttQos.atLeastOnce, messageIdentifier: packetIdentifier));
            });
            return;
          }
          if (_containsSequence(bytes, const [0x40, 0x02, 0x00, packetIdentifier]) && !pubAck.isCompleted) {
            pubAck.complete();
          }
        });
      }
    }());

    final client = Mqtt311EventClient.withPort('127.0.0.1', 'qos1-test', server.port, maxConnectionAttempts: 1)..socketTimeout = 5000;
    addTearDown(client.disconnect);
    await client.connect();

    final received = Completer<mqtt3.MqttPublishMessage>();
    final updates = client.updates!.listen((batch) {
      if (batch.isNotEmpty && !received.isCompleted) {
        received.complete(batch.single.payload as mqtt3.MqttPublishMessage);
      }
    });
    addTearDown(updates.cancel);

    final publish = await received.future.timeout(const Duration(seconds: 5));
    await pubAck.future.timeout(const Duration(seconds: 5));

    expect(publish.variableHeader?.messageIdentifier, packetIdentifier);
    expect(utf8.decode(publish.payload.message), 'acknowledge-me');
  });

  test('remote socket closure reports unsolicited disconnection', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final serverTask = _serveConnections(
      server,
      onConnected: (socket, _) {
        Timer(const Duration(milliseconds: 100), socket.close);
      },
    );
    addTearDown(() async {
      await serverTask.timeout(const Duration(seconds: 2), onTimeout: () {});
    });

    final client = Mqtt311EventClient.withPort('127.0.0.1', 'disconnect-test', server.port, maxConnectionAttempts: 1)..socketTimeout = 5000;
    final disconnected = Completer<void>();
    client.onDisconnected = disconnected.complete;
    await client.connect();

    await disconnected.future.timeout(const Duration(seconds: 5));

    expect(client.connectionStatus?.disconnectionOrigin, mqtt3.MqttDisconnectionOrigin.unsolicited);
  });
}

Future<void> _serveConnections(ServerSocket server, {required void Function(Socket socket, int connectionCount) onConnected}) async {
  var connectionCount = 0;
  await for (final socket in server) {
    connectionCount++;
    var acknowledged = false;
    socket.listen((_) {
      if (acknowledged) return;
      acknowledged = true;
      socket.add(const [0x20, 0x02, 0x00, 0x00]);
      onConnected(socket, connectionCount);
    });
  }
}

List<int> _publishPacket(String topic, String payload, {mqtt3.MqttQos qos = mqtt3.MqttQos.atMostOnce, int? messageIdentifier}) {
  final builder = mqtt3.MqttClientPayloadBuilder()..addString(payload);
  var message = mqtt3.MqttPublishMessage().toTopic(topic).withQos(qos).publishData(builder.payload!);
  if (messageIdentifier != null) {
    message = message.withMessageIdentifier(messageIdentifier);
  }
  final wire = mqtt3.MqttByteBuffer(Uint8Buffer());
  message.writeTo(wire);
  return List<int>.from(wire.buffer!);
}

bool _containsSequence(List<int> bytes, List<int> sequence) {
  for (var start = 0; start <= bytes.length - sequence.length; start++) {
    var matches = true;
    for (var offset = 0; offset < sequence.length; offset++) {
      if (bytes[start + offset] != sequence[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}
