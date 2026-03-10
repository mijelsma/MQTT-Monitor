import '../../../generated/l10n.dart';
import '../../../state/state_key.dart';

enum AppLanguage with KeyedEnum {
  en,
  nl;

  @override
  String get key => name;

  /// Native (autonym) name — always shown in the language's own script.
  String get displayName => switch (this) {
    AppLanguage.en => 'English',
    AppLanguage.nl => 'Nederlands',
  };

  /// Localized name — shown in the current app language.
  String localizedName(S s) => switch (this) {
    AppLanguage.en => s.languageNameEn,
    AppLanguage.nl => s.languageNameNl,
  };
}
