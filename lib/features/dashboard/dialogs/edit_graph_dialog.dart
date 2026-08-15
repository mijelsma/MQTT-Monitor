import 'package:flutter/material.dart';

import '../../../core/dashboard/dashboard_series_policy.dart';
import '../../../core/dashboard/dashboard_value_extractor.dart';
import '../../../core/dashboard/models/chart_type_model.dart';
import '../../../core/dashboard/models/graph_card_model.dart';
import '../../../core/dashboard/models/interpolation_mode_model.dart';
import '../../../shared/widgets/chart_type_toggle.dart';
import '../../../shared/widgets/interpolation_toggle.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/spacers.dart';
import '../../../shared/widgets/ui_field.dart';
import '../../../shared/widgets/ui_modal_scaffold.dart';
import '../../../shared/widgets/ui_slider_row.dart';
import '../../../shared/widgets/ui_switch_row.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Result returned from the edit graph dialog.
class EditGraphResult {
  const EditGraphResult({
    this.topic,
    this.jsonKeyPath,
    required this.displayName,
    this.unit,
    required this.color,
    required this.chartType,
    required this.interpolation,
    required this.dotSize,
    required this.showFill,
    required this.fillOpacity,
    required this.maxDataPoints,
    this.yMin,
    this.yMax,
  });

  final String? topic;
  final String? jsonKeyPath;
  final String displayName;
  final String? unit;
  final Color color;
  final ChartTypeModel chartType;
  final InterpolationModeModel interpolation;
  final double dotSize;
  final bool showFill;
  final double fillOpacity;
  final int maxDataPoints;
  final double? yMin;
  final double? yMax;
}

/// Shows a dialog for editing a graph card's properties.
///
/// Returns an [EditGraphResult] if the user confirms, or `null` if dismissed.
Future<EditGraphResult?> showEditGraphDialog(
  BuildContext context, {
  required GraphCardModel card,
  VoidCallback? onDelete,
}) {
  return showDialog<EditGraphResult>(
    context: context,
    builder: (_) => _EditGraphDialog(card: card, onDelete: onDelete),
  );
}

class _EditGraphDialog extends StatefulWidget {
  const _EditGraphDialog({required this.card, this.onDelete});

  final GraphCardModel card;
  final VoidCallback? onDelete;

  @override
  State<_EditGraphDialog> createState() => _EditGraphDialogState();
}

class _EditGraphDialogState extends State<_EditGraphDialog> {
  late final TextEditingController _topicController;
  late final TextEditingController _nameController;
  late final TextEditingController _keyPathController;
  late final TextEditingController _unitController;
  late final TextEditingController _maxSamplesController;
  late final TextEditingController _yMinController;
  late final TextEditingController _yMaxController;

