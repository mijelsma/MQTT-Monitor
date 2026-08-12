import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/environment_variable.dart';
import '../broker/broker_repository.dart';
import '../storage/preferences_store.dart';
import 'template_resolver.dart';

/// Owns immutable variable definitions, current values, scope, and persistence.
class VariableRepository extends ChangeNotifier {
  VariableRepository(this._store, this._brokers, this._resolver);

  static const String schemaVersionKey = 'variables.schemaVersion';
  static const String snapshotKey = 'variables.snapshot';
  static const int currentSchemaVersion = 1;

  final PreferencesStore _store;
  final BrokerRepository _brokers;
  final TemplateResolver _resolver;

  List<EnvironmentVariable> _variables = const [];
  Map<String, String> _values = const {};
  Set<String> _knownBrokerIds = const {};

  List<EnvironmentVariable> get variables => _variables;
  Map<String, String> get values => _values;

  List<EnvironmentVariable> variablesForBroker(String? brokerId) {
    return _variables.where((variable) => variable.isGlobal || (brokerId != null && variable.brokerIds.contains(brokerId))).toList(growable: false);
  }

  Map<String, String> valuesForBroker(String? brokerId) {
    final visibleNames = variablesForBroker(brokerId).map((variable) => variable.name).toSet();
    return Map.unmodifiable(Map.fromEntries(_values.entries.where((entry) => visibleNames.contains(entry.key))));
  }

  Future<void> initialize() async {
    await _ensureSchema();
    final snapshot = _decodeSnapshot(_store.get(snapshotKey));
    _variables = List.unmodifiable(snapshot.variables);
    _values = Map.unmodifiable(snapshot.values);
    _validateVariables(_variables);
    final names = _variables.map((variable) => variable.name).toSet();
    if (_values.keys.any((name) => !names.contains(name))) {
      throw const FormatException('Variable values contain an unknown variable.');
    }
    _knownBrokerIds = _variables.expand((variable) => variable.brokerIds).toSet();
    _brokers.removeListener(_onBrokersChanged);
    _brokers.addListener(_onBrokersChanged);
    await synchronizeBrokers();
    notifyListeners();
  }

  Future<void> add(EnvironmentVariable variable) async {
    _validateVariable(variable);
    _validateBrokerScope(variable.brokerIds);
    if (_variables.any((existing) => existing.name == variable.name)) {
      throw ArgumentError.value(variable.name, 'variable.name', 'Variable names must be unique.');
    }
    await _persistVariables([..._variables, variable]);
  }

  Future<void> update(String oldName, EnvironmentVariable updated) async {
    _validateVariable(updated);
    _validateBrokerScope(updated.brokerIds);
    final index = _variables.indexWhere((variable) => variable.name == oldName);
    if (index < 0) return;
    if (updated.name != oldName && _variables.any((variable) => variable.name == updated.name)) {
      throw ArgumentError.value(updated.name, 'updated.name', 'Variable names must be unique.');
    }
    final variables = [..._variables]..[index] = updated;
    var values = _values;
    if (updated.name != oldName && _values.containsKey(oldName)) {
      values = {..._values, updated.name: _values[oldName]!}..remove(oldName);
    }
    await _writeSnapshot(variables, values);
  }

  Future<void> delete(String name) async {
    final variables = _variables.where((variable) => variable.name != name).toList(growable: false);
    final values = {..._values}..remove(name);
    await _writeSnapshot(variables, values);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final variables = [..._variables];
    if (oldIndex < 0 || oldIndex >= variables.length || newIndex < 0 || newIndex > variables.length) {
      throw RangeError('Invalid variable reorder.');
    }
    if (newIndex > oldIndex) newIndex--;
    final variable = variables.removeAt(oldIndex);
    variables.insert(newIndex, variable);
    await _persistVariables(variables);
  }

  Future<void> setValue(String name, String value) async {
    if (!_variables.any((variable) => variable.name == name)) return;
    final values = {..._values, name: value};
    await _persistValues(values);
  }

