import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/models/mqtt_qos_default.dart';

void main() {
  group('MqttQosDefault.resolve', () {
    test('lastUsed falls back to the supplied last-used value', () {
      expect(MqttQosDefault.lastUsed.resolve(0), 0);
      expect(MqttQosDefault.lastUsed.resolve(1), 1);
      expect(MqttQosDefault.lastUsed.resolve(2), 2);
    });

    test('qos0/1/2 always return their own value regardless of the last-used value', () {
      expect(MqttQosDefault.qos0.resolve(0), 0);
      expect(MqttQosDefault.qos0.resolve(2), 0);
      expect(MqttQosDefault.qos1.resolve(0), 1);
      expect(MqttQosDefault.qos1.resolve(2), 1);
      expect(MqttQosDefault.qos2.resolve(0), 2);
      expect(MqttQosDefault.qos2.resolve(1), 2);
    });
  });

  group('MqttQosDefault.fromQos', () {
    test('maps 0/1 to qos0/qos1, anything else to qos2', () {
      expect(MqttQosDefault.fromQos(0), MqttQosDefault.qos0);
      expect(MqttQosDefault.fromQos(1), MqttQosDefault.qos1);
      expect(MqttQosDefault.fromQos(2), MqttQosDefault.qos2);
      expect(MqttQosDefault.fromQos(99), MqttQosDefault.qos2);
      expect(MqttQosDefault.fromQos(-1), MqttQosDefault.qos2);
    });
  });

  group('MqttQosDefault metadata', () {
    test('every option has a non-empty short label', () {
      final labels = <String>{};
      for (final option in MqttQosDefault.values) {
        expect(option.shortLabel, isNotEmpty);
        expect(labels.add(option.shortLabel), isTrue, reason: '$option reused a label');
      }
    });

    test('"last used" is the LAST option in the picker (qos0, qos1, qos2, lastUsed)', () {
      expect(
        MqttQosDefault.values,
        orderedEquals([
          MqttQosDefault.qos0,
          MqttQosDefault.qos1,
          MqttQosDefault.qos2,
          MqttQosDefault.lastUsed,
        ]),
      );
    });

    test('"last used" is rendered with a history icon to signal "remember the previous pick"', () {
      final icon = MqttQosDefault.lastUsed.icon;
      expect(icon, isA<Icon>());
      expect((icon as Icon).icon, Icons.history_rounded);
    });

    test('the fixed QoS options render a QosLevelIcon (number badge), not a Material icon', () {
      for (final option in [MqttQosDefault.qos0, MqttQosDefault.qos1, MqttQosDefault.qos2]) {
        expect(option.icon, isA<QosLevelIcon>(), reason: '$option should render a numbered badge');
        expect((option.icon as QosLevelIcon).level, option.resolve(0));
      }
    });
  });

  group('QosLevelIcon', () {
    testWidgets('renders the QoS number inside a rounded square', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: QosLevelIcon(level: 1))),
        ),
      );
      expect(find.text('1'), findsOneWidget);
    });
  });
}
