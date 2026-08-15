import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/shared/format_helpers.dart';

void main() {
  group('formatPayloadForClipboard', () {
    test('pretty-prints JSON using the value-window indentation', () {
      expect(formatPayloadForClipboard('{"sensor":{"value":21},"ok":true}'), '{\n    "sensor": {\n        "value": 21\n    },\n    "ok": true\n}');
    });

    test('pretty-prints a JSON array', () {
      expect(formatPayloadForClipboard('[1,{"value":2}]'), '[\n    1,\n    {\n        "value": 2\n    }\n]');
    });

    test('only compacts short arrays of primitive values', () {
      const payload = '{"samples":[[1,2,3],[4,5,6]],"object":[{"value":1}]}';

      expect(formatPayloadForClipboard(payload, maxInlineArrayItems: 3), '{\n    "samples": [\n        [1, 2, 3],\n        [4, 5, 6]\n    ],\n    "object": [\n        {\n            "value": 1\n        }\n    ]\n}');
      expect(formatPayloadForClipboard(payload, maxInlineArrayItems: 2), '{\n    "samples": [\n        [\n            1,\n            2,\n            3\n        ],\n        [\n            4,\n            5,\n            6\n        ]\n    ],\n    "object": [\n        {\n            "value": 1\n        }\n    ]\n}');
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
