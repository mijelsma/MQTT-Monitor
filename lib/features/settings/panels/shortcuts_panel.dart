import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../core/publishing/models/publish_shortcut_model.dart';
import '../../../shared/widgets/badge_tag.dart';
import '../../../shared/widgets/qos_tag.dart';
import '../../../shared/widgets/scope_badge.dart';
import '../../../shared/widgets/ui_add_button.dart';
import '../../../shared/widgets/ui_empty_state.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../../../shared/widgets/ui_sortable_row.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../dialogs/shortcut_dialog.dart';
import '../view_models/settings_view_model.dart';

class ShortcutsPanel extends StatelessWidget {
  const ShortcutsPanel({super.key});

  void _addShortcut(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final resolvedQos = vm.resolveDefaultQos(vm.defaultShortcutQos);
    final result = await showShortcutDialog(
      context,
      brokers: vm.brokers,
      defaultQos: resolvedQos,
    );
    if (result == null) return;
    vm.addShortcut(result);
  }

  void _editShortcut(
    BuildContext context,
    PublishShortcutModel shortcut,
  ) async {
    final vm = context.read<SettingsViewModel>();
    final result = await showShortcutDialog(
      context,
      shortcut: shortcut,
      brokers: vm.brokers,
      onDelete: () => vm.deleteShortcut(shortcut.id),
    );
    if (result == null) return;
    vm.updateShortcut(result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final s = S.of(context);
    final shortcuts = vm.shortcuts;

    return UiPanelScaffold(
      title: s.shortcutsPanelTitle,
      description: s.shortcutsPanelDescription,
      children: [
        if (shortcuts.isEmpty)
          UiEmptyState(
            icon: Icons.bolt_rounded,
            title: s.shortcutsPanelNoShortcutsTitle,
            message: s.shortcutsPanelNoShortcutsMessage,
          )
        else
          UiSection(
            label: s.shortcutsPanelDefinedShortcuts,
            sortable: true,
            onReorder: (o, n) => vm.reorderShortcuts(o, n),
            children: [
              for (int i = 0; i < shortcuts.length; i++)
                UiSortableRow(
                  key: ValueKey(shortcuts[i].id),
                  index: i,
                  leading: Container(
                    width: 3.5,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(shortcuts[i].colorValue),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  title: shortcuts[i].name,
                  subtitle: shortcuts[i].topic,
                  trailing: [
                    ScopeBadge(
                      isGlobal: shortcuts[i].isGlobal,
                      brokerCount: shortcuts[i].brokerIds.length,
                    ),
                    QosTag(qos: shortcuts[i].qos),
                    if (shortcuts[i].retain)
                      BadgeTag(label: 'RET', color: context.tokens.warning),
                  ],
                  onTap: () => _editShortcut(context, shortcuts[i]),
                  onDelete: () => vm.deleteShortcut(shortcuts[i].id),
                ),
            ],
          ),
        UiAddButton(
          label: s.shortcutsPanelAddShortcut,
          onPressed: () => _addShortcut(context),
        ),
      ],
    );
  }
}
