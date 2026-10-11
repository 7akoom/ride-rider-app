import '../../../core/error/failure.dart';
import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../domain/entities/payment_method.dart';
import '../domain/entities/trip_payment.dart';
import '../domain/repositories/trip_end_repository.dart';
import '../../../core/rider/rider_id.dart';
import 'trip_end_api.dart';

final class TripEndRepositoryImpl implements TripEndRepository {
  TripEndRepositoryImpl(this._api);

  final TripEndApi _api;

  @override
  Future<Result<TripPayment?>> payment(String tripId) async {
    final result = await guard<TripPayment?>(() async => paymentOf(await _api.settlement(await riderIdOrSignIn(), tripId)));

    // Not settled yet: asked again shortly.
    return switch (result) {
      Err(failure: NotFoundFailure()) => const Ok(null),
      _ => result,
    };
  }

  /// Reads a settlement answer. Missing amounts are zero.
  static TripPayment paymentOf(JsonMap json) => TripPayment(
        method: json['paymentMethod'] == 'PAYMENT_METHOD_WALLET' ? PaymentMethod.wallet : PaymentMethod.cash,
        fare: amountAt(json, 'fareAmount') ?? 0,
        fromWallet: amountAt(json, 'walletAmount') ?? 0,
        cash: amountAt(json, 'cashAmount') ?? 0,
        change: amountAt(json, 'changeAmount') ?? 0,
        tip: amountAt(json, 'tipAmount') ?? 0,
      );

  @override
  Future<Result<void>> rate(String tripId, int stars, String comment) async {
    final result = await guard<void>(() => _api.rate(tripId, {
          'ratedBy': 'RATED_BY_RIDER',
          'stars': stars,
          if (comment.isNotEmpty) 'comment': comment,
        }));

    // Already rated (from another phone, or a retry): the rating stands.
    return switch (result) {
      Err(failure: ConflictFailure()) => const Ok(null),
      _ => result,
    };
  }

  @override
  Future<Result<void>> tip(String tripId, int amount, String key) => guard(
        () async => _api.tip(await riderIdOrSignIn(), tripId, {
          'amount': '$amount',
          'idempotencyKey': key,
        }),
      );
}
