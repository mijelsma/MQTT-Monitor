import 'environment_variable_option.dart';

/// Immutable definition of one scoped `${NAME}` topic variable.
class EnvironmentVariable {
  EnvironmentVariable({required this.name, List<String> brokerIds = const [], List<EnvironmentVariableOption> options = const []}) : brokerIds = List.unmodifiable(brokerIds), options = List.unmodifiable(options);

  final String name;
  final List<String> brokerIds;
  final List<EnvironmentVariableOption> options;

  bool get isGlobal => brokerIds.isEmpty;

  EnvironmentVariable copyWith({String? name, List<String>? brokerIds, List<EnvironmentVariableOption>? options}) {
    return EnvironmentVariable(name: name ?? this.name, brokerIds: brokerIds ?? this.brokerIds, options: options ?? this.options);
  }

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariable(name: json['name'] as String, brokerIds: (json['brokerIds'] as List).cast<String>(), options: (json['options'] as List).map((value) => EnvironmentVariableOption.fromJson(Map<String, dynamic>.from(value as Map))).toList(growable: false));
  }

  Map<String, dynamic> toJson() => {'name': name, 'brokerIds': brokerIds, 'options': options.map((option) => option.toJson()).toList()};
}
