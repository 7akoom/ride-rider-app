import '../../../../core/error/result.dart';
import '../../../../core/phone/phone_number.dart';
import '../entities/money_request.dart';

/// Asking riders for money, and paying what others ask (wallet-service).
abstract interface class MoneyRequestRepository {
  /// Asks [payer] (or, with null, whoever opens its code) for [amount]. The same
  /// [key] again is the same request. A phone that is no rider's is a
  /// NotFoundFailure; the rider's own phone or an amount outside the transfer limits
  /// is an InvalidInputFailure; too many phones asked in an hour is a
  /// RateLimitedFailure (it counts as a lookup).
  Future<Result<MoneyRequest>> create({PhoneNumber? payer, required int amount, required String note, required String key});

  /// Newest first; [status] null for all.
  Future<Result<List<MoneyRequest>>> list(MoneyRequestSide side, {MoneyRequestStatus? status});

  /// Opens a request by its code. One the rider may not see is a NotFoundFailure.
  Future<Result<MoneyRequest>> byCode(String code);

  /// Pays it with [pin]. A wrong PIN is a ForbiddenFailure; a locked PIN, the daily
  /// limits, the balance or a request no longer pending a PreconditionFailure; an
  /// amount the limits no longer allow an InvalidInputFailure. Paying again what
  /// was paid returns that payment.
  Future<Result<PaidRequest>> pay(String code, String pin);

  /// The rider it is for says no.
  Future<Result<MoneyRequest>> decline(String code);

  /// The requester takes it back.
  Future<Result<MoneyRequest>> cancel(String code);
}
