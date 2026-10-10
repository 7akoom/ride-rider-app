import 'package:flutter/widgets.dart';

/// Honours the phone's text-size setting within limits the layout can hold, so large
/// accessibility sizes stay readable without breaking screens.
class TextScaleClamp extends StatelessWidget {
  const TextScaleClamp({super.key, required this.child});

  static const double minScale = 0.85;
  static const double maxScale = 1.3;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(
          minScaleFactor: minScale,
          maxScaleFactor: maxScale,
        ),
      ),
      child: child,
    );
  }
}
