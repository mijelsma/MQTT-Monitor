/// Maximum Unicode scalar values sent to the topic-tree text layout.
const int topicPayloadPreviewMaxRunes = 512;

/// Builds a bounded, single-line preview while preserving the full raw value
/// elsewhere in the monitor domain.
String buildTopicPayloadPreview(String payload) {
  if (payload.isEmpty) return payload;

  final output = <int>[];
  var truncated = false;
  final iterator = payload.runes.iterator;
  while (iterator.moveNext()) {
    final encoded = _visibleRunes(iterator.current);
    if (output.length + encoded.length > topicPayloadPreviewMaxRunes) {
      truncated = true;
      break;
    }
    output.addAll(encoded);
  }

  if (truncated) {
    if (output.length == topicPayloadPreviewMaxRunes) output.removeLast();
    output.add(0x2026);
  }
  return String.fromCharCodes(output);
}

List<int> _visibleRunes(int rune) => switch (rune) {
  0x09 => const [0x5C, 0x74], // \t
  0x0A || 0x2028 || 0x2029 => const [0x5C, 0x6E], // \n
  0x0D => const [0x5C, 0x72], // \r
  0xFFFD => const [0x5C, 0x75, 0x46, 0x46, 0x46, 0x44], // \uFFFD
  >= 0x00 && <= 0x1F || >= 0x7F && <= 0x9F => _hexEscape(rune),
  _ => [rune],
};

List<int> _hexEscape(int rune) =>
    '\\x${rune.toRadixString(16).padLeft(2, '0').toUpperCase()}'.codeUnits;
