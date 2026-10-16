import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/phone/phone_number.dart';
import '../entities/money_request.dart';
import '../repositories/money_request_repository.dart';
import 'send_money.dart';

/// Asks for money. A note longer than a transfer's is refused here.
final class RequestMoney {
  const RequestMoney(this.requests);

  final MoneyRequestRepository requests;

  Future<Result<MoneyRequest>> call({PhoneNumber? payer, required int amount, required String note, required String key}) {
    final trimmed = note.trim();

    if (amount <= 0 || trimmed.runes.length > SendMoney.maxNote || key.isEmpty) {
      return Future.value(const Err(InvalidInputFailure()));
    }

    return requests.create(payer: payer, amount: amount, note: trimmed, key: key);
  }
}

final class LoadMoneyRequests {
  const LoadMoneyRequests(this.requests);

  final MoneyRequestRepository requests;

  Future<Result<List<MoneyRequest>>> call(MoneyRequestSide side, {MoneyRequestStatus? status}) =>
      requests.list(side, status: status);
}

/// Opens a request by a code as typed; one that cannot be a code is not looked up.
final class OpenMoneyRequest {
  const OpenMoneyRequest(this.requests);

  final MoneyRequestRepository requests;

  Future<Result<MoneyRequest>> call(String typed) {
    final code = normalizeRequestCode(typed);

    return code == null ? Future.value(const Err(NotFoundFailure())) : requests.byCode(code);
  }
}

final class PayMoneyRequest {
  const PayMoneyRequest(this.requests);

  final MoneyRequestRepository requests;

  Future<Result<PaidRequest>> call(String code, String pin) =>
      pin.isEmpty ? Future.value(const Err(InvalidInputFailure())) : requests.pay(code, pin);
}

final class DeclineMoneyRequest {
  const DeclineMoneyRequest(this.requests);

  final MoneyRequestRepository requests;

  Future<Result<MoneyRequest>> call(String code) => requests.decline(code);
}

final class CancelMoneyRequest {
  const CancelMoneyRequest(this.requests);

  final MoneyRequestRepository requests;

  Future<Result<MoneyRequest>> call(String code) => requests.cancel(code);
}
