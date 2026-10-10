import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/fare_quote.dart';
import '../entities/passenger.dart';
import '../entities/payment_method.dart';
import '../entities/ride.dart';
import '../entities/trip_draft.dart';
import '../repositories/rides_repository.dart';

/// Why a ride could not be requested, when the rider can do something about it.
enum OrderProblem {
  /// The price is gone (expired or already used): new prices are needed.
  pricesChanged,

  /// Not allowed now: a trip already under way, or fees from a cancelled trip to pay.
  notNow,
}

/// Requests the trip at the chosen price. An expired price is not sent: the rider
/// gets new prices instead.
final class OrderRide {
  const OrderRide(this.rides, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final RidesRepository rides;
  final DateTime Function() _clock;

  Future<Result<Ride>> call({
    required TripDraft draft,
    required FareQuote quote,
    required PaymentMethod payment,
    Passenger? passenger,
  }) async {
    if (quote.isExpiredAt(_clock())) {
      return const Err(NotFoundFailure());
    }

    return rides.request(draft: draft, quote: quote, payment: payment, passenger: passenger);
  }
}

/// The trip-service answers a used or expired quote with NotFound or
/// FailedPrecondition; FailedPrecondition is also an active trip or unpaid fees.
OrderProblem? orderProblemOf(Failure failure) => switch (failure) {
      NotFoundFailure() => OrderProblem.pricesChanged,
      PreconditionFailure() => OrderProblem.notNow,
      _ => null,
    };
