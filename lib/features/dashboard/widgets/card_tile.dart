import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/data_point.dart';
import '../../../models/graph_card_model.dart';
import '../../../shared/widgets/graph_card.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import 'grid_metrics.dart';
import 'resize_grip_painter.dart';

/// Wraps a [GraphCard] with drag-to-move and drag-to-resize behavior.
class CardTile extends StatefulWidget {
  const CardTile({super.key, required this.card, required this.series, required this.width, required this.height, required this.metrics, required this.onEdit, required this.onRemove, required this.onResize, required this.onDragStarted, required this.onDragEnd});

  final GraphCardModel card;
  final ValueListenable<List<DataPoint>> series;
  final double width;
  final double height;
  final GridMetrics metrics;

  /// Called when the user finishes resizing with the new span.
  final void Function(int cols, int rows) onResize;

  // Callbacks for edit, remove, and drag events
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  /// Accumulated drag distance during a resize gesture.
  double _resizeDeltaX = 0;
  double _resizeDeltaY = 0;

  bool _isResizing = false;
  bool _isDragging = false;

  /// The column/row span the card would snap to at the current drag position.
  (int cols, int rows) get _previewSpan {
    final m = widget.metrics;
    final maxCols = m.columns - widget.card.gridCol;
    final cols = m.snapCols(widget.width + _resizeDeltaX, maxCols: maxCols);
    final rows = m.snapRows(widget.height + _resizeDeltaY);
    return (cols, rows);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = widget.card;
    final m = widget.metrics;

    final (previewCols, previewRows) = _isResizing ? _previewSpan : (card.colSpan, card.rowSpan);
    final previewWidth = m.widthForCols(previewCols);
    final previewHeight = m.heightForRows(previewRows);
    final spanChanged = _isResizing && (previewCols != card.colSpan || previewRows != card.rowSpan);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card with drag-to-move.
          Positioned.fill(child: _buildDraggable(card)),

          // Resize outline preview.
          if (_isResizing && !_isDragging) _buildResizePreview(tokens, previewWidth, previewHeight, spanChanged),

          // Resize handle (hidden while dragging).
          if (!_isDragging) _buildResizeHandle(tokens, previewWidth, previewHeight),
        ],
      ),
    );
  }

  /// The card content wrapped in a [Draggable] for drag-to-move reordering.
  Widget _buildDraggable(GraphCardModel card) {
    return Draggable<String>(
      data: card.id,
      onDragStarted: () {
        setState(() => _isDragging = true);
        widget.onDragStarted();
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
        widget.onDragEnd();
      },
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Opacity(
            opacity: 0.85,
            child: GraphCard(model: card, dataPoints: widget.series.value),
          ),
        ),
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: RepaintBoundary(
        child: ValueListenableBuilder<List<DataPoint>>(
          valueListenable: widget.series,
          builder: (context, dataPoints, _) => GraphCard(model: card, dataPoints: dataPoints, onEdit: widget.onEdit, onRemove: widget.onRemove),
        ),
      ),
    );
  }

  /// Animated outline shown during a resize gesture. Highlights when the
  /// snapped span differs from the current span.
  Widget _buildResizePreview(AppTokens tokens, double width, double height, bool spanChanged) {
    return Positioned(
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: spanChanged ? tokens.primary.withValues(alpha: 0.07) : Colors.transparent,
            border: Border.all(color: tokens.primary.withValues(alpha: spanChanged ? 0.5 : 0.15), width: 1.5),
          ),
        ),
      ),
    );
  }

  /// Bottom-right grip handle. Tracks pan gestures to resize the card and
  /// commits the new span on release only if it actually changed.
  Widget _buildResizeHandle(AppTokens tokens, double previewWidth, double previewHeight) {
    return AnimatedPositioned(
      duration: _isResizing ? const Duration(milliseconds: 120) : Duration.zero,
      curve: Curves.easeOut,
      left: previewWidth - GridMetrics.handleSize,
      top: previewHeight - GridMetrics.handleSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => setState(() {
          _isResizing = true;
          _resizeDeltaX = 0;
          _resizeDeltaY = 0;
        }),
        onPanUpdate: (d) => setState(() {
          _resizeDeltaX += d.delta.dx;
          _resizeDeltaY += d.delta.dy;
        }),
        onPanEnd: (_) {
          final (cols, rows) = _previewSpan;
          if (cols != widget.card.colSpan || rows != widget.card.rowSpan) {
            widget.onResize(cols, rows);
          }
          setState(() => _isResizing = false);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: SizedBox(
            width: GridMetrics.handleSize,
            height: GridMetrics.handleSize,
            child: CustomPaint(painter: ResizeGripPainter(color: _isResizing ? tokens.primary : tokens.textTertiary)),
          ),
        ),
      ),
    );
  }
}
