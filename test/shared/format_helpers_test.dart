import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/shared/format_helpers.dart';

void main() {
  group('formatPayloadForClipboard', () {
    test('pretty-prints a JSON object with two-space indentation', () {
      expect(
        formatPayloadForClipboard('{"sensor":{"value":21},"ok":true}'),
        '{\n  "sensor": {\n    "value": 21\n  },\n  "ok": true\n}',
      );
    });

    test('pretty-prints a JSON array', () {
      expect(
        formatPayloadForClipboard('[1,{"value":2}]'),
        '[\n  1,\n  {\n    "value": 2\n  }\n]',
      );
    });

    test('passes invalid JSON through unchanged', () {
      const payload = '{not valid json';
      expect(formatPayloadForClipboard(payload), payload);
    });

    test('passes an empty string through unchanged', () {
      expect(formatPayloadForClipboard(''), '');
    });

    test('passes non-JSON plain text through unchanged', () {
      const payload = 'temperature = 21.5 °C';
      expect(formatPayloadForClipboard(payload), payload);
    });
  });
}
