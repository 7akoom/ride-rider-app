/// What the app remembers about the first run, on this phone.
abstract interface class OnboardingPreferences {
  /// Whether the language has been picked once (the language screen shows only then).
  Future<bool> languageChosen();

  Future<void> markLanguageChosen();
}
