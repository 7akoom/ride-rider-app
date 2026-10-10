import '../../../../core/location/geo_point.dart';

enum SavedPlaceKind { home, work, other }

/// One of the rider's saved addresses: home, work, or one they named.
final class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.kind,
    required this.label,
    required this.address,
    required this.point,
  });

  final String id;
  final SavedPlaceKind kind;

  /// The rider's name for it; empty for home and work, which the app names.
  final String label;
  final String address;
  final GeoPoint point;
}
