import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../models/environment_variable.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../dialogs/variable_modal.dart';
import '../settings_viewmodel.dart';

class VariablesPanel extends StatelessWidget {
  const VariablesPanel({super.key});

  void _addVariable(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final existing = vm.environmentVariables.map((v) => v.name).toSet();
    final result = await showVariableModal(context, existingNames: existing, brokers: vm.brokers);
    if (result == null) return;
    vm.addEnvironmentVariable(result);
  }

  void _editVariable(BuildContext context, EnvironmentVariable variable) async {
    final vm = context.read<SettingsViewModel>();
    final existing = vm.environmentVariables.map((v) => v.name).where((n) => n != variable.name).toSet();
    final result = await showVariableModal(context, variable: variable, existingNames: existing, brokers: vm.brokers, onDelete: () => vm.deleteEnvironmentVariable(variable.name));
    if (result == null) return;
    vm.updateEnvironmentVariable(variable.name, result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final variables = vm.environmentVariables;
    final tokens = context.tokens;

    return UiPanelScaffold(
      title: 'Variables',
      description: 'Define environment variables to use as placeholders in chart topic strings. Reference them with [NAME] syntax.',
      children: [
        if (variables.isEmpty)
          const UiEmptyState(icon: Icons.data_object_rounded, title: 'No variables yet', message: 'Add a variable to use as a placeholder\nin your chart topic strings.')
        else
          UiSection(
            label: 'Defined Variables',
            children: [for (int i = 0; i < variables.length; i++) _VariableRow(variable: variables[i], showDivider: i < variables.length - 1, onTap: () => _editVariable(context, variables[i]), onDelete: () => vm.deleteEnvironmentVariable(variables[i].name))],
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Variable'),
            style: FilledButton.styleFrom(backgroundColor: tokens.primary, foregroundColor: tokens.onPrimary),
            onPressed: () => _addVariable(context),
          ),
        ),
      ],
    );
  }
}

class _VariableRow extends StatelessWidget {
  const _VariableRow({required this.variable, required this.showDivider, required this.onTap, this.onDelete});

  final EnvironmentVariable variable;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final optionCount = variable.options.length;
    final scopeText = variable.isGlobal ? 'Global' : '${variable.brokerIds.length} broker${variable.brokerIds.length == 1 ? '' : 's'}';
    final parts = <String>[optionCount == 0 ? 'No options' : '$optionCount option${optionCount == 1 ? '' : 's'}', scopeText];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: tokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
                  child: Center(
                    child: Text(
                      variable.name.isNotEmpty ? variable.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(variable.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(parts.join(' · '), style: TextStyle(fontSize: 11.5, color: tokens.textSecondary)),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: tokens.error),
                    tooltip: S.of(context).remove,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    onPressed: onDelete,
                  ),
                Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textTertiary),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 0.5, thickness: 0.5, color: tokens.border, indent: 0, endIndent: 0),
      ],
    );
  }
}
