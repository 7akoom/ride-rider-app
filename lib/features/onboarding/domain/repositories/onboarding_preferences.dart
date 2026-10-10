/// What the app remembers about the first run, on this phone.
abstract interface class OnboardingPreferences {
  /// Whether the language has been picked once (the language screen shows only then).
  Future<bool> languageChosen();

  Future<void> markLanguageChosen();

  /// Whether the location screen has been shown once (allowed or "not now").
  Future<bool> locationAsked();

  Future<void> markLocationAsked();
}
