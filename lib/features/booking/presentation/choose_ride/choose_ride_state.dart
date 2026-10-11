import '../../../../core/error/failure.dart';
import '../../domain/entities/fare_quote.dart';
import '../../domain/entities/passenger.dart';
import '../../domain/entities/payment_method.dart';

/// Stands for "leave as it is" in [ChooseRideState.copyWith], so null can clear.
const Object _same = Object();

final class ChooseRideState {
  const ChooseRideState({
    this.quotes,
    this.quoteFailure,
    this.loading = true,
    this.selectedClass,
    this.payment = PaymentMethod.cash,
    this.couponCode,
    this.ordering = false,
    this.orderFailure,
    this.passenger,
    this.bookingFailure,
  });

  /// The last prices; kept on screen while new ones load.
  final FareQuotes? quotes;

  /// The prices could not be loaded (and there are none to show).
  final Failure? quoteFailure;
  final bool loading;
  final String? selectedClass;
  final PaymentMethod payment;

  /// The code tried on every price, as sent.
  final String? couponCode;
  final bool ordering;

  /// Why the last request did not go through.
  final Failure? orderFailure;

  /// Set when the ride is for someone else.
  final Passenger? passenger;

  /// Why booking ahead did not go through.
  final Failure? bookingFailure;

  FareQuote? get selected => quotes?.ofClass(selectedClass);

  /// What became of the coupon on the chosen ride type.
  CouponResult get coupon => selected?.coupon ?? CouponResult.none;

  bool get canOrder => selected != null && !loading && !ordering;

  ChooseRideState copyWith({
    Object? quotes = _same,
    Object? quoteFailure = _same,
    bool? loading,
    Object? selectedClass = _same,
    PaymentMethod? payment,
    Object? couponCode = _same,
    bool? ordering,
    Object? orderFailure = _same,
    Object? passenger = _same,
    Object? bookingFailure = _same,
  }) =>
      ChooseRideState(
        quotes: identical(quotes, _same) ? this.quotes : quotes as FareQuotes?,
        quoteFailure:
            identical(quoteFailure, _same) ? this.quoteFailure : quoteFailure as Failure?,
        loading: loading ?? this.loading,
        selectedClass:
            identical(selectedClass, _same) ? this.selectedClass : selectedClass as String?,
        payment: payment ?? this.payment,
        couponCode: identical(couponCode, _same) ? this.couponCode : couponCode as String?,
        ordering: ordering ?? this.ordering,
        orderFailure:
            identical(orderFailure, _same) ? this.orderFailure : orderFailure as Failure?,
        passenger: identical(passenger, _same) ? this.passenger : passenger as Passenger?,
        bookingFailure:
            identical(bookingFailure, _same) ? this.bookingFailure : bookingFailure as Failure?,
      );
}