  late Color _color;
  late ChartTypeModel _chartType;
  late InterpolationModeModel _interpolation;
  late double _dotSize;
  late bool _showFill;
  late double _fillOpacity;
  String? _keyPathError;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.card.topic);
    _nameController = TextEditingController(text: widget.card.displayName);
    _keyPathController = TextEditingController(
      text: widget.card.jsonKeyPath ?? '',
    );
    _unitController = TextEditingController(text: widget.card.unit ?? '');
    _maxSamplesController = TextEditingController(
      text: widget.card.maxDataPoints.toString(),
    );
    _yMinController = TextEditingController(
      text: widget.card.yMin?.toString() ?? '',
    );
    _yMaxController = TextEditingController(
      text: widget.card.yMax?.toString() ?? '',
    );
    _color = Color(widget.card.colorValue);
    _chartType = widget.card.chartType;
    _interpolation = widget.card.interpolation;
    _dotSize = widget.card.dotSize;
    _showFill = widget.card.showFill;
    _fillOpacity = widget.card.fillOpacity;
  }

  @override
  void dispose() {
    _topicController.dispose();
    _nameController.dispose();
    _keyPathController.dispose();
    _unitController.dispose();
    _yMinController.dispose();
    _yMaxController.dispose();
    _maxSamplesController.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final editedTopic = _topicController.text.trim();
    final keyPath = _keyPathController.text.trim();
    try {
      DashboardValueExtractor.validateKeyPath(keyPath);
    } on FormatException {
      setState(
        () => _keyPathError =
            'Use keys and indexes, for example sensor.temperature or samples[0].',
      );
      return;
    }
    // Only include topic in the result if it was actually changed.
    final topicChanged =
        editedTopic.isNotEmpty && editedTopic != widget.card.topic;
    Navigator.of(context).pop(
      EditGraphResult(
        topic: topicChanged ? editedTopic : null,
        jsonKeyPath: keyPath.isEmpty ? null : keyPath,
        displayName: name,
        unit: _unitController.text.trim().isEmpty
            ? null
            : _unitController.text.trim(),
        color: _color,
        chartType: _chartType,
        interpolation: _interpolation,
        dotSize: _dotSize,
        showFill: _showFill,
        fillOpacity: _fillOpacity,
        maxDataPoints: DashboardSeriesPolicy.normalize(
          int.tryParse(_maxSamplesController.text.trim()),
        ),
        yMin: double.tryParse(_yMinController.text.trim()),
        yMax: double.tryParse(_yMaxController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Widget sectionHeader(String text) => Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
    );

    return UiModalScaffold(
      title: 'Edit Graph',
      isEditing: true,
      onDelete: widget.onDelete != null
          ? () {
              widget.onDelete!();
              Navigator.of(context).pop();
            }
          : null,
      onCancel: _cancel,
      onSubmit: _submit,
      submitLabel: 'Save',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic
          UiField(
            label: 'Topic',
            controller: _topicController,
            hint: r'e.g. my/sensor/${ID}/value',
          ),
          const VSpacer(4),
          Text(
            r'Use ${NAME} to insert an environment variable.',
            style: TextStyle(fontSize: 11, color: tokens.textTertiary),
          ),

          const VSpacer(16),
          UiField(
            label: 'Key Path',
            controller: _keyPathController,
            hint: 'e.g. sensor.temperature or samples[0]',
            optional: true,
            style: const TextStyle(fontFamily: 'SF Mono, Menlo, monospace'),
          ),
          if (_keyPathError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _keyPathError!,
                style: TextStyle(fontSize: 11, color: tokens.error),
              ),
            ),

          const VSpacer(16),

          // Display name, unit, and color
          UiField(
            label: 'Display Name',
            controller: _nameController,
            hint: 'e.g. Temperature',
          ),
          UiField(
            margin: const EdgeInsets.only(top: 16),
            label: 'Unit',
            controller: _unitController,
            hint: 'e.g. °C, %, ms',
            optional: true,
          ),
          ColorPickerField(
            margin: const EdgeInsets.only(top: 20),
            label: 'Color',
            value: _color,
            onChanged: (c) => setState(() => _color = c),
          ),

          // Chart type, interpolation mode, and dot size
          ChartTypeToggle(
            margin: const EdgeInsets.only(top: 20),
            label: 'Chart Type',
            value: _chartType,
            onChanged: (t) => setState(() => _chartType = t),
          ),
          InterpolationToggle(
            margin: const EdgeInsets.only(top: 20),
            label: 'Interpolation',
            value: _interpolation,
            onChanged: (m) => setState(() => _interpolation = m),
          ),
          UiSliderRow(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            label: 'Dot Size',
            value: _dotSize,
            min: 0,
            max: 8,
            divisions: 16,
            displayValue: _dotSize == 0 ? 'Off' : _dotSize.toStringAsFixed(1),
            onChanged: (v) => setState(() => _dotSize = v),
          ),

          // Area fill
          UiSwitchRow(
            contentPadding: const EdgeInsets.symmetric(vertical: 2),
            label: 'Area Fill',
            subtitle: 'Show a filled area below the line',
            value: _showFill,
            onChanged: (v) => setState(() => _showFill = v),
          ),
          if (_showFill) ...[
            UiSliderRow(
              margin: const EdgeInsets.only(bottom: 6),
              label: 'Fill Intensity',
              value: _fillOpacity,
              min: 0.02,
              max: 0.5,
              divisions: 24,
              displayValue: '${(_fillOpacity * 100).round()}%',
              onChanged: (v) => setState(() => _fillOpacity = v),
            ),
          ],

          // Max samples and Y-axis range
          UiField(
            margin: const EdgeInsets.only(top: 16, bottom: 2),
            label: 'Max Samples',
            controller: _maxSamplesController,
            hint:
                '${DashboardSeriesPolicy.minimumSamples}-${DashboardSeriesPolicy.maximumSamples}',
          ),
          Text(
            'Each graph keeps at most ${DashboardSeriesPolicy.maximumSamples} values. Default: ${DashboardSeriesPolicy.defaultSamples}.',
            style: TextStyle(fontSize: 11, color: tokens.textTertiary),
          ),
          const VSpacer(16),

          // Y-axis range
          sectionHeader('Y-Axis Range'),
          const VSpacer(4),
          Text(
            'Leave empty for auto range',
            style: TextStyle(fontSize: 11, color: tokens.textTertiary),
          ),
          const VSpacer(8),
          Row(
            children: [
              Expanded(
                child: UiField(
                  label: 'Min',
                  controller: _yMinController,
                  hint: 'Auto',
                  optional: true,
                ),
              ),
              const HSpacer(12),
              Expanded(
                child: UiField(
                  label: 'Max',
                  controller: _yMaxController,
                  hint: 'Auto',
                  optional: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
