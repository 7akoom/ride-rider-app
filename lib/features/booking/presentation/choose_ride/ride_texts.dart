import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/fare_quote.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/use_cases/order_ride.dart';
import '../../domain/use_cases/quote_ride.dart';

/// The words and icons for ordering a ride, in the rider's language.
abstract final class RideTexts {
  /// Every ride type has four seats in this platform's fleet.
  static const int seats = 4;

  static String vehicle(AppLocalizations l10n, String vehicleClass) =>
      switch (vehicleClass) {
        'comfort' => l10n.vehicleComfort,
        _ => l10n.vehicleEconomy,
      };

  static String payment(AppLocalizations l10n, PaymentMethod method) => switch (method) {
        PaymentMethod.cash => l10n.paymentCash,
        PaymentMethod.wallet => l10n.paymentWallet,
      };

  static IconData paymentIcon(PaymentMethod method) => switch (method) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.wallet => Icons.account_balance_wallet_outlined,
      };

  /// The prices could not be loaded.
  static String quoteFailure(AppLocalizations l10n, Failure failure) =>
      isOutsideServiceArea(failure) ? l10n.chooseRideOutsideArea : failure.message(l10n);

  /// The request was refused or failed.
  static String orderFailure(AppLocalizations l10n, Failure failure) =>
      switch (orderProblemOf(failure)) {
        OrderProblem.pricesChanged => l10n.chooseRidePricesUpdated,
        OrderProblem.notNow => l10n.chooseRideNotNow,
        null => failure.message(l10n),
      };

  /// What became of the coupon; null when no code was tried.
  static String? coupon(AppLocalizations l10n, CouponResult result, String code) =>
      switch (result) {
        CouponResult.none => null,
        CouponResult.applied => l10n.couponApplied(code),
        CouponResult.notFound => l10n.couponNotFound,
        CouponResult.ended => l10n.couponEnded,
        CouponResult.notStarted => l10n.couponNotStarted,
        CouponResult.expired => l10n.couponExpired,
        CouponResult.usedUp => l10n.couponUsedUp,
        CouponResult.alreadyUsed => l10n.couponAlreadyUsed,
        CouponResult.notInArea => l10n.couponNotInArea,
        CouponResult.notForClass => l10n.couponNotForClass,
        CouponResult.newRidersOnly => l10n.couponNewRidersOnly,
        CouponResult.belowMinimum => l10n.couponBelowMinimum,
        CouponResult.betterDiscount => l10n.couponBetterDiscount,
      };
}
