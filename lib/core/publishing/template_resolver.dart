import 'template_resolution.dart';

/// Validates and resolves the single supported `${NAME}` placeholder syntax.
class TemplateResolver {
  const TemplateResolver();

  static final RegExp _placeholder = RegExp(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}');
  static final RegExp _variableName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  bool isValidVariableName(String name) => _variableName.hasMatch(name);

  String? validateTemplate(String template) {
    var consumed = 0;
    for (final match in _placeholder.allMatches(template)) {
      final skipped = template.substring(consumed, match.start);
      if (skipped.contains(r'${') || skipped.contains('}')) {
        return 'Malformed variable placeholder.';
      }
      consumed = match.end;
    }
    final remainder = template.substring(consumed);
    if (remainder.contains(r'${') || remainder.contains('}')) {
      return 'Malformed variable placeholder.';
    }
    return null;
  }

  TemplateResolution resolve(String template, Map<String, String> values) {
    final missing = <String>[];
    final value = template.replaceAllMapped(_placeholder, (match) {
      final name = match.group(1)!;
      final resolved = values[name];
      if (resolved == null || resolved.isEmpty) {
        if (!missing.contains(name)) missing.add(name);
        return match.group(0)!;
      }
      return resolved;
    });
    return TemplateResolution(value: value, missingVariables: List.unmodifiable(missing));
  }

  String validationTopic(String template) {
    return template.replaceAll(_placeholder, 'value');
  }
}
