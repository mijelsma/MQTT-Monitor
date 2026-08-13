import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;
import 'package:mqtt_monitor/core/mqtt/adapters/mqtt5/mqtt5_event_client.dart';
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

    final client = Mqtt5EventClient.withPort('127.0.0.1', 'burst-test', server.port, maxConnectionAttempts: 1)..socketTimeout = 5000;
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

    final client = Mqtt5EventClient.withPort('127.0.0.1', 'reconnect-test', server.port, maxConnectionAttempts: 1)
      ..socketTimeout = 5000
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = false;
    addTearDown(client.disconnect);
    await client.connect();

    final received = Completer<mqtt5.MqttReceivedMessage<mqtt5.MqttMessage>>();
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
    final publish = message.payload as mqtt5.MqttPublishMessage;
    expect(message.topic, 'iot/after-reconnect');
    expect(utf8.decode(publish.payload.message!), 'alive');
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('broker DISCONNECT preserves its reason and does not auto-reconnect', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    var connections = 0;
    final serverTask = _serveConnections(
      server,
      onConnected: (socket, _) {
        connections++;
        Timer(const Duration(milliseconds: 100), () {
          socket.add(const [0xe0, 0x02, 0x8b, 0x00]);
        });
      },
    );
    addTearDown(() async {
      await serverTask.timeout(const Duration(seconds: 2), onTimeout: () {});
    });

    final client = Mqtt5EventClient.withPort('127.0.0.1', 'disconnect-test', server.port, maxConnectionAttempts: 1)
      ..socketTimeout = 5000
      ..autoReconnect = true;
    final disconnected = Completer<void>();
    client.onDisconnected = disconnected.complete;
    await client.connect();

    await disconnected.future.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(connections, 1);
    expect(client.connectionStatus?.disconnectionOrigin, mqtt5.MqttDisconnectionOrigin.brokerSolicited);
    expect(client.connectionStatus?.disconnectMessage.reasonCode, mqtt5.MqttDisconnectReasonCode.serverShuttingDown);
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
      socket.add(const [0x20, 0x03, 0x00, 0x00, 0x00]);
      onConnected(socket, connectionCount);
    });
  }
}

List<int> _publishPacket(String topic, String payload) {
  final builder = mqtt5.MqttPayloadBuilder()..addString(payload);
  final message = mqtt5.MqttPublishMessage().toTopic(topic).withQos(mqtt5.MqttQos.atMostOnce).publishData(builder.payload!);
  final wire = mqtt5.MqttByteBuffer(Uint8Buffer());
  message.writeTo(wire);
  return List<int>.from(wire.buffer!);
}
