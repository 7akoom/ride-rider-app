import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/trip_payment.dart';
import 'package:rider_app/features/booking/domain/repositories/trip_end_repository.dart';

const cashPayment = TripPayment(method: PaymentMethod.cash, fare: 3000, cash: 3000);

/// After a trip: settled after [settleAfter] reads, rating and tips remembered.
class FakeTripEnd implements TripEndRepository {
  FakeTripEnd({this.paid = cashPayment, this.settleAfter = 0, this.tipFailure});

  /// What the settlement says once there; null keeps it away for ever.
  TripPayment? paid;
  int settleAfter;
  Failure? tipFailure;
  int reads = 0;
  final List<(int, String)> ratings = [];
  final List<(int, String)> tips = [];

  @override
  Future<Result<TripPayment?>> payment(String tripId) async {
    reads++;

    return Ok(reads > settleAfter ? paid : null);
  }

  @override
  Future<Result<void>> rate(String tripId, int stars, String comment) async {
    ratings.add((stars, comment));

    return const Ok(null);
  }

  @override
  Future<Result<void>> tip(String tripId, int amount, String key) async {
    tips.add((amount, key));
    final f = tipFailure;

    return f == null ? const Ok(null) : Err(f);
  }
}
