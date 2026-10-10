import '../../../../core/location/geo_point.dart';

/// What a spot is, for its icon.
enum SpotKind {
  currentLocation,
  home,
  work,
  saved,
  airport,
  mall,
  hotel,
  hospital,
  university,
  landmark,
  station,
  government,
  restaurant,
  pinned,
  other,
}

/// A place the rider picked for the trip: pickup, a stop or the destination.
final class Spot {
  const Spot({
    required this.point,
    required this.kind,
    this.title,
    this.detail,
    this.savedPlaceId,
  });

  final GeoPoint point;
  final SpotKind kind;

  /// Its name ("Family Mall", a street); null when the map has none (the screen then
  /// names it by its kind: "Current location", "Selected point").
  final String? title;

  /// A second line: the address of a named place.
  final String? detail;

  /// Set when it is one of the rider's saved addresses: the trip then takes the saved
  /// details and note for the captain.
  final String? savedPlaceId;
}
