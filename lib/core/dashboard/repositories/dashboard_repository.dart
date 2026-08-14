import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/dashboard/models/dashboard_layout_model.dart';
import '../../../core/dashboard/models/graph_card_model.dart';
import '../../broker/repositories/broker_repository.dart';
import '../../storage/preferences_store.dart';

/// Owns persisted dashboard configuration independently from live chart data.
class DashboardRepository extends ChangeNotifier {
  DashboardRepository(this._store, this._brokers);

  static const String layoutsKey = 'dashboard.layouts';
  static const String schemaVersionKey = 'dashboard.schemaVersion';
  static const int currentSchemaVersion = 1;
  static const String cardsKeyPrefix = 'dashboard.cards.';
  static const String activeLayoutKeyPrefix = 'dashboard.activeLayout.';

  final PreferencesStore _store;
  final BrokerRepository _brokers;

  Map<String, List<GraphCardModel>> _cardsByBroker = const {};
  Map<String, String?> _activeLayoutByBroker = const {};
  List<DashboardLayoutModel> _layouts = const [];
  Set<String> _knownBrokerIds = const {};
  Future<void>? _synchronizing;

  List<DashboardLayoutModel> get layouts => _layouts;

  Set<String> get brokerIds => _cardsByBroker.keys.toSet();

  List<GraphCardModel> cardsForBroker(String brokerId) => _cardsByBroker[brokerId] ?? const [];

  String? activeLayoutIdForBroker(String brokerId) => _activeLayoutByBroker[brokerId];

  Future<void> initialize() async {
    await _ensureSchema();
    _brokers.removeListener(_onBrokersChanged);
    _brokers.addListener(_onBrokersChanged);
    _knownBrokerIds = _brokers.brokers.map((broker) => broker.id).toSet();

    _layouts = List.unmodifiable(_decodeLayouts(_store.get(layoutsKey)));
    final cards = <String, List<GraphCardModel>>{};
    final active = <String, String?>{};
    for (final brokerId in _knownBrokerIds) {
      cards[brokerId] = List.unmodifiable(_decodeCards(_store.get('$cardsKeyPrefix$brokerId')));
      final rawActive = _store.get('$activeLayoutKeyPrefix$brokerId');
      active[brokerId] = rawActive is String ? rawActive : null;
    }
    _cardsByBroker = Map.unmodifiable(cards);
    _activeLayoutByBroker = Map.unmodifiable(active);
    await synchronizeBrokers();
    notifyListeners();
  }

  Future<void> _ensureSchema() async {
    final stored = _store.get(schemaVersionKey);
    if (stored == null) {
      await _store.setInt(schemaVersionKey, currentSchemaVersion);
      return;
    }
    if (stored != currentSchemaVersion) {
      throw StateError('Unsupported dashboard schema version: $stored');
    }
  }

  Future<void> setCards(String brokerId, List<GraphCardModel> cards) async {
    if (!_brokers.brokers.any((broker) => broker.id == brokerId)) {
      throw ArgumentError.value(brokerId, 'brokerId', 'Dashboard cards require an existing broker.');
    }
    _validateCards(cards);
    final immutable = List<GraphCardModel>.unmodifiable(cards);
    await _store.setString('$cardsKeyPrefix$brokerId', jsonEncode(immutable.map((card) => card.toJson()).toList()));
    _cardsByBroker = Map.unmodifiable({..._cardsByBroker, brokerId: immutable});
    notifyListeners();
  }

  Future<void> addCard(String brokerId, GraphCardModel card) async {
    final cards = [...cardsForBroker(brokerId)];
    if (cards.any((existing) => existing.id == card.id)) {
      throw ArgumentError.value(card.id, 'card.id', 'Dashboard card IDs must be unique per broker.');
    }
    await setCards(brokerId, [...cards, card]);
  }

  Future<void> setLayouts(List<DashboardLayoutModel> layouts) async {
    _validateLayouts(layouts);
    final immutable = List<DashboardLayoutModel>.unmodifiable(layouts);
    await _store.setString(layoutsKey, jsonEncode(immutable.map((layout) => layout.toJson()).toList()));
    _layouts = immutable;
    await _repairActiveLayouts();
    notifyListeners();
  }

  Future<void> setActiveLayout(String brokerId, String? layoutId) async {
    final key = '$activeLayoutKeyPrefix$brokerId';
    if (layoutId == null) {
      await _store.remove(key);
    } else {
      await _store.setString(key, layoutId);
    }
    _activeLayoutByBroker = Map.unmodifiable({..._activeLayoutByBroker, brokerId: layoutId});
    notifyListeners();
  }

  /// Removes configuration whose broker profile no longer exists.
  Future<void> synchronizeBrokers() {
    return _synchronizing ??= _synchronizeBrokers().whenComplete(() => _synchronizing = null);
  }

