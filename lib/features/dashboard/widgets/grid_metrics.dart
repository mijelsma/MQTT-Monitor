import '../../../core/dashboard/models/graph_card_model.dart';

/// Holds grid layout constants and computed cell dimensions.
///
/// Created once per layout pass in [DashboardGrid] and passed down
/// to children that need sizing information.
class GridMetrics {
  GridMetrics({required this.cellWidth, required this.columns});

  /// Creates metrics from the parent's constraint width and column count.
  /// Accounts for outer padding and inter-cell spacing.
  factory GridMetrics.fromConstraints({required double maxWidth, required int columns}) {
    final contentWidth = maxWidth - spacing * 2;
    final cellWidth = (contentWidth - spacing * (columns - 1)) / columns;
    return GridMetrics(cellWidth: cellWidth, columns: columns);
  }

  // Constants
  static const double cellHeight = 180.0;
  static const double spacing = 8.0;
  static const double handleSize = 32.0;
  static const int maxRowSpan = 4;
  static const int maxGridRows = 50;
  static const int minVisibleRows = 3;

  // Computed properties
  final double cellWidth;
  final int columns;

  /// Total content width (all columns and gaps, without outer padding).
  double get totalWidth => widthForCols(columns);

  /// Distance between cell origins (cell size + gap).
  double get strideX => cellWidth + spacing;
  double get strideY => cellHeight + spacing;

  /// Converts a column/row span into pixel dimensions.
  double widthForCols(int cols) => cellWidth * cols + spacing * (cols - 1);
  double heightForRows(int rows) => cellHeight * rows + spacing * (rows - 1);

  /// Snaps a raw pixel width to the nearest column span, clamped.
  int snapCols(double pixelWidth, {required int maxCols}) {
    return (pixelWidth / strideX).round().clamp(1, maxCols);
  }

  /// Snaps a raw pixel height to the nearest row span, clamped.
  int snapRows(double pixelHeight) {
    return (pixelHeight / strideY).round().clamp(1, maxRowSpan);
  }

  /// Responsive column count based on screen width breakpoints.
  static int columnsForWidth(double screenWidth) {
    if (screenWidth > 1200) return 6;
    if (screenWidth > 800) return 4;
    if (screenWidth > 500) return 3;
    if (screenWidth > 300) return 2;
    return 1;
  }

  /// Computes the total grid rows needed to contain all [cards],
  /// plus padding rows for drop targets below.
  static int computeMaxRow(List<GraphCardModel> cards) {
    var maxRow = 0;
    for (final card in cards) {
      final bottom = card.gridRow + card.rowSpan;
      if (bottom > maxRow) maxRow = bottom;
    }
    return (maxRow + 2).clamp(minVisibleRows, maxGridRows);
  }
}
