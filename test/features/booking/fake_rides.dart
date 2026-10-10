import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/booking/domain/entities/fare_quote.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';
import 'package:rider_app/features/booking/domain/repositories/rides_repository.dart';

/// A price valid for ten minutes, for tests.
FareQuote quoteOf(
  String vehicleClass,
  int total, {
  int? beforeDiscount,
  bool surging = false,
  bool driversAvailable = true,
  CouponResult coupon = CouponResult.none,
}) =>
    FareQuote(
      id: 'q-$vehicleClass-$total',
      vehicleClass: vehicleClass,
      total: total,
      beforeDiscount: beforeDiscount,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      driversAvailable: driversAvailable,
      pickupEtaMinutes: 5,
      surging: surging,
      coupon: coupon,
    );

class FakeRides implements RidesRepository {
  FakeRides({
    List<FareQuote>? quotes,
    this.quoteFailure,
    this.orderFailure,
    this.balance = const Ok(12500),
  }) : quotes = quotes ?? [quoteOf('economy', 3000), quoteOf('comfort', 3750)];

  List<FareQuote> quotes;
  Failure? quoteFailure;
  Failure? orderFailure;
  Result<int> balance;

  /// With this code the prices come back lowered by a quarter, coupon applied; any
  /// other code is not found.
  static const String goodCode = 'BTS26';

  final List<String?> couponsTried = [];
  final List<(FareQuote, PaymentMethod)> orders = [];

  @override
  Future<Result<FareQuotes>> quote(TripDraft draft, {String? couponCode}) async {
    couponsTried.add(couponCode);
    final f = quoteFailure;

    if (f != null) {
      return Err(f);
    }

    return Ok(FareQuotes([
      for (final q in quotes)
        switch (couponCode) {
          null => q,
          goodCode => quoteOf(
              q.vehicleClass,
              q.total * 3 ~/ 4,
              beforeDiscount: q.total,
              coupon: CouponResult.applied,
            ),
          _ => quoteOf(q.vehicleClass, q.total, coupon: CouponResult.notFound),
        },
    ]));
  }

  @override
  Future<Result<int>> walletBalance() async => balance;

  @override
  Future<Result<String>> request({
    required TripDraft draft,
    required FareQuote quote,
    required PaymentMethod payment,
  }) async {
    orders.add((quote, payment));
    final f = orderFailure;

    return f == null ? const Ok('trip-1') : Err(f);
  }
}
