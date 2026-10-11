import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/features/wallet/data/wallet_json.dart';
import 'package:rider_app/features/wallet/domain/entities/statement.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_movement.dart';

void main() {
  test('a statement is read with its totals, signed movements and next page', () {
    final page = WalletJson.statementOf({
      'openingBalance': '5000.00',
      'closingBalance': '12500',
      'totalIn': '10500',
      'totalOut': '3000',
      'nextPageToken': 'p2',
      'entries': [
        {'id': 't1', 'type': 'TRANSACTION_TYPE_TRIP_PAYMENT', 'amount': '-3000.00', 'balanceAfter': '2000', 'createdAt': '2026-10-11T06:00:00Z'},
        {'id': 't2', 'type': 'TRANSACTION_TYPE_TOP_UP', 'amount': '10500', 'createdAt': '2026-10-11T07:00:00Z'},
        {'id': 't3', 'type': 'TRANSACTION_TYPE_SOMETHING_NEW', 'amount': '1'},
      ],
    });

    expect(page.opening, 5000);
    expect(page.totalOut, 3000);
    expect(page.next, 'p2');
    expect(page.movements.map((m) => m.kind), [MovementKind.tripPayment, MovementKind.topUp, MovementKind.other]);
    expect(page.movements.first.amount, -3000);
    expect(page.movements.first.isIn, isFalse);
    expect(page.movements.first.balanceAfter, 2000);
  });

  test('the last page has no next page', () {
    expect(WalletJson.statementOf({'nextPageToken': ''}).next, isNull);
  });

  test('each filter is the statement query it stands for', () {
    expect(WalletJson.filterOf(MovementFilter.all), isEmpty);
    expect(WalletJson.filterOf(MovementFilter.moneyIn), {'direction': 'in'});
    expect(WalletJson.filterOf(MovementFilter.tips), {'types': 'TRANSACTION_TYPE_TIP'});
  });
}
