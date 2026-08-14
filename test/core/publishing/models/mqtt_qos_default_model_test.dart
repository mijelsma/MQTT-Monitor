import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/publishing/models/mqtt_qos_default_model.dart';

void main() {
  group('MqttQosDefaultModel.resolve', () {
    test('lastUsed falls back to the supplied last-used value', () {
      expect(MqttQosDefaultModel.lastUsed.resolve(0), 0);
      expect(MqttQosDefaultModel.lastUsed.resolve(1), 1);
      expect(MqttQosDefaultModel.lastUsed.resolve(2), 2);
    });

    test('qos0/1/2 always return their own value regardless of the last-used value', () {
      expect(MqttQosDefaultModel.qos0.resolve(0), 0);
      expect(MqttQosDefaultModel.qos0.resolve(2), 0);
      expect(MqttQosDefaultModel.qos1.resolve(0), 1);
      expect(MqttQosDefaultModel.qos1.resolve(2), 1);
      expect(MqttQosDefaultModel.qos2.resolve(0), 2);
      expect(MqttQosDefaultModel.qos2.resolve(1), 2);
    });
  });

  group('MqttQosDefaultModel.fromQos', () {
    test('maps 0/1 to qos0/qos1, anything else to qos2', () {
      expect(MqttQosDefaultModel.fromQos(0), MqttQosDefaultModel.qos0);
      expect(MqttQosDefaultModel.fromQos(1), MqttQosDefaultModel.qos1);
      expect(MqttQosDefaultModel.fromQos(2), MqttQosDefaultModel.qos2);
      expect(MqttQosDefaultModel.fromQos(99), MqttQosDefaultModel.qos2);
      expect(MqttQosDefaultModel.fromQos(-1), MqttQosDefaultModel.qos2);
    });
  });

  group('MqttQosDefaultModel metadata', () {
    test('every option has a non-empty short label', () {
      final labels = <String>{};
      for (final option in MqttQosDefaultModel.values) {
        expect(option.shortLabel, isNotEmpty);
        expect(labels.add(option.shortLabel), isTrue, reason: '$option reused a label');
      }
    });

    test('"last used" is the LAST option in the picker (qos0, qos1, qos2, lastUsed)', () {
      expect(MqttQosDefaultModel.values, orderedEquals([MqttQosDefaultModel.qos0, MqttQosDefaultModel.qos1, MqttQosDefaultModel.qos2, MqttQosDefaultModel.lastUsed]));
    });
  });
}
