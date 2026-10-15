import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/phone/phone_number.dart';
import '../entities/transfer.dart';
import '../repositories/transfer_repository.dart';

final class LoadTransferOptions {
  const LoadTransferOptions(this.transfers);

  final TransferRepository transfers;

  Future<Result<TransferOptions>> call() => transfers.options();
}

final class LookupRecipient {
  const LookupRecipient(this.transfers);

  final TransferRepository transfers;

  Future<Result<Recipient>> call(PhoneNumber phone) => transfers.lookup(phone);
}

final class LoadRecentRecipients {
  const LoadRecentRecipients(this.transfers);

  final TransferRepository transfers;

  /// At most [count] phones.
  Future<Result<List<PhoneNumber>>> call({int count = 5}) async => switch (await transfers.recentRecipients()) {
        Ok(:final value) => Ok(value.take(count).toList()),
        Err(:final failure) => Err(failure),
      };
}

/// Sends money. A note longer than [maxNote] or an empty PIN is refused here.
final class SendMoney {
  const SendMoney(this.transfers);

  final TransferRepository transfers;

  static const int maxNote = 140;

  Future<Result<SentMoney>> call({
    required PhoneNumber phone,
    required int amount,
    required String note,
    required String pin,
    required String key,
  }) async {
    final trimmed = note.trim();

    if (amount <= 0 || trimmed.runes.length > maxNote || pin.isEmpty || key.isEmpty) {
      return const Err(InvalidInputFailure());
    }

    return transfers.send(phone: phone, amount: amount, note: trimmed, pin: pin, key: key);
  }
}
