import '../../../../core/location/geo_point.dart';
import 'spot.dart';

/// The trip being put together: pickup, up to [maxStops] stops in order, destination.
final class TripDraft {
  const TripDraft({this.pickup, this.stops = const [], this.destination});

  final Spot? pickup;
  final List<Spot> stops;
  final Spot? destination;

  /// The backend's limit for stops on the way.
  static const int maxStops = 2;

  bool get isComplete => pickup != null && destination != null;

  bool get canAddStop => stops.length < maxStops;

  /// Every point in order, for the route: pickup, stops, destination.
  List<GeoPoint> get points => [
        if (pickup != null) pickup!.point,
        for (final stop in stops) stop.point,
        if (destination != null) destination!.point,
      ];

  TripDraft withPickup(Spot spot) =>
      TripDraft(pickup: spot, stops: stops, destination: destination);

  TripDraft withDestination(Spot spot) =>
      TripDraft(pickup: pickup, stops: stops, destination: spot);

  /// Puts [spot] at stop [index]; an index past the end adds it (within the limit).
  TripDraft withStop(int index, Spot spot) {
    final next = [...stops];

    if (index < next.length) {
      next[index] = spot;
    } else if (canAddStop) {
      next.add(spot);
    }

    return TripDraft(pickup: pickup, stops: next, destination: destination);
  }

  TripDraft withoutStop(int index) => TripDraft(
        pickup: pickup,
        stops: [...stops]..removeAt(index),
        destination: destination,
      );
}
