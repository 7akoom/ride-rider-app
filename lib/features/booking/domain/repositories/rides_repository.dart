import '../../../../core/error/result.dart';
import '../entities/fare_quote.dart';
import '../entities/payment_method.dart';
import '../entities/trip_draft.dart';

/// Ordering a ride: its prices, the wallet that may pay for it, and the request.
abstract interface class RidesRepository {
  /// Prices for every ride type; [couponCode] is tried on each.
  Future<Result<FareQuotes>> quote(TripDraft draft, {String? couponCode});

  /// The rider's wallet balance in whole currency units.
  Future<Result<int>> walletBalance();

  /// Requests the trip at [quote]'s price. Returns the new trip's id.
  Future<Result<String>> request({
    required TripDraft draft,
    required FareQuote quote,
    required PaymentMethod payment,
  });
}
