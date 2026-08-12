import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/broker/broker_repository.dart';
import '../../core/history/message_history_service.dart';
import '../../core/ingestion/ingested_message.dart';
import '../../core/ingestion/message_ingestion_coordinator.dart';
import '../../core/state/app_state.dart';
import '../../core/state/keys/dashboard_keys.dart';
import '../../core/state/keys/settings_keys.dart';
import '../../models/broker_entry.dart';
import '../../models/dashboard_layout.dart';
import '../../models/data_point.dart';
import '../../models/environment_variable.dart';
import '../../models/graph_card_model.dart';
import 'dialogs/edit_graph_dialog.dart';

/// Regex that matches `${VAR_NAME}` placeholders in topic templates.
final _variablePlaceholderPattern = RegExp(r'\$\{([^}]+)\}');

/// Regex that extracts a leading number from strings like "23.5°C" or "100%".
final _numericPrefixPattern = RegExp(r'^([+-]?\d+\.?\d*)\s*[a-zA-Z°/%]');

/// Regex that matches array index segments like `[0]` in a JSON key path.
final _arrayIndexPattern = RegExp(r'^\[(\d+)\]$');

/// ViewModel for the graph dashboard screen.
///
/// Manages the collection of graph cards for one broker, listens to MQTT
/// messages to feed data into the correct cards, and persists layout to state.
class DashboardViewModel extends ChangeNotifier {
  /// Creates a broker-scoped dashboard controller and starts its listeners.
  DashboardViewModel({required MessageIngestionCoordinator ingestion, required AppStateManager state, required this.brokerId, required MessageHistoryService historyService, required BrokerRepository brokerRepository}) : _ingestion = ingestion, _state = state, _historyService = historyService, _brokers = brokerRepository {
    // Pre-load all keys needed by this screen.
    _state.load(DashboardKeys.layouts);
    _state.load(DashboardKeys.activeLayoutForBroker(brokerId));
    _state.load(SettingsKeys.environmentVariables);
    _state.load(SettingsKeys.environmentVariableValues);

    _loadCards();
    _backfillFromHistory();

    _state.addListener(_onStateChanged);
    _brokers.addListener(_onBrokersChanged);
    _subscription = _ingestion.messages.listen(_onMessage);
  }

  final MessageIngestionCoordinator _ingestion;
  final AppStateManager _state;
  final MessageHistoryService _historyService;
  final BrokerRepository _brokers;
  final String brokerId;

  StreamSubscription<IngestedMessage>? _subscription;
  Timer? _saveTimer;

  /// Static cache that keeps data points alive across screen navigations
  /// but is naturally cleared when the app restarts.
  static final Map<String, List<DataPoint>> _dataPointCache = {};

  List<GraphCardModel> _cards = [];

  /// The current set of graph cards (read-only view).
  List<GraphCardModel> get cards => List.unmodifiable(_cards);

  // ── Convenience accessors ───────────────────────────────────────────

  /// Shorthand for reading the current environment variable values from state.
  Map<String, String> get _currentVariableValues {
    return _state.read(SettingsKeys.environmentVariableValues);
  }

  /// Returns a mutable copy of all saved layouts.
  List<DashboardLayout> _mutableLayouts() {
    return List<DashboardLayout>.from(_state.read(DashboardKeys.layouts));
  }

  /// Creates a deep-copy snapshot of the current cards (for saving layouts).
  List<GraphCardModel> _snapshotCards() {
    return _cards.map((c) => GraphCardModel.fromJson(c.toJson())).toList();
  }

  /// Loads cards from persisted state and restores any cached data points.
  void _loadCards() {
    final key = DashboardKeys.cardsForBroker(brokerId);
    _state.load(key);

    _cards = List.of(_state.read(key));
    _cards.sort((a, b) => a.position.compareTo(b.position));

    // Restore in-memory data points from a previous visit.
    for (final card in _cards) {
      final cached = _dataPointCache[card.id];
      if (cached != null && cached.isNotEmpty) {
        card.dataPoints.addAll(cached);
      }
    }
  }

  /// Persists the current card list to state.
  Future<void> _saveCards() async {
    final key = DashboardKeys.cardsForBroker(brokerId);
    await _state.write(key, _cards);
  }

