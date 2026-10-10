import '../../../../core/error/result.dart';
import '../entities/fare_quote.dart';
import '../entities/passenger.dart';
import '../entities/payment_method.dart';
import '../entities/ride.dart';
import '../entities/trip_draft.dart';

/// Ordering a ride and following it until a captain takes it: its prices, the wallet
/// that may pay for it, the request, its state and cancelling it.
abstract interface class RidesRepository {
  /// Prices for every ride type; [couponCode] is tried on each.
  Future<Result<FareQuotes>> quote(TripDraft draft, {String? couponCode});

  /// The rider's wallet balance in whole currency units.
  Future<Result<int>> walletBalance();

  /// Requests the trip at [quote]'s price, for [passenger] when it is someone else.
  Future<Result<Ride>> request({
    required TripDraft draft,
    required FareQuote quote,
    required PaymentMethod payment,
    Passenger? passenger,
  });

  Future<Result<Ride>> ride(String id);

  /// The rider's trip that has not ended, or null when there is none.
  Future<Result<Ride?>> activeRide();

  Future<Result<Ride>> cancel(String id);
}
