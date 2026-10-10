/// Where the rider goes next while getting into the app.
enum NextStep {
  /// First run: pick the app's language.
  chooseLanguage,

  /// No session: type the phone number.
  enterPhone,

  /// Signed in, but no rider profile yet: type a name.
  enterName,

  /// Signed in with a profile: the app itself.
  home,

  /// Signed in, but the profile could not be checked (no connection). The start
  /// screen checks again, with a "try again" button.
  checkAgain,
}
