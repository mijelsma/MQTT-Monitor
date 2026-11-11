import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/publishing/models/publish_shortcut_model.dart';
import '../../broker/repositories/broker_repository.dart';
import '../../mqtt/mqtt_topic_name.dart';
import '../../storage/preferences_store.dart';
import '../json_payload_validator.dart';
import '../template_resolver.dart';

/// Owns validated immutable shortcut configuration and broker scope cleanup.
class ShortcutRepository extends ChangeNotifier {
  ShortcutRepository(this._store, this._brokers, this._resolver, this._jsonValidator);

  static const String schemaVersionKey = 'shortcuts.schemaVersion';
  static const String itemsKey = 'shortcuts.items';
  static const int currentSchemaVersion = 1;

  final PreferencesStore _store;
  final BrokerRepository _brokers;
  final TemplateResolver _resolver;
  final JsonPayloadValidator _jsonValidator;
  List<PublishShortcutModel> _shortcuts = const [];
  Set<String> _knownBrokerIds = const {};

  List<PublishShortcutModel> get shortcuts => _shortcuts;

  List<PublishShortcutModel> shortcutsForBroker(String brokerId) {
    return _shortcuts.where((shortcut) => shortcut.isGlobal || shortcut.brokerIds.contains(brokerId)).toList(growable: false);
  }

  Future<void> initialize() async {
    await _ensureSchema();
    _shortcuts = List.unmodifiable(_decode(_store.get(itemsKey)));
    _validateAll(_shortcuts);
    _knownBrokerIds = _shortcuts.expand((shortcut) => shortcut.brokerIds).toSet();
    _brokers.removeListener(_onBrokersChanged);
    _brokers.addListener(_onBrokersChanged);
    await synchronizeBrokers();
    notifyListeners();
  }

  Future<void> add(PublishShortcutModel shortcut) async {
    _validateBrokerScope(shortcut.brokerIds);
    if (_shortcuts.any((existing) => existing.id == shortcut.id)) {
      throw ArgumentError.value(shortcut.id, 'shortcut.id', 'Shortcut IDs must be unique.');
    }
    await _persist([..._shortcuts, shortcut]);
  }

  Future<void> update(PublishShortcutModel updated) async {
    _validateBrokerScope(updated.brokerIds);
    final index = _shortcuts.indexWhere((shortcut) => shortcut.id == updated.id);
    if (index < 0) return;
    final shortcuts = [..._shortcuts]..[index] = updated;
    await _persist(shortcuts);
  }

  /// Creates an identical shortcut with a fresh ID directly after [id].
  Future<void> duplicate(String id) async {
    final index = _shortcuts.indexWhere((shortcut) => shortcut.id == id);
    if (index < 0) return;
    var sequence = DateTime.now().microsecondsSinceEpoch;
    var duplicateId = 'shortcut_$sequence';
    while (_shortcuts.any((shortcut) => shortcut.id == duplicateId)) {
      duplicateId = 'shortcut_${++sequence}';
    }
    final shortcuts = [..._shortcuts]..insert(index + 1, _shortcuts[index].copyWith(id: duplicateId));
    await _persist(shortcuts);
  }

  Future<void> delete(String id) => _persist(_shortcuts.where((shortcut) => shortcut.id != id).toList(growable: false));

  Future<void> reorder(int oldIndex, int newIndex) async {
    final shortcuts = [..._shortcuts];
    if (oldIndex < 0 || oldIndex >= shortcuts.length || newIndex < 0 || newIndex > shortcuts.length) {
      throw RangeError('Invalid shortcut reorder.');
    }
    if (newIndex > oldIndex) newIndex--;
    final shortcut = shortcuts.removeAt(oldIndex);
    shortcuts.insert(newIndex, shortcut);
    await _persist(shortcuts);
  }

  Future<void> synchronizeBrokers() async {
    final brokerIds = _brokers.brokers.map((broker) => broker.id).toSet();
    if (setEquals(brokerIds, _knownBrokerIds)) return;
    final shortcuts = <PublishShortcutModel>[];
    var changed = false;
    for (final shortcut in _shortcuts) {
      if (shortcut.isGlobal) {
        shortcuts.add(shortcut);
        continue;
      }
      final scope = shortcut.brokerIds.where(brokerIds.contains).toList(growable: false);
      if (scope.isEmpty) {
        changed = true;
      } else {
        changed |= !listEquals(scope, shortcut.brokerIds);
        shortcuts.add(shortcut.copyWith(brokerIds: scope));
      }
    }
    _knownBrokerIds = brokerIds;
    if (changed) await _persist(shortcuts);
  }

  Future<void> resetToDefaults() async {
    await _store.remove(itemsKey);
    _shortcuts = const [];
    _knownBrokerIds = const {};
    notifyListeners();
  }

  Future<void> _ensureSchema() async {
    final version = _store.get(schemaVersionKey);
    if (version == null) {
      return _store.setInt(schemaVersionKey, currentSchemaVersion);
    }
    if (version != currentSchemaVersion) {
      throw StateError('Unsupported shortcut schema version: $version');
    }
  }

  Future<void> _persist(List<PublishShortcutModel> shortcuts) async {
    _validateAll(shortcuts);
    await _store.setString(itemsKey, jsonEncode(shortcuts.map((shortcut) => shortcut.toJson()).toList()));
    _shortcuts = List.unmodifiable(shortcuts);
    notifyListeners();
  }

  void _validateAll(List<PublishShortcutModel> shortcuts) {
    final ids = <String>{};
    for (final shortcut in shortcuts) {
      if (!ids.add(shortcut.id)) {
        throw const FormatException('Shortcut IDs must be unique.');
      }
      if (shortcut.name.trim().isEmpty) {
        throw const FormatException('Shortcut names cannot be empty.');
      }
      final templateError = _resolver.validateTemplate(shortcut.topic);
      if (templateError != null) throw FormatException(templateError);
      final topicError = MqttTopicName.validate(_resolver.validationTopic(shortcut.topic));
      if (topicError != null) throw FormatException(topicError);
      if (shortcut.qos < 0 || shortcut.qos > 2) {
        throw const FormatException('Shortcut QoS must be between 0 and 2.');
      }
      if (shortcut.payloadFormatIsJson && !_jsonValidator.isValid(shortcut.payload)) {
        throw const FormatException('Shortcut JSON payload is invalid.');
      }
      if (shortcut.brokerIds.toSet().length != shortcut.brokerIds.length) {
        throw const FormatException('Shortcut broker scope contains duplicates.');
      }
    }
  }

  void _validateBrokerScope(List<String> brokerIds) {
    final known = _brokers.brokers.map((broker) => broker.id).toSet();
    if (brokerIds.any((id) => !known.contains(id))) {
      throw const FormatException('Shortcut scope contains an unknown broker.');
    }
  }

  void _onBrokersChanged() => unawaited(synchronizeBrokers());

  @override
  void dispose() {
    _brokers.removeListener(_onBrokersChanged);
    super.dispose();
  }
}

List<PublishShortcutModel> _decode(Object? raw) {
  if (raw == null) return const [];
  if (raw is! String) {
    throw const FormatException('Shortcuts must be stored as JSON text.');
  }
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('Shortcuts must be an array.');
  }
  return decoded.map((value) => PublishShortcutModel.fromJson(Map<String, dynamic>.from(value as Map))).toList(growable: false);
}
