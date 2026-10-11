import '../domain/entities/passenger.dart';
import '../domain/entities/spot.dart';
import '../domain/entities/trip_draft.dart';

/// The parts of a trip request that asking now and booking ahead share.
abstract final class TripBody {
  /// The trip-service's limit for an address.
  static const int maxAddressLength = 300;

  /// Points, addresses, stops and the passenger.
  static Map<String, dynamic> of(TripDraft draft, {Passenger? passenger}) => {
        'pickup': draft.pickup!.point.toJson(),
        'dropoff': draft.destination!.point.toJson(),
        'pickupAddress': addressOf(draft.pickup!),
        'dropoffAddress': addressOf(draft.destination!),
        if (passenger != null) ...{
          'passengerName': passenger.name,
          'passengerPhone': passenger.phone,
        },
        if (draft.stops.isNotEmpty)
          'stops': [
            for (final stop in draft.stops)
              {'coordinates': stop.point.toJson(), 'address': addressOf(stop)},
          ],
      };

  /// The place as the captain reads it: its name and address, within the limit.
  static String addressOf(Spot spot) {
    final text = [spot.title, spot.detail]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(', ');
    final runes = text.runes;

    return runes.length <= maxAddressLength
        ? text
        : String.fromCharCodes(runes.take(maxAddressLength));
  }
}
