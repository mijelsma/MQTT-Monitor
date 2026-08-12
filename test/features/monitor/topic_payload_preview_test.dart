import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/features/monitor/topic_payload_preview.dart';

void main() {
  test('leaves short printable payloads unchanged', () {
    const payload = '{"sensor":"alpha","value":415}';

    expect(buildTopicPayloadPreview(payload), payload);
  });

  test('normalizes line breaks, controls, and malformed replacements', () {
    const payload = 'a\nb\r\t\u0000\u001f\u007f\u0085\u2028\u2029\ufffdz';

    expect(
      buildTopicPayloadPreview(payload),
      r'a\nb\r\t\x00\x1F\x7F\x85\n\n\uFFFDz',
    );
  });

  test('bounds the final preview and appends an ellipsis', () {
    final payload = List.filled(topicPayloadPreviewMaxRunes + 1, 'x').join();
    final preview = buildTopicPayloadPreview(payload);

    expect(preview.runes.length, topicPayloadPreviewMaxRunes);
    expect(preview.endsWith('…'), isTrue);
  });

  test('does not truncate a payload that exactly reaches the bound', () {
    final payload = List.filled(topicPayloadPreviewMaxRunes, 'x').join();

    expect(buildTopicPayloadPreview(payload), payload);
  });

  test('never splits a Unicode scalar at the preview boundary', () {
    final payload = List.filled(topicPayloadPreviewMaxRunes + 1, '😀').join();
    final preview = buildTopicPayloadPreview(payload);

    expect(preview.runes.length, topicPayloadPreviewMaxRunes);
    expect(preview.endsWith('…'), isTrue);
    expect(preview.contains('�'), isFalse);
  });

  test('bounds control expansion as well as source consumption', () {
    final payload = List.filled(topicPayloadPreviewMaxRunes, '\u0000').join();
    final preview = buildTopicPayloadPreview(payload);

    expect(
      preview.runes.length,
      lessThanOrEqualTo(topicPayloadPreviewMaxRunes),
    );
    expect(preview.endsWith('…'), isTrue);
    expect(preview, isNot(contains('\u0000')));
  });
}
