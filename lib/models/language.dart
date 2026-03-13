import '../generated/l10n.dart';

enum AppLanguage {
  en,
  nl;

  String get displayName => switch (this) {
    AppLanguage.en => 'English',
    AppLanguage.nl => 'Nederlands',
  };

  String localizedName(S s) => switch (this) {
    AppLanguage.en => s.languageNameEn,
    AppLanguage.nl => s.languageNameNl,
  };
}
