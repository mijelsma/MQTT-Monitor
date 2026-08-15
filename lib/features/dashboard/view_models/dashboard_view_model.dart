import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/broker/repositories/broker_repository.dart';
import '../../../core/dashboard/repositories/dashboard_repository.dart';
import '../../../core/dashboard/dashboard_series_policy.dart';
import '../../../core/dashboard/dashboard_series_store.dart';
import '../../../core/history/services/message_history_service.dart';
import '../../../core/publishing/template_resolver.dart';
import '../../../core/publishing/repositories/variable_repository.dart';
import '../../../core/broker/models/broker_entry_model.dart';
import '../../../core/dashboard/models/dashboard_layout_model.dart';
import '../../../core/dashboard/models/data_point_model.dart';
import '../../../core/publishing/models/environment_variable_model.dart';
import '../../../core/dashboard/models/graph_card_model.dart';
import '../dialogs/edit_graph_dialog.dart';

/// Coordinates one dashboard route while repositories own its actual state.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required DashboardRepository repository,
    required DashboardSeriesStore seriesStore,
    required VariableRepository variableRepository,
    required TemplateResolver templateResolver,
    required this.brokerId,
    required MessageHistoryService historyService,
    required BrokerRepository brokerRepository,
  }) : _repository = repository,
       _seriesStore = seriesStore,
       _variables = variableRepository,
       _templateResolver = templateResolver,
       _historyService = historyService,
       _brokers = brokerRepository {
    _repository.addListener(_onConfigurationChanged);
    _variables.addListener(_onStateChanged);
    _brokers.addListener(_onConfigurationChanged);
  }

  final DashboardRepository _repository;
  final DashboardSeriesStore _seriesStore;
  final VariableRepository _variables;
  final TemplateResolver _templateResolver;
  final MessageHistoryService _historyService;
  final BrokerRepository _brokers;
  final String brokerId;

  List<GraphCardModel> get cards {
    final cards = [..._repository.cardsForBroker(brokerId)];
    cards.sort((a, b) => a.position.compareTo(b.position));
    return List.unmodifiable(cards);
  }

  ValueListenable<List<DataPointModel>> seriesFor(String cardId) =>
      _seriesStore.seriesFor(brokerId, cardId);

  Map<String, String> get variableValues =>
      _variables.valuesForBroker(brokerId);

  List<DashboardLayoutModel> get layouts => _repository.layouts
      .where((layout) => layout.isGlobal || layout.brokerIds.contains(brokerId))
      .toList(growable: false);

  String? get activeLayoutId => _repository.activeLayoutIdForBroker(brokerId);

  DashboardLayoutModel? get activeLayout {
    final id = activeLayoutId;
    return id == null
        ? null
        : _repository.layouts.where((layout) => layout.id == id).firstOrNull;
  }

  List<BrokerEntryModel> get brokers => _brokers.brokers;

  List<EnvironmentVariableModel> get environmentVariables {
    return _variables.variablesForBroker(brokerId);
  }

  void removeCard(String cardId) {
    final remaining = cards.where((card) => card.id != cardId).toList();
    final reindexed = [
      for (var index = 0; index < remaining.length; index++)
        remaining[index].copyWith(position: index),
    ];
    unawaited(_repository.setCards(brokerId, reindexed));
  }

  void updateCard(String cardId, EditGraphResult result) {
    final updated = [
      for (final card in cards)
        if (card.id == cardId)
          card.copyWith(
            topic: result.topic,
            jsonKeyPath: () => result.jsonKeyPath,
            displayName: result.displayName,
            unit: result.unit,
            clearUnit: result.unit == null,
            colorValue: result.color.toARGB32(),
            chartType: result.chartType,
            interpolation: result.interpolation,
            dotSize: result.dotSize,
            showFill: result.showFill,
            fillOpacity: result.fillOpacity,
            maxDataPoints: DashboardSeriesPolicy.normalize(
              result.maxDataPoints,
            ),
            yMin: () => result.yMin,
            yMax: () => result.yMax,
          )
        else
          card,
    ];
    unawaited(_repository.setCards(brokerId, updated));
  }

  void setCardSize(String cardId, int colSpan, int rowSpan) {
    unawaited(
      _repository.setCards(brokerId, [
        for (final card in cards)
          card.id == cardId
              ? card.copyWith(colSpan: colSpan, rowSpan: rowSpan)
              : card,
      ]),
    );
  }

  void moveCard(String cardId, int gridCol, int gridRow) {
    unawaited(
      _repository.setCards(brokerId, [
        for (final card in cards)
          card.id == cardId
              ? card.copyWith(gridCol: gridCol, gridRow: gridRow)
              : card,
      ]),
    );
  }

  bool ensureValidLayout(int columns) {
    final current = cards;
    final mustPack =
        current.any((card) => card.colSpan > columns) || _hasOverlaps(current);
    if (!mustPack) return false;
    unawaited(_repository.setCards(brokerId, _packCards(current, columns)));
    return true;
  }

  void clearDashboardHistory() {
    final topics = cards
        .map((card) => _templateResolver.resolve(card.topic, variableValues))
        .where((resolution) => resolution.isComplete)
        .map((resolution) => resolution.value)
        .toSet();
    _historyService.clearTopics(topics);
    _seriesStore.clearCards(brokerId, cards.map((card) => card.id));
  }

  bool get hasUnsavedChanges {
    final layout = activeLayout;
    if (layout == null || cards.length != layout.cards.length) {
      return layout != null;
    }
    for (var index = 0; index < cards.length; index++) {
      if (jsonEncode(cards[index].toJson()) !=
          jsonEncode(layout.cards[index].toJson())) {
        return true;
      }
    }
    return false;
  }

  Future<void> discardChanges() async {
    final id = activeLayoutId;
    if (id != null) await selectLayout(id);
  }

  Future<void> selectLayout(String layoutId) async {
    final layout = _repository.layouts
        .where((candidate) => candidate.id == layoutId)
        .firstOrNull;
    if (layout == null) return;
    await _repository.setCards(
      brokerId,
      [...layout.cards]..sort((a, b) => a.position.compareTo(b.position)),
    );
    await _repository.setActiveLayout(brokerId, layoutId);
  }

  Future<void> saveLayout({
    required String title,
    List<String> brokerIds = const [],
    int colorIndex = 0,
  }) async {
    final id = 'layout_${DateTime.now().microsecondsSinceEpoch}';
    final layout = DashboardLayoutModel(
      id: id,
      title: title,
      brokerIds: List.unmodifiable(brokerIds),
      colorIndex: colorIndex,
      cards: cards,
    );
    await _repository.setLayouts([..._repository.layouts, layout]);
    await _repository.setActiveLayout(brokerId, id);
  }

  Future<void> updateActiveLayout() async {
    final id = activeLayoutId;
    if (id == null) return;
    await _repository.setLayouts([
      for (final layout in _repository.layouts)
        layout.id == id ? layout.copyWith(cards: cards) : layout,
    ]);
  }

  Future<void> clearDashboard() async {
    _seriesStore.clearCards(brokerId, cards.map((card) => card.id));
    await _repository.setCards(brokerId, const []);
    await _repository.setActiveLayout(brokerId, null);
  }

  Future<void> deleteLayout(String layoutId) async {
    await _repository.setLayouts(
      _repository.layouts
          .where((layout) => layout.id != layoutId)
          .toList(growable: false),
    );
  }

  Future<void> updateLayoutMetadata(DashboardLayoutModel updated) async {
    await _repository.setLayouts([
      for (final layout in _repository.layouts)
        layout.id == updated.id ? updated : layout,
    ]);
  }

  void setVariableValue(String name, String value) {
    unawaited(_variables.setValue(name, value));
  }

  void _onConfigurationChanged() => notifyListeners();

  void _onStateChanged() => notifyListeners();

  @override
  void dispose() {
    _repository.removeListener(_onConfigurationChanged);
    _variables.removeListener(_onStateChanged);
    _brokers.removeListener(_onConfigurationChanged);
    super.dispose();
  }
}

