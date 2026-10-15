import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/rider/rider_id.dart';
import '../domain/entities/transfer.dart';
import '../domain/repositories/transfer_repository.dart';
import 'transfer_api.dart';

final class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl(this._api);

  final TransferApi _api;

  @override
  Future<Result<TransferOptions>> options() =>
      guard(() async => transferOptionsOf(await _api.options(await riderIdOrSignIn())));

  @override
  Future<Result<Recipient>> lookup(PhoneNumber phone) =>
      guard(() async => recipientOf(phone, await _api.lookup(await riderIdOrSignIn(), phone.e164)));

  @override
  Future<Result<List<PhoneNumber>>> recentRecipients() =>
      guard(() async => recentRecipientsOf(await _api.list(await riderIdOrSignIn())));

  @override
  Future<Result<SentMoney>> send({
    required PhoneNumber phone,
    required int amount,
    required String note,
    required String pin,
    required String key,
  }) =>
      guard(() async {
        final json = await _api.send(
          await riderIdOrSignIn(),
          phone: phone.e164,
          amount: '$amount',
          note: note,
          pin: pin,
          key: key,
        );

        return sentMoneyOf(phone, json);
      });
}

/// GetTransferOptionsResponse; fields at their defaults are left out.
TransferOptions transferOptionsOf(JsonMap json) {
  final dailyCount = json['dailyCount'];
  final sentCount = json['sentCount'];

  return TransferOptions(
    min: amountAt(json, 'minAmount') ?? 0,
    max: amountAt(json, 'maxAmount') ?? 0,
    dailyAmount: amountAt(json, 'dailyAmount') ?? 0,
    dailyCount: dailyCount is num ? dailyCount.toInt() : 0,
    sentAmount: amountAt(json, 'sentAmount') ?? 0,
    sentCount: sentCount is num ? sentCount.toInt() : 0,
  );
}

Recipient recipientOf(PhoneNumber phone, JsonMap json) {
  final result = switch (json['result']) {
    'found' => RecipientResult.found,
    'not_found' => RecipientResult.notFound,
    'self' => RecipientResult.self,
    _ => throw const FormatException('an unknown lookup result'),
  };
  final name = json['displayName'];

  return Recipient(phone: phone, result: result, name: name is String ? name : '');
}

/// The phones of the transfers the rider sent, newest first, each once.
List<PhoneNumber> recentRecipientsOf(JsonMap json) {
  final seen = <PhoneNumber>{};
  final transfers = json['transfers'];

  if (transfers is List) {
    for (final item in transfers) {
      if (item is Map && item['direction'] == 'sent' && item['counterpartPhone'] is String) {
        final phone = PhoneNumber.tryParse(item['counterpartPhone'] as String);

        if (phone != null) {
          seen.add(phone);
        }
      }
    }
  }

  return seen.toList();
}

SentMoney sentMoneyOf(PhoneNumber phone, JsonMap json) {
  final transfer = objectAt(json, 'transfer') ?? (throw const FormatException('no transfer in the answer'));
  final wallet = objectAt(json, 'wallet');
  final at = DateTime.tryParse(transfer['createdAt'] is String ? transfer['createdAt'] as String : '');
  final note = transfer['note'];

  return SentMoney(
    id: requiredText(transfer, 'id'),
    phone: phone,
    amount: requiredAmount(transfer, 'amount'),
    at: at?.toLocal() ?? DateTime.now(),
    note: note is String ? note : '',
    balance: wallet == null ? null : amountAt(wallet, 'balance'),
  );
}
