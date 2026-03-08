import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/language.dart';
import '../../elements/ui_panel_scaffold.dart';
import '../../elements/ui_section.dart';

class LanguagePanel extends StatefulWidget {
  const LanguagePanel({super.key});

  @override
  State<LanguagePanel> createState() => _LanguagePanelState();
}

class _LanguagePanelState extends State<LanguagePanel> {
  String _selected = 'en';

  static const _languages = [
    Language(code: 'en', name: 'English', flag: '\u{1F1EC}\u{1F1E7}'),
    Language(code: 'de', name: 'Deutsch', flag: '\u{1F1E9}\u{1F1EA}'),
    Language(code: 'fr', name: 'Français', flag: '\u{1F1EB}\u{1F1F7}'),
    Language(code: 'nl', name: 'Nederlands', flag: '\u{1F1F3}\u{1F1F1}'),
    Language(code: 'es', name: 'Español', flag: '\u{1F1EA}\u{1F1F8}'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.tokens.primary;

    return UiPanelScaffold(
      title: 'Language',
      description: 'Select the interface language.',
      children: [
        UiSection(
          label: 'Interface Language',
          children: [
            for (final language in _languages)
              ListTile(
                key: ValueKey(language.code),
                leading: Text(language.flag, style: const TextStyle(fontSize: 22)),
                title: Text(language.name, style: const TextStyle(fontSize: 14)),
                trailing: _selected == language.code ? Icon(Icons.check_rounded, color: accent, size: 20) : null,
                onTap: () => setState(() => _selected = language.code),
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