  /// Schedules a save after a short delay (used during rapid data ingestion).
  void _debounceSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveCards);
  }

  /// Backfills card data from the global history service when the dashboard
  /// is opened, so charts show data collected while the user was elsewhere.
  ///
  /// If a card already has cached data points (from a previous visit), only
  /// history entries newer than the last cached point are appended.
  void _backfillFromHistory() {
    final varValues = _currentVariableValues;

    for (final card in _cards) {
      final resolved = _resolveTopic(card.topic, varValues);
      final history = _historyService.getHistory(resolved);

      // Skip entries already covered by cached data.
      final cutoff = card.dataPoints.isNotEmpty ? card.dataPoints.last.timestamp : null;

      for (final entry in history) {
        if (cutoff != null && !entry.receivedAt.isAfter(cutoff)) continue;

        final value = _extractNumericValue(entry.payload, card.jsonKeyPath);
        if (value != null) {
          card.addDataPoint(DataPoint(timestamp: entry.receivedAt, value: value));
        }
      }
    }
  }

  /// Removes a graph card from the dashboard.
  void removeCard(String cardId) {
    _dataPointCache.remove(cardId);
    _cards.removeWhere((c) => c.id == cardId);
    _reindexPositions();
    _saveCards();
    notifyListeners();
  }

  /// Applies all editable properties from an [EditGraphResult] to a card.
  void updateCard(String cardId, EditGraphResult result) {
    final card = _cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return;

    // When the topic changes, clear old data and start monitoring the new one.
    if (result.topic != null && result.topic != card.topic) {
      card.topic = result.topic!;
      card.dataPoints.clear();
      _dataPointCache.remove(card.id);
    }

    card.displayName = result.displayName;
    card.unit = result.unit;
    card.color = result.color;
    card.chartType = result.chartType;
    card.interpolation = result.interpolation;
    card.dotSize = result.dotSize;
    card.showFill = result.showFill;
    card.fillOpacity = result.fillOpacity;
    card.maxDataPoints = result.maxDataPoints;
    card.yMin = result.yMin;
    card.yMax = result.yMax;

    _saveCards();
    notifyListeners();
  }

  /// Sets the grid size (columns x rows) for a card.
  void setCardSize(String cardId, int colSpan, int rowSpan) {
    final card = _cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return;
    card.colSpan = colSpan;
    card.rowSpan = rowSpan;
    _saveCards();
    notifyListeners();
  }

  /// Moves a card to a specific grid position.
  void moveCard(String cardId, int gridCol, int gridRow) {
    final card = _cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return;
    card.gridCol = gridCol;
    card.gridRow = gridRow;
    _saveCards();
    notifyListeners();
  }

  /// Validates and fixes card positions for the given column count.
  /// Returns true if any cards were repositioned.
  bool ensureValidLayout(int columns) {
    // Shrink any cards that are wider than the available columns.
    var needsPack = false;
    for (final card in _cards) {
      if (card.colSpan > columns) {
        card.colSpan = columns;
        needsPack = true;
      }
    }

    if (!needsPack) needsPack = _hasOverlaps();

    if (needsPack) {
      _packCards(columns);
      _saveCards();
    }
    return needsPack;
  }

  /// Checks whether any two cards share the same grid cell.
  bool _hasOverlaps() {
    final cells = <(int, int)>{};
    for (final card in _cards) {
      for (var row = card.gridRow; row < card.gridRow + card.rowSpan; row++) {
        for (var col = card.gridCol; col < card.gridCol + card.colSpan; col++) {
          if (!cells.add((row, col))) return true;
        }
      }
    }
    return false;
  }

  /// Re-packs all cards top-left into a grid of [columns] width,
  /// resolving any overlaps.
  void _packCards(int columns) {
    final occupied = <(int, int)>{};

    for (final card in _cards) {
      card.colSpan = card.colSpan.clamp(1, columns);
      final position = _findFirstFit(occupied: occupied, colSpan: card.colSpan, rowSpan: card.rowSpan, columns: columns);

      card.gridCol = position.col;
      card.gridRow = position.row;

      // Mark all cells this card now covers as occupied.
      for (var row = position.row; row < position.row + card.rowSpan; row++) {
        for (var col = position.col; col < position.col + card.colSpan; col++) {
          occupied.add((row, col));
        }
      }
    }
  }

  /// Finds the first (top-left) grid position where a card of the
  /// given span fits without overlapping any [occupied] cells.
  ({int row, int col}) _findFirstFit({required Set<(int, int)> occupied, required int colSpan, required int rowSpan, required int columns}) {
    for (var row = 0; ; row++) {
      for (var col = 0; col <= columns - colSpan; col++) {
        if (_fitsAt(occupied, row, col, rowSpan, colSpan)) {
          return (row: row, col: col);
        }
      }
    }
  }

  /// Returns true if a card of [rows] x [cols] fits at the given position.
  bool _fitsAt(Set<(int, int)> occupied, int row, int col, int rows, int cols) {
    for (var r = row; r < row + rows; r++) {
      for (var c = col; c < col + cols; c++) {
        if (occupied.contains((r, c))) return false;
      }
    }
    return true;
  }

  /// Handles incoming MQTT messages by routing them to matching cards.
  void _onMessage(IngestedMessage msg) {
    if (msg.brokerId != brokerId) return;
    var matched = false;
    final varValues = _currentVariableValues;

    for (final card in _cards) {
      final resolvedTopic = _resolveTopic(card.topic, varValues);
      if (resolvedTopic != msg.topic) continue;

      final value = _extractNumericValue(msg.value.payload, card.jsonKeyPath);
      if (value == null) continue;

      card.addDataPoint(DataPoint(timestamp: msg.value.receivedAt, value: value));
      matched = true;
    }

    if (matched) {
      notifyListeners();
      _debounceSave();
    }
  }

  /// Replaces `${VAR_NAME}` placeholders in a topic template with actual values.
  static String _resolveTopic(String template, Map<String, String> values) {
    return template.replaceAllMapped(_variablePlaceholderPattern, (match) => values[match.group(1)!] ?? match.group(0)!);
  }

  /// Extracts a numeric value from a raw MQTT payload.
  ///
  /// If [jsonKeyPath] is null/empty, tries to parse the payload directly
  /// as a number (e.g. "23.5" or "100%"). Otherwise, decodes JSON and
  /// walks the key path (supports dot-separated keys and `[index]` segments).
  static double? _extractNumericValue(String payload, String? jsonKeyPath) {
    // No key path → try plain numeric parsing.
    if (jsonKeyPath == null || jsonKeyPath.isEmpty) {
      final rawValue = _parseNumericString(payload.trim());
      if (rawValue != null) return rawValue;

      // A root-level JSON string (for example `"23.5"`) is a valid source
      // for a graph just like a root-level JSON number.
      try {
        final decoded = jsonDecode(payload);
        if (decoded is num) return decoded.toDouble();
        if (decoded is String) return _parseNumericString(decoded);
      } catch (_) {
        // Not JSON; the direct parsing above already handled text payloads.
      }
      return null;
    }

    // Walk the JSON structure along the key path.
    try {
      dynamic current = jsonDecode(payload);

      for (final segment in jsonKeyPath.split('.')) {
        final indexMatch = _arrayIndexPattern.firstMatch(segment);

        if (indexMatch != null) {
          // Array index segment, e.g. "[0]".
          if (current is! List) return null;
          final index = int.parse(indexMatch.group(1)!);
          if (index < 0 || index >= current.length) return null;
          current = current[index];
        } else if (current is Map<String, dynamic>) {
          // Object key segment, e.g. "temperature".
          current = current[segment];
        } else {
          return null;
        }
      }

      if (current is num) return current.toDouble();
      if (current is String) return double.tryParse(current);
    } catch (_) {
      // Malformed JSON — silently ignore.
    }
    return null;
  }

  /// Tries to parse a string as a number. Handles plain numbers ("23.5")
  /// and numbers with trailing units ("23.5°C", "100%").
  static double? _parseNumericString(String text) {
    final plain = double.tryParse(text);
    if (plain != null) return plain;

    final match = _numericPrefixPattern.firstMatch(text);
    if (match != null) return double.tryParse(match.group(1)!);

    return null;
  }

  /// All layouts visible to this broker (global + broker-scoped).
  List<DashboardLayout> get layouts {
    final all = _state.read(DashboardKeys.layouts);
    return all.where((l) => l.isGlobal || l.brokerIds.contains(brokerId)).toList();
  }

  /// The ID of the currently active layout, or null for the scratch pad.
  String? get activeLayoutId {
    return _state.read(DashboardKeys.activeLayoutForBroker(brokerId));
  }

  /// The currently active layout, or null if using the scratch pad.
  DashboardLayout? get activeLayout {
    final id = activeLayoutId;
    if (id == null) return null;
    final all = _state.read(DashboardKeys.layouts);
    return all.where((l) => l.id == id).firstOrNull;
  }

  /// Clears history and cached data points for all topics used in this dashboard.
  void clearDashboardHistory() {
    final varValues = _currentVariableValues;
    final topics = _cards.map((c) => _resolveTopic(c.topic, varValues)).toSet();
    _historyService.clearTopics(topics);
    _clearDataPointCaches();
    for (final card in _cards) {
      card.dataPoints.clear();
    }
    _saveCards();
    notifyListeners();
  }

  /// Whether the current cards differ from the active layout's saved snapshot.
  bool get hasUnsavedChanges {
    final layout = activeLayout;
    if (layout == null) return false;
    if (_cards.length != layout.cards.length) return true;
    for (var i = 0; i < _cards.length; i++) {
      final current = jsonEncode(_cards[i].toJson());
      final saved = jsonEncode(layout.cards[i].toJson());
      if (current != saved) return true;
    }
    return false;
  }

  /// Reverts the current dashboard to the saved active layout.
  Future<void> discardChanges() async {
    final id = activeLayoutId;
    if (id == null) return;
    await selectLayout(id);
  }

  /// Switches to a different layout and loads its saved cards.
  Future<void> selectLayout(String layoutId) async {
    final all = _state.read(DashboardKeys.layouts);
    final layout = all.where((l) => l.id == layoutId).firstOrNull;

    if (layout != null && layout.cards.isNotEmpty) {
      _clearDataPointCaches();
      _cards = layout.cards.map((c) => GraphCardModel.fromJson(c.toJson())).toList();
      _cards.sort((a, b) => a.position.compareTo(b.position));
      _backfillFromHistory();
      await _saveCards();
    }

    await _state.write(DashboardKeys.activeLayoutForBroker(brokerId), layoutId);
    notifyListeners();
  }

  /// Saves the current dashboard as a new named layout.
  Future<void> saveLayout({required String title, List<String> brokerIds = const [], int colorIndex = 0}) async {
    final id = 'layout_${DateTime.now().millisecondsSinceEpoch}';
    final layout = DashboardLayout(id: id, title: title, brokerIds: brokerIds, colorIndex: colorIndex, cards: _snapshotCards());

    final all = _mutableLayouts()..add(layout);
    await _state.write(DashboardKeys.layouts, all);
    await _state.write(DashboardKeys.activeLayoutForBroker(brokerId), id);
    notifyListeners();
  }

  /// Overwrites the active layout with the current card configuration.
  Future<void> updateActiveLayout() async {
    final id = activeLayoutId;
    if (id == null) return;

    final all = _mutableLayouts();
    final index = all.indexWhere((l) => l.id == id);
    if (index < 0) return;

    all[index] = all[index].copyWith(cards: _snapshotCards());
    await _state.write(DashboardKeys.layouts, all);
    notifyListeners();
  }

  /// Clears all cards and deactivates the current layout (back to scratch pad).
  Future<void> clearDashboard() async {
    _clearDataPointCaches();
    _cards = [];
    await _saveCards();
    await _state.write(DashboardKeys.activeLayoutForBroker(brokerId), null);
    notifyListeners();
  }

  /// Deletes a saved layout. If it was the active one, reverts to scratch pad.
  Future<void> deleteLayout(String layoutId) async {
    final all = _mutableLayouts()..removeWhere((l) => l.id == layoutId);
    await _state.write(DashboardKeys.layouts, all);

    if (activeLayoutId == layoutId) {
      await _state.write(DashboardKeys.activeLayoutForBroker(brokerId), null);
    }
    notifyListeners();
  }

  /// Updates a layout's metadata (title, color, scope) without changing its cards.
  Future<void> updateLayoutMetadata(DashboardLayout updated) async {
    final all = _mutableLayouts();
    final index = all.indexWhere((l) => l.id == updated.id);
    if (index < 0) return;

    all[index] = updated;
    await _state.write(DashboardKeys.layouts, all);
    notifyListeners();
  }

  /// The list of configured brokers (used for scope selection in dialogs).
  List<BrokerEntry> get brokers => _brokers.brokers;

  /// Environment variables visible to this broker (global + broker-scoped).
  List<EnvironmentVariable> get environmentVariables {
    final all = _state.read(SettingsKeys.environmentVariables);
    return all.where((v) => v.isGlobal || v.brokerIds.contains(brokerId)).toList();
  }

  /// Current values for each environment variable.
  Map<String, String> get variableValues => _currentVariableValues;

  /// Sets the value for a single environment variable and clears data
  /// on any cards whose topic references it.
  void setVariableValue(String name, String value) {
    final values = Map<String, String>.from(variableValues);
    values[name] = value;
    _state.write(SettingsKeys.environmentVariableValues, values);

    // Clear data on affected cards so they re-collect with the new topic.
    for (final card in _cards) {
      if (card.topic.contains('[$name]')) {
        card.dataPoints.clear();
        _dataPointCache.remove(card.id);
      }
    }
    notifyListeners();
  }

  /// Reassigns sequential position indices after a card is removed.
  void _reindexPositions() {
    for (var i = 0; i < _cards.length; i++) {
      _cards[i].position = i;
    }
  }

  /// Removes all data point caches for the current cards.
  void _clearDataPointCaches() {
    for (final card in _cards) {
      _dataPointCache.remove(card.id);
    }
  }

  /// Re-notifies listeners when external state changes (e.g. layout edits
  /// from the settings screen).
  void _onStateChanged() => notifyListeners();

  /// Notifies dashboard consumers when the available broker list changes.
  void _onBrokersChanged() => notifyListeners();

  /// Releases message, persistence, broker, and timer listeners.
  @override
  void dispose() {
    _subscription?.cancel();
    _saveTimer?.cancel();
    _state.removeListener(_onStateChanged);
    _brokers.removeListener(_onBrokersChanged);

    // Snapshot data points into the static cache so they survive navigation.
    for (final card in _cards) {
      _dataPointCache[card.id] = List.of(card.dataPoints);
    }
    _saveCards();
    super.dispose();
  }
}
