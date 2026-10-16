import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/rider/rider_id.dart';
import '../domain/entities/money_request.dart';
import '../domain/repositories/money_request_repository.dart';
import 'money_request_api.dart';

final class MoneyRequestRepositoryImpl implements MoneyRequestRepository {
  MoneyRequestRepositoryImpl(this._api);

  final MoneyRequestApi _api;

  @override
  Future<Result<MoneyRequest>> create({
    PhoneNumber? payer,
    required int amount,
    required String note,
    required String key,
  }) =>
      guard(() async => moneyRequestIn(await _api.create(
            await riderIdOrSignIn(),
            payerPhone: payer?.e164 ?? '',
            amount: '$amount',
            note: note,
            key: key,
          )));

  @override
  Future<Result<List<MoneyRequest>>> list(MoneyRequestSide side, {MoneyRequestStatus? status}) => guard(() async {
        final json = await _api.list(
          await riderIdOrSignIn(),
          role: side.name,
          status: status?.name ?? '',
        );
        final items = json['moneyRequests'];

        return [
          if (items is List)
            for (final item in items)
              if (item is Map) moneyRequestOf(decodeJsonObject(item)),
        ];
      });

  @override
  Future<Result<MoneyRequest>> byCode(String code) =>
      guard(() async => moneyRequestIn(await _api.get(await riderIdOrSignIn(), code)));

  @override
  Future<Result<PaidRequest>> pay(String code, String pin) =>
      guard(() async => paidRequestOf(await _api.pay(await riderIdOrSignIn(), code, pin)));

  @override
  Future<Result<MoneyRequest>> decline(String code) =>
      guard(() async => moneyRequestIn(await _api.decline(await riderIdOrSignIn(), code)));

  @override
  Future<Result<MoneyRequest>> cancel(String code) =>
      guard(() async => moneyRequestIn(await _api.cancel(await riderIdOrSignIn(), code)));
}

/// The request in a MoneyRequestResponse.
MoneyRequest moneyRequestIn(JsonMap json) =>
    moneyRequestOf(objectAt(json, 'moneyRequest') ?? (throw const FormatException('no money request in the answer')));

/// A MoneyRequest message; fields at their defaults are left out.
MoneyRequest moneyRequestOf(JsonMap json) {
  String text(String key) => json[key] is String ? json[key] as String : '';
  DateTime? time(String key) => DateTime.tryParse(text(key))?.toLocal();

  final role = switch (text('role')) {
    'requester' => MoneyRequestRole.requester,
    'payer' => MoneyRequestRole.payer,
    'viewer' => MoneyRequestRole.viewer,
    _ => throw const FormatException('an unknown money request role'),
  };
  final status = switch (text('status')) {
    'pending' => MoneyRequestStatus.pending,
    'paid' => MoneyRequestStatus.paid,
    'declined' => MoneyRequestStatus.declined,
    'cancelled' => MoneyRequestStatus.cancelled,
    'expired' => MoneyRequestStatus.expired,
    _ => throw const FormatException('an unknown money request status'),
  };

  return MoneyRequest(
    id: requiredText(json, 'id'),
    code: requiredText(json, 'code'),
    role: role,
    open: json['open'] == true,
    amount: requiredAmount(json, 'amount'),
    status: status,
    expiresAt: time('expiresAt') ?? (throw const FormatException('no expiry in the answer')),
    createdAt: time('createdAt') ?? DateTime.now(),
    requesterName: text('requesterName'),
    requesterPhone: text('requesterPhone'),
    payerName: text('payerName'),
    payerPhone: text('payerPhone'),
    note: text('note'),
    closedAt: time('closedAt'),
  );
}

PaidRequest paidRequestOf(JsonMap json) {
  final transfer = objectAt(json, 'transfer') ?? (throw const FormatException('no transfer in the answer'));
  final wallet = objectAt(json, 'wallet');
  final at = DateTime.tryParse(transfer['createdAt'] is String ? transfer['createdAt'] as String : '');

  return PaidRequest(
    request: moneyRequestIn(json),
    transferId: requiredText(transfer, 'id'),
    at: at?.toLocal() ?? DateTime.now(),
    balance: wallet == null ? null : amountAt(wallet, 'balance'),
  );
}
