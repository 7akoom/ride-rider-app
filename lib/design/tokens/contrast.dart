import 'dart:math' as math;
import 'dart:ui';

const Color _black = Color(0xFF000000);
const Color _white = Color(0xFFFFFFFF);

/// WCAG contrast ratio between two colours (1 to 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();

  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Whichever of [dark] and [light] reads better on [background].
Color bestTextOn(Color background, {required Color dark, Color light = _white}) {
  return contrastRatio(dark, background) >= contrastRatio(light, background)
      ? dark
      : light;
}

/// [color] if it already reaches [minimum] contrast on [background]; otherwise the
/// closest shade of it (moved towards black on light backgrounds, towards white on dark
/// ones) that does.
Color withContrast(Color color, Color background, {double minimum = 4.5}) {
  if (contrastRatio(color, background) >= minimum) {
    return color;
  }

  final target = background.computeLuminance() > 0.5 ? _black : _white;

  for (var step = 1; step <= 20; step++) {
    final candidate = Color.lerp(color, target, step / 20)!;
    if (contrastRatio(candidate, background) >= minimum) {
      return candidate;
    }
  }

  return target;
}
