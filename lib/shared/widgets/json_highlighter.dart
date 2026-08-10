import 'dart:convert';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// Callback that fires when a user taps a pin icon next to a numeric JSON value.
///
/// [keyPath] is the dot-separated path (e.g. `"sensor.temperature"`).
/// [label] is the leaf key name.
typedef JsonPinCallback = void Function(String keyPath, String label);

/// Renders a JSON string with syntax-highlighted pretty-printing.
///
/// Falls back to plain monospaced text if the input is not valid JSON.
///
/// When [onPin] is provided, small action icons are rendered in-line before
/// every JSON key whose value is numeric, allowing users to pin that value
/// to the graph dashboard.
///
/// The static [highlight] method produces coloured [TextSpan]s from raw
/// JSON text and is reused by the publish-panel's editable controller so
/// there is exactly *one* tokeniser for the entire app.
class JsonHighlighter extends StatelessWidget {
  const JsonHighlighter({super.key, required this.source, this.prettyPrint = true, this.onPin, this.selectable = true});

  final String source;

  /// When `true` (default), the JSON is re-formatted with 4-space indentation
  /// before highlighting. Set to `false` to highlight the raw text as-is.
  final bool prettyPrint;

  /// Whether this widget creates its own selectable text. Set this to false
  /// when an ancestor [SelectionArea] owns selection across multiple rows.
  final bool selectable;

  /// Optional callback to enable inline pin icons next to numeric values.
  final JsonPinCallback? onPin;

