import 'package:flutter/material.dart';

import '../../../core/dashboard/models/graph_card_model.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../view_models/dashboard_view_model.dart';
import '../dialogs/edit_graph_dialog.dart';
import 'card_tile.dart';
import 'dotted_border_painter.dart';
import 'grid_drop_target.dart';
import 'grid_metrics.dart';

/// A free-placement grid where cards can be dragged to reorder and resized
/// by dragging a corner handle. Each card occupies one or more cells
/// defined by (gridCol, gridRow, colSpan, rowSpan).
class DashboardGrid extends StatefulWidget {
  const DashboardGrid({super.key, required this.vm});

  final DashboardViewModel vm;

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid> {
  /// The card currently being dragged, or null when idle.
  String? _draggingCardId;

  /// Set when a card lands on a drop target. Applied in [onDragEnd] so the
  /// grid rebuilds after the drag overlay is dismissed (avoids visual glitches).
  ({String cardId, int col, int row})? _pendingMove;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final columns = GridMetrics.columnsForWidth(MediaQuery.sizeOf(context).width);
    vm.ensureValidLayout(columns);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = GridMetrics.fromConstraints(maxWidth: constraints.maxWidth, columns: columns);
        final maxRow = GridMetrics.computeMaxRow(vm.cards);

        // Find the card being dragged (if any) and which cells are taken.
        final draggedCard = _draggingCardId != null ? vm.cards.where((c) => c.id == _draggingCardId).firstOrNull : null;
        final occupied = _occupiedCells(vm.cards, exclude: _draggingCardId);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(GridMetrics.spacing),
          child: SizedBox(
            width: metrics.totalWidth,
            height: metrics.heightForRows(maxRow),
            child: Stack(
              children: [
                // Drop targets — behind cards, only while dragging.
                if (draggedCard != null) ..._dropTargets(metrics, occupied, draggedCard, columns, maxRow),

                // Dotted empty-cell outlines — shows the grid while dragging.
                if (_draggingCardId != null) ..._emptyCellIndicators(metrics, occupied, maxRow),

                // Card tiles — always visible.
                ..._cardTiles(metrics),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns all (row, col) cells occupied by cards, optionally
  /// excluding [exclude] (the card being dragged).
  static Set<(int, int)> _occupiedCells(List<GraphCardModel> cards, {String? exclude}) {
    final cells = <(int, int)>{};
    for (final card in cards) {
      if (card.id == exclude) continue;
      for (var r = card.gridRow; r < card.gridRow + card.rowSpan; r++) {
        for (var c = card.gridCol; c < card.gridCol + card.colSpan; c++) {
          cells.add((r, c));
        }
      }
    }
    return cells;
  }

  /// Returns all (row, col) origins where a card of [cardCols] × [cardRows]
  /// can be placed without overlapping [occupied] cells.
  static Set<(int, int)> _validDropPositions({required Set<(int, int)> occupied, required int cardCols, required int cardRows, required int gridColumns, required int maxRow}) {
    final positions = <(int, int)>{};
    for (var row = 0; row <= maxRow - cardRows; row++) {
      for (var col = 0; col <= gridColumns - cardCols; col++) {
        var fits = true;
        for (var r = row; r < row + cardRows && fits; r++) {
          for (var c = col; c < col + cardCols && fits; c++) {
            if (occupied.contains((r, c))) fits = false;
          }
        }
        if (fits) positions.add((row, col));
      }
    }
    return positions;
  }

  /// Invisible drop targets at each valid position for the dragged card.
  List<Widget> _dropTargets(GridMetrics metrics, Set<(int, int)> occupied, GraphCardModel draggedCard, int columns, int maxRow) {
    final positions = _validDropPositions(occupied: occupied, cardCols: draggedCard.colSpan, cardRows: draggedCard.rowSpan, gridColumns: columns, maxRow: maxRow);

    return [
      for (final (row, col) in positions)
        Positioned(
          left: col * metrics.strideX,
          top: row * metrics.strideY,
          child: GridDropTarget(
            width: metrics.widthForCols(draggedCard.colSpan),
            height: metrics.heightForRows(draggedCard.rowSpan),
            onAccept: (cardId) {
              _pendingMove = (cardId: cardId, col: col, row: row);
            },
          ),
        ),
    ];
  }

  /// Faint dotted-border outlines for empty cells — reveals the grid
  /// structure while the user is dragging a card.
  List<Widget> _emptyCellIndicators(GridMetrics metrics, Set<(int, int)> occupied, int maxRow) {
    final color = context.tokens.border.withValues(alpha: 1);

    return [
      for (var row = 0; row < maxRow; row++)
        for (var col = 0; col < metrics.columns; col++)
          if (!occupied.contains((row, col)))
            Positioned(
              left: col * metrics.strideX,
              top: row * metrics.strideY,
              child: IgnorePointer(
                child: SizedBox(
                  width: metrics.cellWidth,
                  height: GridMetrics.cellHeight,
                  child: CustomPaint(painter: DottedBorderPainter(color: color)),
                ),
              ),
            ),
    ];
  }

  /// Draggable, resizable card tiles for each dashboard card.
  List<Widget> _cardTiles(GridMetrics metrics) {
    final vm = widget.vm;

    return [
      for (final card in vm.cards)
        Positioned(
          key: ValueKey('card_${card.id}'),
          left: card.gridCol * metrics.strideX,
          top: card.gridRow * metrics.strideY,
          child: CardTile(
            card: card,
            series: vm.seriesFor(card.id),
            width: metrics.widthForCols(card.colSpan).clamp(0.0, metrics.totalWidth),
            height: metrics.heightForRows(card.rowSpan),
            metrics: metrics,
            onEdit: () => _showEditDialog(card),
            onRemove: () => vm.removeCard(card.id),
            onResize: (cols, rows) => vm.setCardSize(card.id, cols, rows),
            onDragStarted: () => setState(() => _draggingCardId = card.id),
            onDragEnd: () {
              final pending = _pendingMove;
              _pendingMove = null;
              if (pending != null) {
                vm.moveCard(pending.cardId, pending.col, pending.row);
              }
              setState(() => _draggingCardId = null);
            },
          ),
        ),
    ];
  }

  /// Shows the edit dialog for a card and applies changes via the ViewModel.
  void _showEditDialog(GraphCardModel card) async {
    final vm = widget.vm;
    final result = await showEditGraphDialog(context, card: card, onDelete: () => vm.removeCard(card.id));
    if (result != null) {
      vm.updateCard(card.id, result);
    }
  }
}
