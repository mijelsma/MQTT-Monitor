import 'package:flutter/material.dart';
import '../../../theme/app_tokens/app_tokens.dart';
import '../models/language.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';
import '../../widgets/spacers.dart';

// Divider indent for language rows: 14 (left padding) + 22 (flag emoji) + 16 (gap) = 52
const _kDividerIndent = 52.0;

class LanguagePanel extends StatefulWidget {
  const LanguagePanel({super.key});

  @override
  State<LanguagePanel> createState() => _LanguagePanelState();
}

class _LanguagePanelState extends State<LanguagePanel> {
  String _selected = 'en';

  static const _languages = [Language(code: 'en', name: 'English', flag: '🇬🇧'), Language(code: 'de', name: 'Deutsch', flag: '🇩🇪'), Language(code: 'fr', name: 'Français', flag: '🇫🇷'), Language(code: 'nl', name: 'Nederlands', flag: '🇳🇱'), Language(code: 'es', name: 'Español', flag: '🇪🇸')];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text('Language', style: theme.textTheme.headlineSmall),

          // Spacer
          VSpacer(6),

          // Description
          Text('Select the interface language.', style: theme.textTheme.bodySmall),

          // Spacer
          VSpacer(20),

          // Language options
          SettingsGroup(
            children: _languages.asMap().entries.map((entry) {
              final language = entry.value;
              final isLast = entry.key == _languages.length - 1;

              return _buildLanguageRow(language: language, isLast: isLast);
            }).toList(),
          ),

          // Spacer
          VSpacer(12),

          // Note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Changes will apply on next launch.', style: theme.textTheme.labelSmall),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow({required Language language, required bool isLast}) {
    final accent = context.tokens.primary;

    return SettingsRow(
      isLast: isLast,
      dividerIndent: _kDividerIndent,
      child: ListTile(
        leading: Text(language.flag, style: const TextStyle(fontSize: 22)),
        title: Text(language.name, style: const TextStyle(fontSize: 14)),
        trailing: _selected == language.code ? Icon(Icons.check_rounded, color: accent, size: 20) : null,
        onTap: () => setState(() => _selected = language.code),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
    );
  }
}
