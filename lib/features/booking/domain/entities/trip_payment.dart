import 'payment_method.dart';

/// How a finished trip was paid, once the platform settled it. Whole currency units.
final class TripPayment {
  const TripPayment({
    required this.method,
    required this.fare,
    this.fromWallet = 0,
    this.cash = 0,
    this.change = 0,
    this.tip = 0,
  });

  final PaymentMethod method;

  /// What the trip cost.
  final int fare;
  final int fromWallet;

  /// What the rider hands the captain.
  final int cash;

  /// Change the captain had not, put in the rider's wallet instead.
  final int change;
  final int tip;

  /// Everything the trip took from the rider, the tip with it.
  int get total => fare + tip;
}
