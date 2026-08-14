import '../../../generated/l10n.dart';

enum AppLanguageModel {
  en,
  nl;

  String get displayName => switch (this) {
    AppLanguageModel.en => 'English',
    AppLanguageModel.nl => 'Nederlands',
  };

  String localizedName(S s) => switch (this) {
    AppLanguageModel.en => s.languageNameEn,
    AppLanguageModel.nl => s.languageNameNl,
  };
}
