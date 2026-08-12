class EnvironmentVariableOption {
  const EnvironmentVariableOption({required this.label, required this.value});

  final String label;
  final String value;

  factory EnvironmentVariableOption.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariableOption(label: json['label'] as String, value: json['value'] as String);
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}
