import 'graph_card_model.dart';

class DashboardLayout {
  DashboardLayout({required this.id, required this.title, List<String> brokerIds = const [], this.colorIndex = 0, List<GraphCardModel> cards = const []}) : brokerIds = List.unmodifiable(brokerIds), cards = List.unmodifiable(cards);

  final String id;
  final String title;

  /// When empty the layout is global (works across any broker).
  /// When set it is scoped to those specific brokers.
  final List<String> brokerIds;

  /// Color index into [AppColors.brokerColorOptions].
  final int colorIndex;

  /// Snapshot of the graph cards in this layout.
  final List<GraphCardModel> cards;

  bool get isGlobal => brokerIds.isEmpty;

  DashboardLayout copyWith({String? title, List<String>? brokerIds, int? colorIndex, List<GraphCardModel>? cards}) {
    return DashboardLayout(id: id, title: title ?? this.title, brokerIds: brokerIds ?? this.brokerIds, colorIndex: colorIndex ?? this.colorIndex, cards: cards ?? this.cards);
  }

  factory DashboardLayout.fromJson(Map<String, dynamic> json) {
    final ids = (json['brokerIds'] as List?)?.cast<String>() ?? [];
    final rawCards = (json['cards'] as List?) ?? [];
    final cards = rawCards.map((e) => GraphCardModel.fromJson(e as Map<String, dynamic>)).toList();
    return DashboardLayout(id: json['id'] as String, title: json['title'] as String, brokerIds: ids, colorIndex: json['colorIndex'] as int? ?? 0, cards: cards);
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'brokerIds': brokerIds, 'colorIndex': colorIndex, 'cards': cards.map((c) => c.toJson()).toList()};
}
