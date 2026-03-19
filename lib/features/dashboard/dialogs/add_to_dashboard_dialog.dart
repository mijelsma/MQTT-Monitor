import 'package:flutter/material.dart';

import '../../../models/chart_type.dart';
import '../../../models/graph_card_model.dart';
import '../../../models/interpolation_mode.dart';
import '../../../shared/widgets/chart_type_toggle.dart';
import '../../../shared/widgets/interpolation_toggle.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Result returned from the graph card dialog (add or edit).
class GraphCardDialogResult {
  const GraphCardDialogResult({this.topic, required this.displayName, this.unit, required this.color, required this.chartType, required this.interpolation, required this.dotSize, required this.showFill, required this.fillOpacity, required this.maxDataPoints, this.yMin, this.yMax});

  final String? topic;
  final String displayName;
  final String? unit;
  final Color color;
  final ChartType chartType;
  final InterpolationMode interpolation;
  final double dotSize;
  final bool showFill;
  final double fillOpacity;
  final int maxDataPoints;
  final double? yMin;
  final double? yMax;
}

/// Shows a dialog for editing a graph card's properties.
///
/// When [card] is provided, the dialog opens in edit mode with pre-filled values.
/// Returns a [GraphCardDialogResult] if the user confirms, or `null` if dismissed.
Future<GraphCardDialogResult?> showGraphCardDialog(BuildContext context, {required GraphCardModel card, VoidCallback? onDelete}) {
  return showDialog<GraphCardDialogResult>(
    context: context,
    builder: (_) => _GraphCardDialog(card: card, onDelete: onDelete),
  );
}

class _GraphCardDialog extends StatefulWidget {
  const _GraphCardDialog({required this.card, this.onDelete});

  final GraphCardModel card;
  final VoidCallback? onDelete;

  @override
  State<_GraphCardDialog> createState() => _GraphCardDialogState();
}

class _GraphCardDialogState extends State<_GraphCardDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _topicController;
  late final TextEditingController _yMinController;
  late final TextEditingController _yMaxController;
  late final TextEditingController _maxSamplesController;
  late Color _color;
  late ChartType _chartType;
  late InterpolationMode _interpolation;
  late double _dotSize;
  late bool _showFill;
  late double _fillOpacity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card.displayName);
    _unitController = TextEditingController(text: widget.card.unit ?? '');
    _topicController = TextEditingController(text: widget.card.topic);
    _yMinController = TextEditingController(text: widget.card.yMin?.toString() ?? '');
    _yMaxController = TextEditingController(text: widget.card.yMax?.toString() ?? '');
    _maxSamplesController = TextEditingController(text: widget.card.maxDataPoints > 0 ? widget.card.maxDataPoints.toString() : '');
    _color = widget.card.color;
    _chartType = widget.card.chartType;
    _interpolation = widget.card.interpolation;
    _dotSize = widget.card.dotSize;
    _showFill = widget.card.showFill;
    _fillOpacity = widget.card.fillOpacity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _topicController.dispose();
    _yMinController.dispose();
    _yMaxController.dispose();
    _maxSamplesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final editedTopic = _topicController.text.trim();
    // Only include topic in the result if it was actually changed.
    final topicChanged = editedTopic.isNotEmpty && editedTopic != widget.card.topic;
    Navigator.of(context).pop(
      GraphCardDialogResult(
        topic: topicChanged ? editedTopic : null,
        displayName: name,
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
        color: _color,
        chartType: _chartType,
        interpolation: _interpolation,
        dotSize: _dotSize,
        showFill: _showFill,
        fillOpacity: _fillOpacity,
        maxDataPoints: int.tryParse(_maxSamplesController.text.trim()) ?? 0,
        yMin: double.tryParse(_yMinController.text.trim()),
        yMax: double.tryParse(_yMaxController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return UiModalScaffold(
      title: 'Edit Graph',
      isEditing: true,
      onDelete: widget.onDelete != null
          ? () {
              widget.onDelete!();
              Navigator.of(context).pop();
            }
          : null,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submit,
      submitLabel: 'Save',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic (editable)
          UiField(label: 'Topic', controller: _topicController, hint: 'e.g. my/sensor/[ID]/value'),
          const VSpacer(4),
          Text('Use [NAME] to insert an environment variable.', style: TextStyle(fontSize: 11, color: tokens.textTertiary)),

          // JSON key path (if applicable)
          if (widget.card.jsonKeyPath != null) ...[
            const VSpacer(16),
            Text(
              'Key Path',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.textPrimary),
            ),
            const VSpacer(6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border, width: 0.5),
              ),
              child: Text(
                widget.card.jsonKeyPath!,
                style: TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 12, color: tokens.textSecondary),
              ),
            ),
          ],

          const VSpacer(16),
          UiField(label: 'Display Name', controller: _nameController, hint: 'e.g. Temperature'),

          const VSpacer(16),
          UiField(label: 'Unit', controller: _unitController, hint: 'e.g. °C, %, ms', optional: true),

          const VSpacer(20),
          ColorPickerField(label: 'Color', value: _color, onChanged: (c) => setState(() => _color = c)),

          const VSpacer(20),
          Text(
            'Chart Type',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.textPrimary),
          ),
          const VSpacer(8),
          ChartTypeToggle(value: _chartType, onChanged: (t) => setState(() => _chartType = t)),

          const VSpacer(20),
          Text(
            'Interpolation',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.textPrimary),
          ),
          const VSpacer(8),
          InterpolationToggle(value: _interpolation, onChanged: (m) => setState(() => _interpolation = m)),

          const VSpacer(20),
          UiSliderRow(label: 'Dot Size', value: _dotSize, min: 0, max: 8, divisions: 16, displayValue: _dotSize == 0 ? 'Off' : _dotSize.toStringAsFixed(1), compact: true, onChanged: (v) => setState(() => _dotSize = v)),

          const VSpacer(12),
          UiSwitchRow(label: 'Area Fill', value: _showFill, compact: true, onChanged: (v) => setState(() => _showFill = v)),
          if (_showFill) ...[const VSpacer(4), UiSliderRow(label: 'Fill Intensity', value: _fillOpacity, min: 0.02, max: 0.5, divisions: 24, displayValue: '${(_fillOpacity * 100).round()}%', compact: true, onChanged: (v) => setState(() => _fillOpacity = v))],

          const VSpacer(16),
          UiField(label: 'Max Samples', controller: _maxSamplesController, hint: 'Unlimited', optional: true),
          const VSpacer(2),
          Text('Leave empty to keep all values', style: TextStyle(fontSize: 11, color: tokens.textTertiary)),

          const VSpacer(16),
          Text(
            'Y-Axis Range',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.textPrimary),
          ),
          const VSpacer(4),
          Text('Leave empty for auto range', style: TextStyle(fontSize: 11, color: tokens.textTertiary)),
          const VSpacer(8),
          Row(
            children: [
              Expanded(
                child: UiField(label: 'Min', controller: _yMinController, hint: 'Auto', optional: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UiField(label: 'Max', controller: _yMaxController, hint: 'Auto', optional: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