  Future<void> synchronizeBrokers() async {
    final brokerIds = _brokers.brokers.map((broker) => broker.id).toSet();
    if (setEquals(brokerIds, _knownBrokerIds)) return;
    final variables = <EnvironmentVariable>[];
    final removedNames = <String>{};
    var changed = false;
    for (final variable in _variables) {
      if (variable.isGlobal) {
        variables.add(variable);
        continue;
      }
      final scope = variable.brokerIds.where(brokerIds.contains).toList(growable: false);
      if (scope.isEmpty) {
        removedNames.add(variable.name);
      } else {
        changed |= !listEquals(scope, variable.brokerIds);
        variables.add(variable.copyWith(brokerIds: scope));
      }
    }
    final values = {..._values}..removeWhere((name, _) => removedNames.contains(name));
    _knownBrokerIds = brokerIds;
    if (changed || removedNames.isNotEmpty) {
      await _writeSnapshot(variables, values);
    }
  }

  Future<void> resetAfterPreferencesClear() async {
    await _store.remove(snapshotKey);
    await _store.remove(schemaVersionKey);
    _variables = const [];
    _values = const {};
    _knownBrokerIds = const {};
    notifyListeners();
  }

  Future<void> _ensureSchema() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      return _store.setInt(schemaVersionKey, currentSchemaVersion);
    }
    if (version != currentSchemaVersion) {
      throw StateError('Unsupported variable schema version: $version');
    }
  }

  Future<void> _persistVariables(List<EnvironmentVariable> variables) => _writeSnapshot(variables, _values);
  Future<void> _persistValues(Map<String, String> values) => _writeSnapshot(_variables, values);

  Future<void> _writeSnapshot(List<EnvironmentVariable> variables, Map<String, String> values) async {
    _validateVariables(variables);
    await _store.setString(snapshotKey, jsonEncode({'definitions': variables.map((variable) => variable.toJson()).toList(), 'values': values}));
    _variables = List.unmodifiable(variables);
    _values = Map.unmodifiable(values);
    notifyListeners();
  }

  void _validateVariables(List<EnvironmentVariable> variables) {
    final names = <String>{};
    for (final variable in variables) {
      _validateVariable(variable);
      if (!names.add(variable.name)) {
        throw const FormatException('Variable names must be unique.');
      }
    }
  }

  void _validateVariable(EnvironmentVariable variable) {
    if (!_resolver.isValidVariableName(variable.name)) {
      throw ArgumentError.value(variable.name, 'variable.name', 'Invalid variable name.');
    }
    if (variable.brokerIds.toSet().length != variable.brokerIds.length) {
      throw const FormatException('Variable broker scope contains duplicates.');
    }
  }

  void _validateBrokerScope(List<String> brokerIds) {
    final known = _brokers.brokers.map((broker) => broker.id).toSet();
    if (brokerIds.any((id) => !known.contains(id))) {
      throw const FormatException('Variable scope contains an unknown broker.');
    }
  }

  void _onBrokersChanged() => unawaited(synchronizeBrokers());

  @override
  void dispose() {
    _brokers.removeListener(_onBrokersChanged);
    super.dispose();
  }
}

({List<EnvironmentVariable> variables, Map<String, String> values}) _decodeSnapshot(Object? raw) {
  if (raw == null) return (variables: const [], values: const {});
  if (raw is! String) {
    throw const FormatException('Variable snapshot must be JSON text.');
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Variable snapshot must be an object.');
  }
  final definitions = decoded['definitions'];
  final values = decoded['values'];
  if (definitions is! List || values is! Map) {
    throw const FormatException('Variable snapshot fields are invalid.');
  }
  final variables = definitions.map((value) => EnvironmentVariable.fromJson(Map<String, dynamic>.from(value as Map))).toList(growable: false);
  return (variables: variables, values: Map<String, String>.from(values));
}
