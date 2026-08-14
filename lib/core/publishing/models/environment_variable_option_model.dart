class EnvironmentVariableOptionModel {
  const EnvironmentVariableOptionModel({required this.label, required this.value});

  final String label;
  final String value;

  factory EnvironmentVariableOptionModel.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariableOptionModel(label: json['label'] as String, value: json['value'] as String);
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}
