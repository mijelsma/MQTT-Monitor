import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/mqtt/mqtt_topic_filter.dart';

void main() {
  group('validation', () {
    test('accepts concrete and wildcard MQTT filters', () {
      for (final filter in ['home/device/state', 'home/+/state', 'home/#', '#', '/leading/level', 'trailing/', r'$share/workers/home/+/state']) {
        expect(MqttTopicFilter.validate(filter), isNull, reason: filter);
      }
    });

    test('rejects misplaced wildcards and invalid text', () {
      for (final filter in ['', 'home/#/state', 'home/sensor+', 'home/+value']) {
        expect(MqttTopicFilter.validate(filter), isNotNull, reason: filter);
      }
      expect(MqttTopicFilter.validate('home/\u0000/state'), isNotNull);
      expect(MqttTopicFilter.validate(r'$share//home/#'), isNotNull);
      expect(MqttTopicFilter.validate(r'$share/gr+oup/home/#'), isNotNull);
      expect(MqttTopicFilter.validate(List.filled(65536, 'a').join()), isNotNull);
    });
  });

  group('matching', () {
    test('matches single and multi-level wildcards', () {
      expect(MqttTopicFilter.matches('home/+/state', 'home/device/state'), isTrue);
      expect(MqttTopicFilter.matches('home/+/state', 'home/a/b/state'), isFalse);
      expect(MqttTopicFilter.matches('home/#', 'home'), isTrue);
      expect(MqttTopicFilter.matches('home/#', 'home/device/state'), isTrue);
      expect(MqttTopicFilter.matches('home/+', 'home/'), isTrue);
    });

    test('does not let a root wildcard match system topics', () {
      expect(MqttTopicFilter.matches('#', r'$SYS/broker/uptime'), isFalse);
      expect(MqttTopicFilter.matches(r'$SYS/#', r'$SYS/broker/uptime'), isTrue);
    });

    test('matches the effective filter of a shared subscription', () {
      expect(MqttTopicFilter.matches(r'$share/workers/home/+/state', 'home/device/state'), isTrue);
      expect(MqttTopicFilter.matches(r'$share/workers/#', r'$SYS/broker/uptime'), isFalse);
      expect(MqttTopicFilter.matches(r'$share/workers/$SYS/#', r'$SYS/broker/uptime'), isTrue);
    });
  });
}
