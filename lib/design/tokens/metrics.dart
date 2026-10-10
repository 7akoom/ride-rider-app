/// Spacing on a 4-point grid.
abstract final class Space {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;

  /// Left/right padding of a screen and inside cards.
  static const double gutter = x4;

  /// Between sections of a screen.
  static const double section = x6;
}

/// Corner radii.
abstract final class Radii {
  static const double input = 12;
  static const double iconButton = 12;
  static const double button = 14;
  static const double card = 16;
  static const double dialog = 20;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Fixed sizes of interactive elements.
abstract final class Sizes {
  /// Minimum size of anything tappable.
  static const double touchTarget = 44;
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double iconButton = 44;
  static const double listRow = 56;
  static const double chipHeight = 36;
  static const double avatar = 48;
  static const double icon = 24;
  static const double iconSmall = 20;

  /// The round picture at the top of an explaining screen (location permission).
  static const double hero = 112;
  static const double heroIcon = 56;

  /// The widest content column on tablets and wide phones.
  static const double maxContentWidth = 560;
}
