import '../../../state/state_key.dart';

enum AppLanguage with KeyedEnum {
  en,
  de,
  fr,
  nl,
  es;

  @override
  String get key => name;

  String get displayName => switch (this) {
    AppLanguage.en => 'English',
    AppLanguage.de => 'Deutsch',
    AppLanguage.fr => 'Français',
    AppLanguage.nl => 'Nederlands',
    AppLanguage.es => 'Español',
  };
}
