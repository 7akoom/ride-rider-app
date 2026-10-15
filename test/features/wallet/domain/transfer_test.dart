import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/phone/phone_number.dart';
import 'package:rider_app/features/wallet/data/transfer_repository_impl.dart';
import 'package:rider_app/features/wallet/domain/entities/transfer.dart';
import 'package:rider_app/features/wallet/domain/use_cases/send_money.dart';

import '../fake_wallet.dart';

final _phone = PhoneNumber.tryParse('07501234567')!;

void main() {
  const options = TransferOptions(min: 250, max: 10000, dailyAmount: 20000, dailyCount: 3, sentAmount: 15000, sentCount: 1);

  test('an amount is checked against the limits, the day and the balance', () {
    expect(options.leftToday, 5000);
    expect(options.mostNow(4000), 4000);
    expect(options.mostNow(50000), 5000);

    expect(options.problemOf(100, balance: 9000), TransferAmountProblem.tooSmall);
    expect(options.problemOf(12000, balance: 90000), TransferAmountProblem.tooBig);
    expect(options.problemOf(6000, balance: 90000), TransferAmountProblem.overToday);
    expect(options.problemOf(4000, balance: 3000), TransferAmountProblem.overBalance);
    expect(options.problemOf(4000, balance: 9000), isNull);

    const used = TransferOptions(min: 250, max: 10000, dailyAmount: 20000, dailyCount: 3, sentCount: 3);
    expect(used.problemOf(1000, balance: 9000), TransferAmountProblem.tooManyToday);
  });

  test('the answers read the JSON with its defaults left out', () {
    final read = transferOptionsOf(const {
      'currencyCode': 'IQD',
      'minAmount': '250',
      'maxAmount': '1000000.000',
      'dailyAmount': '2000000',
      'dailyCount': 10,
      'sentAmount': '5000',
      'sentCount': 1,
    });
    expect((read.min, read.max, read.dailyAmount, read.dailyCount, read.sentAmount, read.sentCount),
        (250, 1000000, 2000000, 10, 5000, 1));
    expect(transferOptionsOf(const {'minAmount': '250'}).sentCount, 0);

    final found = recipientOf(_phone, const {'result': 'found', 'displayName': 'Haidar K.'});
    expect((found.result, found.name), (RecipientResult.found, 'Haidar K.'));
    expect(recipientOf(_phone, const {'result': 'not_found'}).result, RecipientResult.notFound);
    expect(recipientOf(_phone, const {'result': 'self'}).result, RecipientResult.self);
    expect(() => recipientOf(_phone, const {}), throwsFormatException);

    final recent = recentRecipientsOf(const {
      'transfers': [
        {'direction': 'sent', 'counterpartPhone': '+9647501234567'},
        {'direction': 'received', 'counterpartPhone': '+9647709999999'},
        {'direction': 'sent', 'counterpartPhone': '+9647701111111'},
        {'direction': 'sent', 'counterpartPhone': '+9647501234567'},
      ],
    });
    expect(recent.map((p) => p.e164), ['+9647501234567', '+9647701111111']);

    final sent = sentMoneyOf(_phone, const {
      'transfer': {'id': 't1', 'amount': '5000', 'note': 'dinner', 'createdAt': '2026-10-15T11:30:00Z'},
      'wallet': {'balance': '7500'},
    });
    expect((sent.id, sent.amount, sent.note, sent.balance), ('t1', 5000, 'dinner', 7500));
    expect(sent.at, DateTime.utc(2026, 10, 15, 11, 30).toLocal());
  });

  test('a note too long or an empty PIN never reaches the server', () async {
    final transfers = FakeTransfers();
    final send = SendMoney(transfers);

    final long = await send(phone: _phone, amount: 1000, note: 'x' * 141, pin: '2580', key: 'k');
    expect((long as Err).failure, isA<InvalidInputFailure>());
    expect((await send(phone: _phone, amount: 1000, note: '', pin: '', key: 'k')), isA<Err<SentMoney>>());
    expect(transfers.sent, isEmpty);

    expect(await send(phone: _phone, amount: 1000, note: ' hi ', pin: '2580', key: 'k'), isA<Ok<SentMoney>>());
    expect(transfers.sent.single.note, 'hi');
  });
}
