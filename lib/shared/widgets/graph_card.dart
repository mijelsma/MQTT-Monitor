import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/chart_type.dart';
import '../../models/data_point.dart';
import '../../models/graph_card_model.dart';
import '../../models/interpolation_mode.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens/app_tokens.dart';

/// A reusable card widget that renders a live-updating line or bar chart
/// for a single tracked MQTT value.
class GraphCard extends StatelessWidget {
  const GraphCard({super.key, required this.model, this.onEdit, this.onRemove});

  final GraphCardModel model;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(model: model, onEdit: onEdit, onRemove: onRemove),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 4),
              child: model.dataPoints.isEmpty
                  ? _EmptyChart(tokens: tokens)
                  : model.chartType == ChartType.line
                  ? _LineChart(model: model, tokens: tokens)
                  : _BarChart(model: model, tokens: tokens),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.model, this.onEdit, this.onRemove});

  final GraphCardModel model;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final lastValue = model.dataPoints.isNotEmpty ? model.dataPoints.last.value.toStringAsFixed(2) : '—';
    final unitSuffix = model.unit != null && model.unit!.isNotEmpty ? ' ${model.unit}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: model.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.displayName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$lastValue$unitSuffix',
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
          if (onEdit != null || onRemove != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 16, color: tokens.textTertiary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 16,
              itemBuilder: (_) => [
                if (onEdit != null) PopupMenuItem(value: 'edit', child: _menuItem(Icons.edit_rounded, 'Edit')),
                if (onRemove != null) ...[const PopupMenuDivider(), PopupMenuItem(value: 'remove', child: _menuItem(Icons.delete_outline_rounded, 'Remove', isDestructive: true))],
              ],
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit?.call();
                  case 'remove':
                    onRemove?.call();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {bool isDestructive = false}) {
    final color = isDestructive ? AppColors.error500 : null;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.tokens});

  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, size: 24, color: tokens.muted),
          const SizedBox(height: 6),
          Text(
            'Waiting for data…',
            style: TextStyle(fontSize: 11, color: tokens.textTertiary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.model, required this.tokens});

  final GraphCardModel model;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots(model.dataPoints);
    final (:minY, :maxY, :yInterval) = _yConfig(model);

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        gridData: _chartGrid(tokens, yInterval),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: _xInterval(model.dataPoints),
              getTitlesWidget: (value, meta) {
                if (value <= meta.min || value >= meta.max) return const SizedBox.shrink();
                return _timeLabel(value, tokens);
              },
            ),
          ),
          leftTitles: _leftAxisTitles(tokens, yInterval),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: model.interpolation == InterpolationMode.curved,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            isStepLineChart: model.interpolation == InterpolationMode.stepped,
            color: model.color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: model.dotSize > 0,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: model.dotSize, color: model.color, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: model.showFill,
              color: model.color.withValues(alpha: model.fillOpacity),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tokens.elevated,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final timestamp = _formatTimestamp(s.x);
              return LineTooltipItem(
                '${_formatValue(s.y)}\n',
                TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: model.color),
                children: [
                  TextSpan(
                    text: timestamp,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.normal, color: tokens.textSecondary),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.model, required this.tokens});

  final GraphCardModel model;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final (:minY, :maxY, :yInterval) = _yConfig(model);

    return BarChart(
      BarChartData(
        gridData: _chartGrid(tokens, yInterval),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= model.dataPoints.length) return const SizedBox.shrink();
                if (model.dataPoints.length > 10 && idx % (model.dataPoints.length ~/ 5) != 0) return const SizedBox.shrink();
                return _timeLabel(model.dataPoints[idx].timestamp.millisecondsSinceEpoch.toDouble(), tokens);
              },
            ),
          ),
          leftTitles: _leftAxisTitles(tokens, yInterval),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        barGroups: model.dataPoints.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: model.color,
                width: model.dataPoints.length > 30 ? 3 : 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => tokens.elevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x;
              final timestamp = idx >= 0 && idx < model.dataPoints.length ? _formatTimestamp(model.dataPoints[idx].timestamp.millisecondsSinceEpoch.toDouble()) : '';
              return BarTooltipItem(
                '${_formatValue(rod.toY)}\n',
                TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: model.color),
                children: [
                  TextSpan(
                    text: timestamp,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.normal, color: tokens.textSecondary),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

({double minY, double maxY, double yInterval}) _yConfig(GraphCardModel model) {
  final (autoMin, autoMax) = _yRange(model.dataPoints);
  final minY = model.yMin ?? autoMin;
  final maxY = model.yMax ?? autoMax;
  return (minY: minY, maxY: maxY, yInterval: _niceInterval(minY, maxY));
}

FlGridData _chartGrid(AppTokens tokens, double yInterval) => FlGridData(
  show: true,
  drawVerticalLine: false,
  horizontalInterval: yInterval,
  getDrawingHorizontalLine: (value) => FlLine(color: tokens.border, strokeWidth: 0.5),
);

AxisTitles _leftAxisTitles(AppTokens tokens, double yInterval) => AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 40,
    interval: yInterval,
    getTitlesWidget: (value, meta) {
      if (_tooCloseToEdge(value, meta.min, meta.max, yInterval)) {
        return const SizedBox.shrink();
      }
      return Text(_formatValue(value), style: TextStyle(fontSize: 9, color: tokens.textTertiary));
    },
  ),
);

List<FlSpot> _buildSpots(List<DataPoint> points) {
  if (points.isEmpty) return [];
  return points.map((p) => FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value)).toList();
}

(double, double) _yRange(List<DataPoint> points) {
  if (points.isEmpty) return (0, 1);
  var min = points.first.value;
  var max = points.first.value;
  for (final p in points) {
    if (p.value < min) min = p.value;
    if (p.value > max) max = p.value;
  }
  final padding = (max - min) * 0.1;
  if (padding == 0) return (min - 1, max + 1);
  return (min - padding, max + padding);
}

double _niceInterval(double minY, double maxY) {
  final range = maxY - minY;
  if (range <= 0) return 1;
  final rawStep = range / 5;
  final mag = math.pow(10, (math.log(rawStep) / math.ln10).floorToDouble()).toDouble();
  final normalized = rawStep / mag;
  final nice = normalized <= 1.5
      ? 1.0
      : normalized <= 3.5
      ? 2.0
      : normalized <= 7.5
      ? 5.0
      : 10.0;
  return nice * mag;
}

bool _tooCloseToEdge(double value, double min, double max, double interval) {
  final threshold = interval * 0.6;
  if ((value - min).abs() < threshold && (value - min).abs() > 0.001) return true;
  if ((max - value).abs() < threshold && (max - value).abs() > 0.001) return true;
  return false;
}

double _xInterval(List<DataPoint> points) {
  if (points.length < 2) return 1;
  final total = points.last.timestamp.millisecondsSinceEpoch - points.first.timestamp.millisecondsSinceEpoch;
  if (total <= 0) return 1;
  return total / 4;
}

Widget _timeLabel(double msValue, AppTokens tokens) {
  final dt = DateTime.fromMillisecondsSinceEpoch(msValue.toInt());
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text('$h:$m:$s', style: TextStyle(fontSize: 8, color: tokens.textTertiary)),
  );
}

String _formatTimestamp(double msValue) {
  final dt = DateTime.fromMillisecondsSinceEpoch(msValue.toInt());
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _formatValue(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}
