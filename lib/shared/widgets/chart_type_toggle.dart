import 'package:flutter/material.dart';

import '../../core/dashboard/models/chart_type_model.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'toggle_chip.dart';

/// A segmented toggle for choosing between line and bar chart types.
///
/// When [label] is provided, a title is rendered above the toggle.
class ChartTypeToggle extends StatelessWidget {
  const ChartTypeToggle({super.key, this.label, this.margin, required this.value, required this.onChanged});

  final String? label;
  final EdgeInsetsGeometry? margin;
  final ChartTypeModel value;
  final ValueChanged<ChartTypeModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        for (final type in ChartTypeModel.values) ...[if (type != ChartTypeModel.values.first) const SizedBox(width: 8), ToggleChip(label: type == ChartTypeModel.line ? 'Line' : 'Bar', icon: type == ChartTypeModel.line ? Icons.show_chart_rounded : Icons.bar_chart_rounded, selected: value == type, onTap: () => onChanged(type))],
      ],
    );
    if (label == null) return row;
    Widget result = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.tokens.textPrimary),
        ),
        const SizedBox(height: 8),
        row,
      ],
    );
    if (margin != null) result = Padding(padding: margin!, child: result);
    return result;
  }
}
