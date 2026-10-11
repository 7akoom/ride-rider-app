import '../../../core/error/failure.dart';
import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../domain/entities/cancellation.dart';
import '../domain/entities/fare_quote.dart';
import '../domain/entities/passenger.dart';
import '../domain/entities/payment_method.dart';
import '../domain/entities/ride.dart';
import '../domain/entities/trip_draft.dart';
import '../domain/repositories/rides_repository.dart';
import 'fare_quote_json.dart';
import 'ride_json.dart';
import '../../../core/rider/rider_id.dart';
import 'rides_api.dart';
import 'trip_body.dart';

final class RidesRepositoryImpl implements RidesRepository {
  RidesRepositoryImpl(this._api);

  final RidesApi _api;

  /// Recorded on the trip; staff read it, riders never see it.
  static const String cancelReason = 'rider cancelled in the app';

  /// The reason as staff read it, in English: "rider: the captain was late".
  static String reasonOf(Cancellation? why) => switch (why) {
        null => cancelReason,
        Cancellation(reason: CancelReason.captainLate) => 'rider: the captain was late',
        Cancellation(reason: CancelReason.changedMind) => 'rider: changed their mind',
        Cancellation(reason: CancelReason.orderedByMistake) => 'rider: ordered by mistake',
        Cancellation(reason: CancelReason.captainAsked) => 'rider: the captain asked to cancel',
        Cancellation(reason: CancelReason.other, :final text) => 'rider: $text',
      };

  @override
  Future<Result<FareQuotes>> quote(TripDraft draft, {String? couponCode}) => guard(() async {
        final json = await _api.quotes({
          'riderId': await riderIdOrSignIn(),
          'pickup': draft.pickup!.point.toJson(),
          'dropoff': draft.destination!.point.toJson(),
          if (draft.stops.isNotEmpty) 'stops': [for (final s in draft.stops) s.point.toJson()],
          if (couponCode != null) 'couponCode': couponCode,
        });

        return FareQuoteJson.quotesOf(json);
      });

  @override
  Future<Result<int>> walletBalance() => guard(() async {
        final json = await _api.wallet(await riderIdOrSignIn());

        return amountAt(objectAt(json, 'wallet') ?? const {}, 'balance') ?? 0;
      });

  @override
  Future<Result<Ride>> request({
    required TripDraft draft,
    required FareQuote quote,
    required PaymentMethod payment,
    Passenger? passenger,
  }) =>
      guard(() async {
        final json = await _api.requestTrip({
          'riderId': await riderIdOrSignIn(),
          ...TripBody.of(draft, passenger: passenger),
          'vehicleClass': quote.vehicleClass,
          'paymentMethod': payment.name,
          'quoteId': quote.id,
        });

        return RideJson.fromAnswer(json);
      });

  @override
  Future<Result<Ride>> ride(String id) =>
      guard(() async => RideJson.fromAnswer(await _api.trip(id)));

  @override
  Future<Result<Ride?>> activeRide() async {
    final result = await guard(() async => RideJson.fromAnswer(await _api.activeTrip(await riderIdOrSignIn())));

    // No trip under way is answered 404.
    return switch (result) {
      Ok(:final value) => Ok(value),
      Err(failure: NotFoundFailure()) => const Ok(null),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<Ride>> cancel(String id, {Cancellation? why}) =>
      guard(() async => RideJson.fromAnswer(await _api.cancelTrip(id, reasonOf(why))));
}
