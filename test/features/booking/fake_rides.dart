import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/features/booking/domain/entities/fare_quote.dart';
import 'package:rider_app/features/booking/domain/entities/passenger.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';
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
  DiscountKind discount = DiscountKind.none,
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
      discount: discount,
    );

/// A ride for tests: waiting for a captain unless told otherwise.
Ride rideOf({
  String id = 'trip-1',
  RideStatus status = RideStatus.searching,
  bool noCaptain = false,
  String vehicleClass = 'economy',
  PaymentMethod payment = PaymentMethod.cash,
}) =>
    Ride(
      id: id,
      status: noCaptain ? RideStatus.cancelled : status,
      pickup: const GeoPoint(36.19, 44.01),
      dropoff: const GeoPoint(36.23, 43.98),
      pickupAddress: 'Gulan Street',
      dropoffAddress: 'Family Mall',
      vehicleClass: vehicleClass,
      payment: payment,
      fare: 3000,
      requestedAt: DateTime.now(),
      cancelledBySystem: noCaptain,
      cancellationReason: noCaptain ? 'no drivers available' : '',
    );

class FakeRides implements RidesRepository {
  FakeRides({
    List<FareQuote>? quotes,
    this.quoteFailure,
    this.orderFailure,
    this.balance = const Ok(12500),
    this.active,
  }) : quotes = quotes ?? [quoteOf('economy', 3000), quoteOf('comfort', 3750)];

  List<FareQuote> quotes;
  Failure? quoteFailure;
  Failure? orderFailure;
  Result<int> balance;

  /// What the ride's state reads as, from the next read on.
  Ride? state;
  Ride? active;
  Failure? cancelFailure;

  /// With this code the prices come back lowered by a quarter, coupon applied; any
  /// other code is not found.
  static const String goodCode = 'BTS26';

  final List<String?> couponsTried = [];
  final List<(FareQuote, PaymentMethod)> orders = [];
  final List<Passenger?> passengers = [];
  final List<String> cancelled = [];

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
              discount: DiscountKind.coupon,
            ),
          _ => quoteOf(q.vehicleClass, q.total, coupon: CouponResult.notFound),
        },
    ]));
  }

  @override
  Future<Result<int>> walletBalance() async => balance;

  @override
  Future<Result<Ride>> request({
    required TripDraft draft,
    required FareQuote quote,
    required PaymentMethod payment,
    Passenger? passenger,
  }) async {
    orders.add((quote, payment));
    passengers.add(passenger);
    final f = orderFailure;

    return f == null
        ? Ok(rideOf(id: 'trip-${orders.length}', vehicleClass: quote.vehicleClass, payment: payment))
        : Err(f);
  }

  @override
  Future<Result<Ride>> ride(String id) async => Ok(state ?? rideOf(id: id));

  @override
  Future<Result<Ride?>> activeRide() async => Ok(active);

  @override
  Future<Result<Ride>> cancel(String id) async {
    cancelled.add(id);
    final f = cancelFailure;

    return f == null ? Ok(rideOf(id: id, status: RideStatus.cancelled)) : Err(f);
  }
}
