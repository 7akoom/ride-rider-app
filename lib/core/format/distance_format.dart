import 'dart:math' as math;

import '../l10n/l10n.dart';
import 'bidi.dart';

/// A distance for people: meters under one kilometer ("350 m"), then kilometers with
/// one decimal ("2.1 km"), Western digits, the unit from the translation.
String formatDistance(AppLocalizations l10n, double meters) {
  if (meters < 1000) {
    final rounded = math.min(990, math.max(10, (meters / 10).round() * 10));

    return l10n.distanceMeters(isolateLtr('$rounded'));
  }

  final km = meters / 1000;
  final text = km < 100 ? km.toStringAsFixed(1) : km.round().toString();

  return l10n.distanceKm(isolateLtr(text));
}