bool _hasOverlaps(List<GraphCardModel> cards) {
  final occupied = <(int, int)>{};
  for (final card in cards) {
    for (var row = card.gridRow; row < card.gridRow + card.rowSpan; row++) {
      for (var col = card.gridCol; col < card.gridCol + card.colSpan; col++) {
        if (!occupied.add((row, col))) return true;
      }
    }
  }
  return false;
}

List<GraphCardModel> _packCards(List<GraphCardModel> cards, int columns) {
  final occupied = <(int, int)>{};
  final packed = <GraphCardModel>[];
  for (final original in cards) {
    final colSpan = original.colSpan.clamp(1, columns);
    var row = 0;
    var placed = false;
    while (!placed) {
      for (var col = 0; col <= columns - colSpan; col++) {
        if (_fitsAt(occupied, row, col, original.rowSpan, colSpan)) {
          final card = original.copyWith(
            colSpan: colSpan,
            gridCol: col,
            gridRow: row,
          );
          packed.add(card);
          for (var usedRow = row; usedRow < row + card.rowSpan; usedRow++) {
            for (var usedCol = col; usedCol < col + card.colSpan; usedCol++) {
              occupied.add((usedRow, usedCol));
            }
          }
          placed = true;
          break;
        }
      }
      if (!placed) row++;
    }
  }
  return packed;
}

bool _fitsAt(Set<(int, int)> occupied, int row, int col, int rows, int cols) {
  for (var candidateRow = row; candidateRow < row + rows; candidateRow++) {
    for (var candidateCol = col; candidateCol < col + cols; candidateCol++) {
      if (occupied.contains((candidateRow, candidateCol))) return false;
    }
  }
  return true;
}