  Future<void> _synchronizeBrokers() async {
    final current = _brokers.brokers.map((broker) => broker.id).toSet();
    final removed = _knownBrokerIds.difference(current);
    final orphanIds = <String>{
      ...removed,
      for (final key in _store.getKeys())
        if (key.startsWith(cardsKeyPrefix) && !current.contains(key.substring(cardsKeyPrefix.length))) key.substring(cardsKeyPrefix.length),
      for (final key in _store.getKeys())
        if (key.startsWith(activeLayoutKeyPrefix) && !current.contains(key.substring(activeLayoutKeyPrefix.length))) key.substring(activeLayoutKeyPrefix.length),
    };

    for (final id in orphanIds) {
      await _store.remove('$cardsKeyPrefix$id');
      await _store.remove('$activeLayoutKeyPrefix$id');
    }

    final cards = <String, List<GraphCardModel>>{for (final id in current) id: _cardsByBroker[id] ?? const []};
    final active = <String, String?>{for (final id in current) id: _activeLayoutByBroker[id]};
    _cardsByBroker = Map.unmodifiable(cards);
    _activeLayoutByBroker = Map.unmodifiable(active);

    var layoutsChanged = false;
    final layouts = <DashboardLayoutModel>[];
    for (final layout in _layouts) {
      if (layout.isGlobal) {
        layouts.add(layout);
        continue;
      }
      final brokerIds = layout.brokerIds.where(current.contains).toList(growable: false);
      if (brokerIds.isEmpty) {
        layoutsChanged = true;
        continue;
      }
      if (brokerIds.length != layout.brokerIds.length) layoutsChanged = true;
      layouts.add(layout.copyWith(brokerIds: brokerIds));
    }
    if (layoutsChanged) {
      _layouts = List.unmodifiable(layouts);
      await _store.setString(layoutsKey, jsonEncode(_layouts.map((layout) => layout.toJson()).toList()));
    }

    _knownBrokerIds = current;
    await _repairActiveLayouts();
  }

  Future<void> _repairActiveLayouts() async {
    final validLayoutIds = _layouts.map((layout) => layout.id).toSet();
    final active = {..._activeLayoutByBroker};
    for (final entry in active.entries.toList()) {
      if (entry.value != null && !validLayoutIds.contains(entry.value)) {
        active[entry.key] = null;
        await _store.remove('$activeLayoutKeyPrefix${entry.key}');
      }
    }
    _activeLayoutByBroker = Map.unmodifiable(active);
  }

  /// Removes all saved dashboard cards, layouts, and active selections.
  Future<void> resetToDefaults() async {
    for (final key in _store.getKeys().where((key) => key == layoutsKey || key.startsWith(cardsKeyPrefix) || key.startsWith(activeLayoutKeyPrefix))) {
      await _store.remove(key);
    }
    _cardsByBroker = const {};
    _activeLayoutByBroker = const {};
    _layouts = const [];
    _knownBrokerIds = const {};
    notifyListeners();
  }

  void _onBrokersChanged() {
    unawaited(synchronizeBrokers().then((_) => notifyListeners()));
  }

  @override
  void dispose() {
    _brokers.removeListener(_onBrokersChanged);
    super.dispose();
  }
}

List<DashboardLayoutModel> _decodeLayouts(Object? raw) {
  if (raw == null) return const [];
  if (raw is! String) {
    throw const FormatException('Dashboard layouts must be stored as JSON text.');
  }
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('Dashboard layouts must be a JSON array.');
  }
  final layouts = decoded.map((value) => DashboardLayoutModel.fromJson(Map<String, dynamic>.from(value as Map))).toList(growable: false);
  _validateLayouts(layouts);
  return layouts;
}

List<GraphCardModel> _decodeCards(Object? raw) {
  if (raw == null) return const [];
  if (raw is! String) {
    throw const FormatException('Dashboard cards must be stored as JSON text.');
  }
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('Dashboard cards must be a JSON array.');
  }
  final cards = decoded.map((value) => GraphCardModel.fromJson(Map<String, dynamic>.from(value as Map))).toList(growable: false);
  _validateCards(cards);
  return cards;
}

void _validateCards(List<GraphCardModel> cards) {
  final ids = <String>{};
  for (final card in cards) {
    if (!ids.add(card.id)) {
      throw const FormatException('Dashboard card IDs must be unique per broker.');
    }
  }
}

void _validateLayouts(List<DashboardLayoutModel> layouts) {
  final ids = <String>{};
  for (final layout in layouts) {
    if (!ids.add(layout.id)) {
      throw const FormatException('Dashboard layout IDs must be unique.');
    }
    _validateCards(layout.cards);
  }
}