  /// Returns `true` if [text] is valid JSON.
  static bool isJson(String text) {
    try {
      jsonDecode(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String displayText = source;
    Object? parsed;
    if (prettyPrint) {
      parsed = _tryParse(source);
      if (parsed == null) {
        final style = TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 12.5, height: 1.5, color: tokens.textPrimary);
        return selectable ? SelectableText(source, style: style) : Text(source, style: style);
      }
      displayText = const JsonEncoder.withIndent('    ').convert(parsed);
    }

    final spans = highlight(displayText, isDark, tokens);

    // No pin callback → simple selectable text (original behaviour).
    if (onPin == null || parsed == null) {
      final span = TextSpan(children: spans);
      final style = TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 12.5, height: 1.5, color: tokens.textPrimary);
      return selectable ? SelectableText.rich(span, style: style) : Text.rich(span, style: style);
    }

    // Build a line-indexed map of pinnable key paths, then render per-line
    // rows so we can prepend a small icon without disturbing the formatting.
    final pinnableLines = _buildPinnableLineMap(parsed, displayText);
    final lineSpans = _splitSpansByLine(spans);
    const baseStyle = TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 12.5, height: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lineSpans.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pinnableLines.containsKey(i))
                _InlinePinButton(
                  onTap: () {
                    final info = pinnableLines[i]!;
                    onPin!(info.keyPath, info.label);
                  },
                  tokens: tokens,
                )
              else
                const SizedBox(width: 20),
              Text.rich(
                TextSpan(children: lineSpans[i]),
                style: baseStyle.copyWith(color: tokens.textPrimary),
                softWrap: false,
              ),
            ],
          ),
      ],
    );
  }

  static Object? _tryParse(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  // ── Pin-line mapping ────────────────────────────────────────────────

  /// Splits a flat list of TextSpans into per-line groups at newline boundaries.
  static List<List<TextSpan>> _splitSpansByLine(List<TextSpan> spans) {
    final lines = <List<TextSpan>>[[]];
    for (final span in spans) {
      final text = span.text ?? '';
      final parts = text.split('\n');
      for (var j = 0; j < parts.length; j++) {
        if (j > 0) lines.add([]);
        if (parts[j].isNotEmpty) {
          lines.last.add(TextSpan(text: parts[j], style: span.style));
        }
      }
    }
    return lines;
  }

  /// Maps line numbers (0-based) to key-path info for lines holding a numeric value.
  static Map<int, _PinnableInfo> _buildPinnableLineMap(Object parsed, String prettyJson) {
    final result = <int, _PinnableInfo>{};
    final lines = prettyJson.split('\n');
    final numPattern = RegExp(r'^\s*"([^"]+)"\s*:\s*(-?\d+\.?\d*([eE][+-]?\d+)?)\s*,?\s*$');
    final pathStack = <String>[];
    // Track the current array index at each nesting level that is an array.
    // When we push an array marker, we store the running index here.
    final arrayIndexStack = <int>[];
    // Whether each level on pathStack is an array (true) or object (false).
    final isArrayStack = <bool>[];

    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();

      // ── Object open ──
      if (trimmed.endsWith('{') || trimmed == '{') {
        // If the parent is an array, this object is an array element.
        // Increment the parent array index (except for the very first element).
        if (isArrayStack.isNotEmpty && isArrayStack.last) {
          arrayIndexStack[arrayIndexStack.length - 1]++;
        }
        final m = RegExp(r'^\s*"([^"]+)"\s*:\s*\{').firstMatch(lines[i]);
        pathStack.add(m != null ? m.group(1)! : '');
        isArrayStack.add(false);
        continue;
      }
      // ── Object close ──
      if (trimmed.startsWith('}')) {
        if (pathStack.isNotEmpty) {
          pathStack.removeLast();
          isArrayStack.removeLast();
        }
        continue;
      }

      // ── Array open ──
      if (trimmed.endsWith('[') || trimmed == '[') {
        final m = RegExp(r'^\s*"([^"]+)"\s*:\s*\[').firstMatch(lines[i]);
        pathStack.add(m != null ? m.group(1)! : '');
        isArrayStack.add(true);
        // Start index at -1; it gets incremented to 0 on the first child.
        arrayIndexStack.add(-1);
        continue;
      }
      // ── Array close ──
      if (trimmed.startsWith(']')) {
        if (pathStack.isNotEmpty) {
          pathStack.removeLast();
          isArrayStack.removeLast();
        }
        if (arrayIndexStack.isNotEmpty) arrayIndexStack.removeLast();
        continue;
      }

      final m = numPattern.firstMatch(lines[i]);
      if (m != null) {
        final key = m.group(1)!;
        final segments = <String>[];
        for (var s = 0; s < pathStack.length; s++) {
          if (pathStack[s].isNotEmpty) segments.add(pathStack[s]);
          // If this level is an array, append the current index.
          if (isArrayStack[s]) {
            // Find the corresponding array index counter.
            int arrayLevel = 0;
            for (var a = 0; a <= s; a++) {
              if (isArrayStack[a]) arrayLevel++;
            }
            if (arrayLevel > 0 && arrayLevel <= arrayIndexStack.length) {
              segments.add('[${arrayIndexStack[arrayLevel - 1]}]');
            }
          }
        }
        segments.add(key);
        result[i] = _PinnableInfo(keyPath: segments.join('.'), label: key);
      }

      // ── Bare array element ──
      // Lines directly inside an array that aren't "key": value pairs.
      // Increment the index for every element; only pin numeric ones.
      if (m == null && isArrayStack.isNotEmpty && isArrayStack.last) {
        arrayIndexStack[arrayIndexStack.length - 1]++;
        final bareNum = RegExp(r'^\s*(-?\d+\.?\d*([eE][+-]?\d+)?)\s*,?\s*$');
        final bm = bareNum.firstMatch(lines[i]);
        if (bm != null) {
          final currentIndex = arrayIndexStack.last;
          final segments = <String>[];
          for (var s = 0; s < pathStack.length; s++) {
            if (pathStack[s].isNotEmpty) segments.add(pathStack[s]);
            if (isArrayStack[s]) {
              int arrayLevel = 0;
              for (var a = 0; a <= s; a++) {
                if (isArrayStack[a]) arrayLevel++;
              }
              if (arrayLevel > 0 && arrayLevel <= arrayIndexStack.length) {
                segments.add('[${arrayIndexStack[arrayLevel - 1]}]');
              }
            }
          }
          final parentKey = pathStack.isNotEmpty ? pathStack.last : '';
          final label = parentKey.isNotEmpty ? '$parentKey[$currentIndex]' : '[$currentIndex]';
          result[i] = _PinnableInfo(keyPath: segments.join('.'), label: label);
        }
      }
    }
    return result;
  }

  // ── Syntax highlighting ─────────────────────────────────────────────
  ///
  /// Exposed as a public static so other widgets (e.g. an editable JSON field)
  /// can reuse the same colouring logic.
  static List<TextSpan> highlight(String json, bool isDark, AppTokens tokens) {
    final spans = <TextSpan>[];

    // Derive all colors from the app theme palette
    final keyColor = tokens.primary;
    final stringColor = isDark ? AppColors.success400 : AppColors.success700;
    final numberColor = isDark ? AppColors.warning400 : AppColors.warning700;
    final boolColor = isDark ? AppColors.secondary400 : AppColors.secondary700;
    final nullColor = tokens.muted;
    final punctColor = tokens.textTertiary;

    final buffer = StringBuffer();
    var inString = false;
    var escaped = false;
    var isKey = false;

    void flushBuffer() {
      if (buffer.isEmpty) return;
      final text = buffer.toString();
      buffer.clear();

      // Check for number, bool, null
      if (RegExp(r'^-?\d+\.?\d*([eE][+-]?\d+)?$').hasMatch(text.trim())) {
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(color: numberColor, fontWeight: FontWeight.w500),
          ),
        );
      } else if (text.trim() == 'true' || text.trim() == 'false') {
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(color: boolColor, fontWeight: FontWeight.w600),
          ),
        );
      } else if (text.trim() == 'null') {
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(color: nullColor, fontStyle: FontStyle.italic),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(color: punctColor),
          ),
        );
      }
    }

    // Walk through the pretty-printed JSON character by character.
    for (var i = 0; i < json.length; i++) {
      final c = json[i];

      if (inString) {
        buffer.write(c);
        if (escaped) {
          escaped = false;
          continue;
        }
        if (c == '\\') {
          escaped = true;
          continue;
        }
        if (c == '"') {
          final text = buffer.toString();
          buffer.clear();
          final color = isKey ? keyColor : stringColor;
          final weight = isKey ? FontWeight.w600 : FontWeight.w400;
          spans.add(
            TextSpan(
              text: text,
              style: TextStyle(color: color, fontWeight: weight),
            ),
          );
          inString = false;
        }
        continue;
      }

      if (c == '"') {
        flushBuffer();
        // A comma can precede both an object key and an array value. Inspect
        // the token itself instead: only a quoted string followed by a colon
        // is an object key.
        isKey = _isKeyPosition(json, i);
        inString = true;
        buffer.write(c);
        continue;
      }

      if (c == '{' || c == '}' || c == '[' || c == ']' || c == ':' || c == ',') {
        flushBuffer();
        spans.add(
          TextSpan(
            text: c,
            style: TextStyle(color: punctColor, fontWeight: FontWeight.w400),
          ),
        );
        continue;
      }

      buffer.write(c);
    }

    flushBuffer();
    return spans;
  }

  /// Checks if the quote at index [i] starts a JSON key (vs a value).
  static bool _isKeyPosition(String json, int i) {
    // Find the end of this JSON string, respecting escape sequences, then
    // check the next meaningful character. This distinguishes object keys
    // from strings in arrays after their separating comma.
    var escaped = false;
    for (var j = i + 1; j < json.length; j++) {
      final c = json[j];
      if (escaped) {
        escaped = false;
      } else if (c == '\\') {
        escaped = true;
      } else if (c == '"') {
        for (var k = j + 1; k < json.length; k++) {
          final next = json[k];
          if (next == ' ' || next == '\n' || next == '\r' || next == '\t') {
            continue;
          }
          return next == ':';
        }
        return false;
      }
    }
    return false;
  }
}

// ── Private helpers ─────────────────────────────────────────────────────

class _PinnableInfo {
  const _PinnableInfo({required this.keyPath, required this.label});
  final String keyPath;
  final String label;
}

class _InlinePinButton extends StatefulWidget {
  const _InlinePinButton({required this.onTap, required this.tokens});

  final VoidCallback onTap;
  final AppTokens tokens;

  @override
  State<_InlinePinButton> createState() => _InlinePinButtonState();
}

class _InlinePinButtonState extends State<_InlinePinButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovering ? widget.tokens.primary : widget.tokens.muted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 20,
          height: 12.5 * 1.5, // match line height
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.push_pin_rounded, size: 12, color: color),
          ),
        ),
      ),
    );
  }
}
