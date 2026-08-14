import 'package:flutter/material.dart';

import '../../theme/app_tokens/app_tokens.dart';
import '../widgets/json_highlighter.dart';

/// A [TextEditingController] with optional JSON syntax highlighting.
///
/// Toggle [highlightJson] to enable or disable colouring and call
/// [updateTheme] once per build so the controller knows the current palette.
class HighlightingController extends TextEditingController {
  HighlightingController({super.text});

  bool highlightJson = false;

  AppTokens? _tokens;
  bool _isDark = false;

  /// Feeds the current theme into the controller for [buildTextSpan].
  void updateTheme(AppTokens tokens, bool isDark) {
    _tokens = tokens;
    _isDark = isDark;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (!highlightJson || _tokens == null || text.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final spans = JsonHighlighter.highlight(text, _isDark, _tokens!);
    return TextSpan(style: style, children: spans);
  }
}
