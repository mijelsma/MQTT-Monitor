import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';
import '../../../state/keys/settings_keys.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/language.dart';
import '../../elements/ui_panel_scaffold.dart';
import '../../elements/ui_section.dart';

class LanguagePanel extends StatelessWidget {
  const LanguagePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.tokens.primary;
    final selected = context.watch<AppStateManager>().read(SettingsKeys.language);

    return UiPanelScaffold(
      title: 'Language',
      description: 'Select the interface language.',
      children: [
        UiSection(
          label: 'Interface Language',
          children: [
            for (final language in AppLanguage.values)
              ListTile(
                key: ValueKey(language),
                title: Text(language.displayName, style: const TextStyle(fontSize: 14)),
                trailing: selected == language ? Icon(Icons.check_rounded, color: accent, size: 20) : null,
                onTap: () => context.read<AppStateManager>().write(SettingsKeys.language, language),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              ),
          ],
        ),

        // Note below the list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Changes will apply on next launch.', style: theme.textTheme.labelSmall),
        ),
      ],
    );
  }
}
