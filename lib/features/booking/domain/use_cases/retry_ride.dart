import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';
import '../entities/fare_quote.dart';
import '../entities/ride.dart';
import '../entities/spot.dart';
import '../entities/trip_draft.dart';
import 'order_ride.dart';
import 'quote_ride.dart';

/// The trip a ride was for, as a draft again (to try once more, or choose another
/// ride type).
TripDraft draftOf(Ride ride) => TripDraft(
      pickup: _spot(ride.pickup, ride.pickupAddress),
      stops: [for (final stop in ride.stops) _spot(stop.point, stop.address)],
      destination: _spot(ride.dropoff, ride.dropoffAddress),
    );

Spot _spot(GeoPoint point, String address) => Spot(
      point: point,
      kind: SpotKind.pinned,
      title: address.isEmpty ? null : address,
    );

/// No captain took the ride: the same trip again at a new price, same ride type and
/// payment (the cheapest type when that one is no longer offered).
final class RetryRide {
  const RetryRide({required this.quote, required this.order});

  final QuoteRide quote;
  final OrderRide order;

  Future<Result<Ride>> call(Ride ride) async {
    final draft = draftOf(ride);
    final quotes = await quote(draft);

    if (quotes is Err<FareQuotes>) {
      return Err(quotes.failure);
    }

    final picked = _pick((quotes as Ok<FareQuotes>).value, ride.vehicleClass);
    if (picked == null) {
      return const Err(NotFoundFailure());
    }

    return order(draft: draft, quote: picked, payment: ride.payment);
  }

  static FareQuote? _pick(FareQuotes quotes, String vehicleClass) =>
      quotes.ofClass(vehicleClass) ?? (quotes.quotes.isEmpty ? null : quotes.quotes.first);
}
