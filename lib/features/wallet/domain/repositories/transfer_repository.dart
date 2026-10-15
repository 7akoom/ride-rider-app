import '../../../../core/error/result.dart';
import '../../../../core/phone/phone_number.dart';
import '../entities/transfer.dart';

/// Sending money to other riders from the wallet.
abstract interface class TransferRepository {
  Future<Result<TransferOptions>> options();

  /// Whether a transfer to [phone] would reach a rider, with the rider's short name.
  /// Lookups are counted: too many in an hour is a RateLimitedFailure.
  Future<Result<Recipient>> lookup(PhoneNumber phone);

  /// The phones the rider sent to lately, newest first, each once.
  Future<Result<List<PhoneNumber>>> recentRecipients();

  /// Sends [amount] to [phone], confirmed with [pin]. The same [key] again is the same
  /// transfer, never a second one. A wrong PIN is a ForbiddenFailure; a locked or
  /// missing PIN, the daily limits or the balance are a PreconditionFailure; a phone
  /// that is no rider's any more is a NotFoundFailure.
  Future<Result<SentMoney>> send({
    required PhoneNumber phone,
    required int amount,
    required String note,
    required String pin,
    required String key,
  });
}
