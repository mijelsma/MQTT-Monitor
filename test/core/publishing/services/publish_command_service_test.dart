import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/publish_result.dart';
import 'package:mqtt_monitor/core/publishing/publish_command.dart';
import 'package:mqtt_monitor/core/publishing/publish_command_failure.dart';
import 'package:mqtt_monitor/core/publishing/services/publish_command_service.dart';
import 'package:mqtt_monitor/core/publishing/publish_transport.dart';
import 'package:mqtt_monitor/core/publishing/template_resolver.dart';

void main() {
  test('validates and resolves before forwarding one publish', () async {
    final transport = _RecordingTransport();
    final service = PublishCommandService(transport, const TemplateResolver());
    var dispatches = 0;

    final result = await service.execute(const PublishCommand(topicTemplate: r'sensors/${DEVICE}/set', payload: '{"enabled":true}', payloadIsJson: true, qos: 2, retain: true), {'DEVICE': 'lamp'}, onDispatch: () => dispatches++);

    expect(result.wasSent, isTrue);
    expect(result.transportResult!.isDelivered, isTrue);
    expect(transport.topic, 'sensors/lamp/set');
    expect(transport.payload, '{"enabled":true}');
    expect(transport.qos, 2);
    expect(transport.retain, isTrue);
    expect(transport.calls, 1);
    expect(dispatches, 1);
  });

  test('returns precise failures without touching transport', () async {
    final transport = _RecordingTransport();
    final service = PublishCommandService(transport, const TemplateResolver());
    var dispatches = 0;

    final cases = <({PublishCommand command, PublishCommandFailure failure})>[
      (command: const PublishCommand(topicTemplate: ''), failure: PublishCommandFailure.emptyTopic),
      (command: const PublishCommand(topicTemplate: r'sensor/${BROKEN'), failure: PublishCommandFailure.invalidTemplate),
      (command: const PublishCommand(topicTemplate: r'sensor/${ID}'), failure: PublishCommandFailure.missingVariables),
      (command: const PublishCommand(topicTemplate: 'sensor/+'), failure: PublishCommandFailure.invalidTopic),
      (command: const PublishCommand(topicTemplate: 'sensor/value', payload: '{broken', payloadIsJson: true), failure: PublishCommandFailure.invalidJson),
      (command: const PublishCommand(topicTemplate: 'sensor/value', qos: 3), failure: PublishCommandFailure.invalidQos),
    ];

    for (final testCase in cases) {
      final result = await service.execute(testCase.command, const {}, onDispatch: () => dispatches++);
      expect(result.failure, testCase.failure);
    }
    expect(transport.calls, 0);
    expect(dispatches, 0);
  });

  test('reports offline when validated command has no active transport', () async {
    final service = PublishCommandService(_RecordingTransport(connected: false), const TemplateResolver());

    final result = await service.execute(const PublishCommand(topicTemplate: 'sensor/value'), const {});

    expect(result.failure, PublishCommandFailure.offline);
  });
}

class _RecordingTransport implements PublishTransport {
  _RecordingTransport({this.connected = true});

  final bool connected;
  int calls = 0;
  String? topic;
  String? payload;
  int? qos;
  bool? retain;

  @override
  Future<PublishResult>? publish(String topic, String payload, {int qos = 0, bool retain = false}) {
    if (!connected) return null;
    calls++;
    this.topic = topic;
    this.payload = payload;
    this.qos = qos;
    this.retain = retain;
    return Future.value(PublishResult.delivered());
  }
}
