import 'dart:convert';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// Renders a JSON string with syntax-highlighted pretty-printing.
///
/// Falls back to plain monospaced text if the input is not valid JSON.
class JsonHighlighter extends StatelessWidget {
  const JsonHighlighter({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final parsed = _tryParse(source);
    if (parsed == null) {
      // Not JSON — render as plain text
      return SelectableText(
        source,
        style: TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 12.5, height: 1.5, color: tokens.textPrimary),
      );
    }

    final pretty = const JsonEncoder.withIndent('    ').convert(parsed);
    final spans = _highlight(pretty, isDark, tokens);

    return SelectableText.rich(
      TextSpan(children: spans),
      style: TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 12.5, height: 1.5, color: tokens.textPrimary),
    );
  }

  static Object? _tryParse(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  static List<TextSpan> _highlight(String json, bool isDark, AppTokens tokens) {
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
        // Determine if this is a key: look back (skipping whitespace) for '{' or ','
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
    // Walk backwards from the quote, skip whitespace/newlines.
    for (var j = i - 1; j >= 0; j--) {
      final c = json[j];
      if (c == ' ' || c == '\n' || c == '\r' || c == '\t') continue;
      // After '{' or ',' we expect a key.
      return c == '{' || c == ',';
    }
    return true;
  }
}
