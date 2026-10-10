import 'package:flutter/painting.dart';

/// Only bottom sheets and floating map buttons cast a shadow; cards are flat with a
/// 1px border.
abstract final class Shadows {
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1A05070F), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> none = [];
}
