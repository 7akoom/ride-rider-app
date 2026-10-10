import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/entities/spot.dart';

/// How a spot is drawn in lists: its icon, and its name in the rider's language.
abstract final class SpotView {
  static IconData icon(SpotKind kind) => switch (kind) {
        SpotKind.currentLocation => Icons.my_location,
        SpotKind.home => Icons.home_outlined,
        SpotKind.work => Icons.work_outline,
        SpotKind.saved => Icons.bookmark_border,
        SpotKind.airport => Icons.flight,
        SpotKind.mall => Icons.storefront_outlined,
        SpotKind.hotel => Icons.hotel_outlined,
        SpotKind.hospital => Icons.local_hospital_outlined,
        SpotKind.university => Icons.school_outlined,
        SpotKind.landmark => Icons.account_balance_outlined,
        SpotKind.station => Icons.directions_bus_outlined,
        SpotKind.government => Icons.gavel_outlined,
        SpotKind.restaurant => Icons.restaurant_outlined,
        SpotKind.pinned => Icons.push_pin_outlined,
        SpotKind.other => Icons.place_outlined,
      };

  /// Its own name, or the name of its kind when it has none.
  static String title(AppLocalizations l10n, Spot spot) {
    final own = spot.title;
    if (own != null && own.isNotEmpty) {
      return own;
    }

    return switch (spot.kind) {
      SpotKind.currentLocation => l10n.spotCurrentLocation,
      SpotKind.home => l10n.savedHome,
      SpotKind.work => l10n.savedWork,
      _ => l10n.spotPinned,
    };
  }
}
