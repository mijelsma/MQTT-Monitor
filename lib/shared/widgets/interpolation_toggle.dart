import 'package:flutter/material.dart';

import '../../core/dashboard/models/interpolation_mode_model.dart';
import '../../theme/app_tokens/app_tokens.dart';
import 'toggle_chip.dart';

/// A segmented toggle for choosing between interpolation modes.
///
/// When [label] is provided, a title is rendered above the toggle.
class InterpolationToggle extends StatelessWidget {
  const InterpolationToggle({super.key, this.label, this.margin, required this.value, required this.onChanged});

  final String? label;
  final EdgeInsetsGeometry? margin;
  final InterpolationModeModel value;
  final ValueChanged<InterpolationModeModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        for (final mode in InterpolationModeModel.values) ...[if (mode != InterpolationModeModel.values.first) const SizedBox(width: 8), ToggleChip(label: _label(mode), selected: value == mode, onTap: () => onChanged(mode))],
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

  String _label(InterpolationModeModel mode) => switch (mode) {
    InterpolationModeModel.curved => 'Curved',
    InterpolationModeModel.linear => 'Linear',
    InterpolationModeModel.stepped => 'Stepped',
  };
}
