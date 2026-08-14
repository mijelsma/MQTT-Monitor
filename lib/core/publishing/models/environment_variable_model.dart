import 'environment_variable_option_model.dart';

/// Immutable definition of one scoped `${NAME}` topic variable.
class EnvironmentVariableModel {
  EnvironmentVariableModel({required this.name, List<String> brokerIds = const [], List<EnvironmentVariableOptionModel> options = const []}) : brokerIds = List.unmodifiable(brokerIds), options = List.unmodifiable(options);

  final String name;
  final List<String> brokerIds;
  final List<EnvironmentVariableOptionModel> options;

  bool get isGlobal => brokerIds.isEmpty;

  EnvironmentVariableModel copyWith({String? name, List<String>? brokerIds, List<EnvironmentVariableOptionModel>? options}) {
    return EnvironmentVariableModel(name: name ?? this.name, brokerIds: brokerIds ?? this.brokerIds, options: options ?? this.options);
  }

  factory EnvironmentVariableModel.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariableModel(name: json['name'] as String, brokerIds: (json['brokerIds'] as List).cast<String>(), options: (json['options'] as List).map((value) => EnvironmentVariableOptionModel.fromJson(Map<String, dynamic>.from(value as Map))).toList(growable: false));
  }

  Map<String, dynamic> toJson() => {'name': name, 'brokerIds': brokerIds, 'options': options.map((option) => option.toJson()).toList()};
}
