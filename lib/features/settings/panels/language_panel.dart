import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../../../core/ui/models/app_language_model.dart';
import '../../../shared/widgets/ui_panel_scaffold.dart';
import '../../../shared/widgets/ui_section.dart';
import '../view_models/settings_view_model.dart';

class LanguagePanel extends StatelessWidget {
  const LanguagePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.tokens.primary;
    final vm = context.watch<SettingsViewModel>();
    final selected = vm.language;
    final s = S.of(context);

    return UiPanelScaffold(
      title: s.languagePanelTitle,
      description: s.languagePanelDescription,
      children: [
        UiSection(
          label: s.languagePanelSectionLabel,
          children: [
            for (final language in AppLanguageModel.values)
              ListTile(
                key: ValueKey(language),
                title: Text(language.localizedName(s), style: const TextStyle(fontSize: 14)),
                trailing: selected == language ? Icon(Icons.check_rounded, color: accent, size: 20) : null,
                onTap: () => vm.setLanguage(language),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(S.of(context).languagePanelChangesNote, style: theme.textTheme.labelSmall),
        ),
      ],
    );
  }
}
