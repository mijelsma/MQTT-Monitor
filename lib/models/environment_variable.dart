/// A named placeholder variable that can be used inside chart topic strings.
///
/// For example, a variable named `ID` lets you write topics like
/// `my/sensor/[ID]/value`. The app substitutes the current value at runtime.
class EnvironmentVariable {
  EnvironmentVariable({required this.name, this.brokerIds = const [], List<EnvironmentVariableOption>? options}) : options = options ?? [];

  String name;

  /// When empty the variable is global (available for any broker).
  /// When set it is scoped to those specific brokers.
  final List<String> brokerIds;

  final List<EnvironmentVariableOption> options;

  bool get isGlobal => brokerIds.isEmpty;

  EnvironmentVariable copyWith({String? name, List<String>? brokerIds, List<EnvironmentVariableOption>? options}) {
    return EnvironmentVariable(
      name: name ?? this.name,
      brokerIds: brokerIds ?? this.brokerIds,
      options: options ?? this.options, //
    );
  }

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariable(
      name: json['name'] as String,
      brokerIds: (json['brokerIds'] as List?)?.cast<String>() ?? [],
      options: (json['options'] as List?)?.map((e) => EnvironmentVariableOption.fromJson(e as Map<String, dynamic>)).toList() ?? [], //
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'brokerIds': brokerIds,
    'options': options.map((e) => e.toJson()).toList(), //
  };
}

/// A pre-defined option for an environment variable, with a human-readable
/// label and the actual value to substitute into the topic string.
class EnvironmentVariableOption {
  EnvironmentVariableOption({required this.label, required this.value});

  String label;
  String value;

  factory EnvironmentVariableOption.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariableOption(
      label: json['label'] as String,
      value: json['value'] as String, //
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value, //
  };
}
