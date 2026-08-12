/// Result of resolving `${NAME}` placeholders in a publish or dashboard topic.
class TemplateResolution {
  const TemplateResolution({required this.value, this.missingVariables = const []});

  final String value;
  final List<String> missingVariables;

  bool get isComplete => missingVariables.isEmpty;
}
