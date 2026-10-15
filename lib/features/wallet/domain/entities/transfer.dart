import '../../../../core/phone/phone_number.dart';

/// Why an amount cannot be sent now.
enum TransferAmountProblem { tooSmall, tooBig, overToday, tooManyToday, overBalance }

/// What a transfer may be for the rider now: [min] to [max] each, and at most
/// [dailyAmount] in [dailyCount] transfers in any 24 hours, of which [sentAmount] in
/// [sentCount] went out already. Whole currency units.
final class TransferOptions {
  const TransferOptions({
    required this.min,
    required this.max,
    required this.dailyAmount,
    required this.dailyCount,
    this.sentAmount = 0,
    this.sentCount = 0,
  });

  final int min;
  final int max;
  final int dailyAmount;
  final int dailyCount;
  final int sentAmount;
  final int sentCount;

  /// How much more may go out in the next 24 hours.
  int get leftToday => dailyAmount > sentAmount ? dailyAmount - sentAmount : 0;

  /// The most one transfer may move now (the limit, the day's rest, the [balance]).
  int mostNow(int balance) => [max, leftToday, balance].reduce((a, b) => a < b ? a : b);

  /// What is wrong with sending [amount] out of [balance]; null when it can go.
  TransferAmountProblem? problemOf(int amount, {required int balance}) {
    if (sentCount >= dailyCount) {
      return TransferAmountProblem.tooManyToday;
    }

    if (amount < min) {
      return TransferAmountProblem.tooSmall;
    }

    if (amount > max) {
      return TransferAmountProblem.tooBig;
    }

    if (amount > leftToday) {
      return TransferAmountProblem.overToday;
    }

    if (amount > balance) {
      return TransferAmountProblem.overBalance;
    }

    return null;
  }
}

/// What a phone is for a transfer.
enum RecipientResult { found, notFound, self }

/// A looked-up phone: [name] is the rider's short name ("Haidar K."), set when found.
final class Recipient {
  const Recipient({required this.phone, required this.result, this.name = ''});

  final PhoneNumber phone;
  final RecipientResult result;
  final String name;
}

/// A transfer that went through.
final class SentMoney {
  const SentMoney({
    required this.id,
    required this.phone,
    required this.amount,
    required this.at,
    this.note = '',
    this.balance,
  });

  final String id;
  final PhoneNumber phone;
  final int amount;
  final DateTime at;
  final String note;

  /// The wallet after it, when the server said.
  final int? balance;
}
