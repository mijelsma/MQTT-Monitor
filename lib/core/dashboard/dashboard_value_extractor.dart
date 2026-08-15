import 'dart:convert';

typedef DashboardJsonDecoder = Object? Function(String source);

/// Extracts graphable numbers from one already-decoded MQTT payload.
class DashboardValueExtractor {
  DashboardValueExtractor({DashboardJsonDecoder decoder = jsonDecode}) : _decoder = decoder;

  final DashboardJsonDecoder _decoder;

  Object? decode(String payload) => _decoder(payload);

  /// Validates the dot-and-index syntax accepted for dashboard JSON paths.
  static void validateKeyPath(String path) {
    if (path.trim().isEmpty) return;
    _tokens(path).toList(growable: false);
  }

  double? extract(Object? decoded, String? keyPath) {
    Object? current = decoded;
    if (keyPath != null && keyPath.trim().isNotEmpty) {
      for (final token in _tokens(keyPath)) {
        if (token is int) {
          if (current is! List || token < 0 || token >= current.length) {
            return null;
          }
          current = current[token];
        } else {
          if (current is! Map || !current.containsKey(token)) return null;
          current = current[token];
        }
      }
    }
    return numericValue(current);
  }

  static double? numericValue(Object? value) {
    if (value is num) return value.toDouble();
    if (value is! String) return null;
    final text = value.trim();
    final plain = double.tryParse(text);
    if (plain != null) return plain;
    final match = RegExp(r'^([+-]?(?:\d+(?:\.\d*)?|\.\d+))\s*[a-zA-Z°/%]').firstMatch(text);
    return match == null ? null : double.tryParse(match.group(1)!);
  }
}

Iterable<Object> _tokens(String path) sync* {
  final pattern = RegExp(r'([^.\[\]]+)|\[(\d+)\]');
  var consumed = 0;
  for (final match in pattern.allMatches(path)) {
    final skipped = path.substring(consumed, match.start);
    if (skipped.isNotEmpty && skipped != '.') {
      throw const FormatException('Invalid dashboard JSON path.');
    }
    final index = match.group(2);
    yield index == null ? match.group(1)! : int.parse(index);
    consumed = match.end;
  }
  if (consumed != path.length) {
    throw const FormatException('Invalid dashboard JSON path.');
  }
}
