import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../generated/l10n.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Pretty-prints JSON while keeping short arrays of primitive values on one
/// line. Maps always remain expanded for readability.
String formatJsonPayload(String payload, {int maxInlineArrayItems = 1, Set<String> expandedArrayPaths = const {}, bool includeArrayMarkers = false}) {
  try {
    return _formatJsonValue(jsonDecode(payload), level: 0, path: r'$', maxInlineArrayItems: maxInlineArrayItems.clamp(1, 10), expandedArrayPaths: expandedArrayPaths, includeArrayMarkers: includeArrayMarkers);
  } on FormatException {
    return payload;
  }
}

/// Formats valid JSON payloads for the clipboard exactly as shown in the
/// message value window. Non-JSON content is returned byte-for-byte unchanged.
String formatPayloadForClipboard(String payload, {int maxInlineArrayItems = 1}) => formatJsonPayload(payload, maxInlineArrayItems: maxInlineArrayItems);

String _formatJsonValue(Object? value, {required int level, required String path, required int maxInlineArrayItems, required Set<String> expandedArrayPaths, required bool includeArrayMarkers}) {
  const indent = '    ';
  final currentIndent = List.filled(level, indent).join();
  final childIndent = List.filled(level + 1, indent).join();
  if (value is Map) {
    if (value.isEmpty) return '{}';
    final entries = value.entries.map((entry) => '$childIndent${jsonEncode(entry.key)}: ${_formatJsonValue(entry.value, level: level + 1, path: '$path.${entry.key}', maxInlineArrayItems: maxInlineArrayItems, expandedArrayPaths: expandedArrayPaths, includeArrayMarkers: includeArrayMarkers)}');
    return '{\n${entries.join(',\n')}\n$currentIndent}';
  }
  if (value is List) {
    final primitive = value.every((item) => item == null || item is num || item is bool || item is String);
    final inline = primitive && value.length <= maxInlineArrayItems && !expandedArrayPaths.contains(path);
    if (inline) {
      final pinnable = value.any((item) => item is num || item is String && num.tryParse(item) != null);
      final marker = includeArrayMarkers && pinnable ? '\uE000$path\uE001' : '';
      return '[${value.map(jsonEncode).join(', ')}]$marker';
    }
    if (value.isEmpty) return '[]';
    final items = <String>[];
    for (var index = 0; index < value.length; index++) {
      items.add('$childIndent${_formatJsonValue(value[index], level: level + 1, path: '$path[$index]', maxInlineArrayItems: maxInlineArrayItems, expandedArrayPaths: expandedArrayPaths, includeArrayMarkers: includeArrayMarkers)}');
    }
    return '[\n${items.join(',\n')}\n$currentIndent]';
  }
  return jsonEncode(value);
}

/// Formats a [DateTime] as a human-readable timestamp string.
///
/// When [verbose] is true (default), today's timestamps read "Today at HH:mm:ss.SSS".
/// When false, today's timestamps are just "HH:mm:ss.SSS" (for compact list rows).
String formatTimestamp(DateTime dt, {bool verbose = true}) {
  final now = DateTime.now();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  final ms = dt.millisecond.toString().padLeft(3, '0');
  final time = '$h:$m:$s.$ms';

  final sep = verbose ? ' at ' : ' ';

  if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
    return verbose ? 'Today$sep$time' : time;
  }

  final yesterday = now.subtract(const Duration(days: 1));
  if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
    return 'Yesterday$sep$time';
  }

  if (dt.year == now.year) {
    return '${dt.day} ${_months[dt.month - 1]}$sep$time';
  }

  return '${dt.day} ${_months[dt.month - 1]} ${dt.year}$sep$time';
}

/// Formats a payload string as a human-readable byte size.
String formatByteSize(String payload) {
  final bytes = utf8.encode(payload).length;
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Truncates [text] to [maxLen] characters, collapsing whitespace.
String truncate(String text, int maxLen) {
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.length <= maxLen) return clean;
  return '${clean.substring(0, maxLen)}\u2026';
}

/// Formats a [Duration] as a human-readable interval string.
///
/// Examples: "1 second", "2 minutes 30 seconds", "1 hour 5 minutes".
/// Picks the two most significant non-zero units to keep it readable.
String formatDurationHuman(Duration d, BuildContext context) {
  final s = S.of(context);
  final totalSeconds = d.inSeconds;
  if (totalSeconds < 1) return s.durationLessThanSecond;

  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = totalSeconds % 60;

  final parts = <String>[];
  if (hours > 0) parts.add(s.durationHours(hours));
  if (minutes > 0) parts.add(s.durationMinutes(minutes));
  if (seconds > 0 && hours == 0) parts.add(s.durationSeconds(seconds));

  return parts.join(' ');
}
