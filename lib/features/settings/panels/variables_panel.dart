import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../models/environment_variable.dart';
import '../../../shared/widgets/scope_badge.dart';
import '../../../shared/widgets/ui_add_button.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../dialogs/variable_dialog.dart';
import '../settings_viewmodel.dart';

class VariablesPanel extends StatelessWidget {
  const VariablesPanel({super.key});

  void _addVariable(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final existing = vm.environmentVariables.map((v) => v.name).toSet();
    final result = await showVariableDialog(context, existingNames: existing, brokers: vm.brokers);
    if (result == null) return;
    vm.addEnvironmentVariable(result);
  }

  void _editVariable(BuildContext context, EnvironmentVariable variable) async {
    final vm = context.read<SettingsViewModel>();
    final existing = vm.environmentVariables.map((v) => v.name).where((n) => n != variable.name).toSet();
    final result = await showVariableDialog(context, variable: variable, existingNames: existing, brokers: vm.brokers, onDelete: () => vm.deleteEnvironmentVariable(variable.name));
    if (result == null) return;
    vm.updateEnvironmentVariable(variable.name, result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final s = S.of(context);
    final variables = vm.environmentVariables;

    return UiPanelScaffold(
      title: s.variablesPanelTitle,
      description: s.variablesPanelDescription,
      children: [
        if (variables.isEmpty)
          UiEmptyState(icon: Icons.data_object_rounded, title: s.variablesPanelNoVariablesTitle, message: s.variablesPanelNoVariablesMessage)
        else
          UiSection(
            label: s.variablesPanelDefinedVariables,
            sortable: true,
            onReorder: (o, n) => vm.reorderEnvironmentVariables(o, n),
            children: [
              for (int i = 0; i < variables.length; i++)
                UiSortableRow(
                  key: ValueKey(variables[i].name),
                  index: i,
                  leading: _VariableAvatar(name: variables[i].name),
                  title: variables[i].name,
                  subtitle: _subtitle(s, variables[i]),
                  trailing: [ScopeBadge(isGlobal: variables[i].isGlobal, brokerCount: variables[i].brokerIds.length)],
                  onTap: () => _editVariable(context, variables[i]),
                  onDelete: () => vm.deleteEnvironmentVariable(variables[i].name),
                ),
            ],
          ),
        UiAddButton(label: s.variablesPanelAddVariable, onPressed: () => _addVariable(context)),
      ],
    );
  }

  String _subtitle(S s, EnvironmentVariable v) {
    final count = v.options.length;
    return count == 0 ? s.variablesPanelNoOptions : '$count option${count == 1 ? '' : 's'}';
  }
}

class _VariableAvatar extends StatelessWidget {
  const _VariableAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: tokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.primary),
        ),
      ),
    );
  }
}
