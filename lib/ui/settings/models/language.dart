import '../../../generated/l10n.dart';
import '../../../state/state_key.dart';

enum AppLanguage with KeyedEnum {
  en,
  de,
  fr,
  nl,
  es;

  @override
  String get key => name;

  /// Native (autonym) name — always shown in the language's own script.
  String get displayName => switch (this) {
    AppLanguage.en => 'English',
    AppLanguage.de => 'Deutsch',
    AppLanguage.fr => 'Français',
    AppLanguage.nl => 'Nederlands',
    AppLanguage.es => 'Español',
  };

  /// Localized name — shown in the current app language.
  String localizedName(S s) => switch (this) {
    AppLanguage.en => s.languageNameEn,
    AppLanguage.de => s.languageNameDe,
    AppLanguage.fr => s.languageNameFr,
    AppLanguage.nl => s.languageNameNl,
    AppLanguage.es => s.languageNameEs,
  };
}
