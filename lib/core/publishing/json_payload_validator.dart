import 'dart:convert';

/// Provides the single JSON validation policy for publish payloads.
class JsonPayloadValidator {
  const JsonPayloadValidator();

  String? validate(String text) {
    try {
      jsonDecode(text);
      return null;
    } on FormatException catch (error) {
      final offset = error.offset;
      if (offset != null && offset <= text.length) {
        final prefix = text.substring(0, offset);
        final line = '\n'.allMatches(prefix).length + 1;
        final lastNewline = prefix.lastIndexOf('\n');
        final column = lastNewline == -1 ? offset + 1 : offset - lastNewline;
        return 'Ln $line, Col $column: ${error.message}';
      }
      return error.message;
    }
  }

  bool isValid(String text) => validate(text) == null;
}
