/// The language the user picked. Pure Dart — no Flutter imports.
enum AppLanguage {
  /// Follow the phone. The default until the user picks one.
  system(null),
  english('en'),
  arabic('ar');

  const AppLanguage(this.languageCode);

  /// Null means "whatever the phone uses".
  final String? languageCode;

  /// Anything unknown (nothing saved, or a value from a newer version) falls
  /// back to following the phone.
  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (AppLanguage language) =>
        language.languageCode != null && language.languageCode == code,
    orElse: () => AppLanguage.system,
  );
}
