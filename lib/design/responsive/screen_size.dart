import 'package:flutter/widgets.dart';

/// Width classes the layout adapts to (Material window size classes).
enum ScreenSize {
  /// Phones in portrait (under 600 dp).
  compact,

  /// Large phones in landscape, small tablets (600–839 dp).
  medium,

  /// Tablets and wider (840 dp and up).
  expanded;

  static ScreenSize fromWidth(double width) {
    if (width < 600) {
      return ScreenSize.compact;
    }

    return width < 840 ? ScreenSize.medium : ScreenSize.expanded;
  }
}

extension ScreenSizeContext on BuildContext {
  ScreenSize get screenSize => ScreenSize.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isCompact => screenSize == ScreenSize.compact;
}
