import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/wallet/domain/entities/statement.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_movement.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_overview.dart';
import 'package:rider_app/features/wallet/domain/repositories/wallet_repository.dart';

WalletMovement movementOf(MovementKind kind, int amount, {String id = 'm', DateTime? at, int? balanceAfter}) =>
    WalletMovement(id: id, kind: kind, amount: amount, at: at ?? DateTime(2026, 10, 11, 9, 30), balanceAfter: balanceAfter);

/// A wallet of 12,500 with a few movements; [pages] are the statement's pages in order.
class FakeWallet implements WalletRepository {
  FakeWallet({
    this.overviewResult = const Ok(WalletOverview(balance: 12500)),
    List<WalletMovement>? latest,
    List<StatementPage>? pages,
    this.statementFailure,
  })  : latest = latest ??
            [
              movementOf(MovementKind.topUp, 10000, id: 'a'),
              movementOf(MovementKind.tripPayment, -3000, id: 'b'),
            ],
        pages = pages ??
            [
              StatementPage(
                movements: [movementOf(MovementKind.voucher, 3000, id: 'c', balanceAfter: 12500)],
                opening: 9500,
                closing: 12500,
                totalIn: 3000,
                totalOut: 0,
              ),
            ];

  Result<WalletOverview> overviewResult;
  List<WalletMovement> latest;
  List<StatementPage> pages;
  Failure? statementFailure;
  final List<(MovementFilter, String?)> asked = [];

  @override
  Future<Result<WalletOverview>> overview() async => overviewResult;

  @override
  Future<Result<List<WalletMovement>>> recent(int limit) async => Ok(latest.take(limit).toList());

  @override
  Future<Result<StatementPage>> statement({
    required DateTime from,
    required DateTime to,
    MovementFilter filter = MovementFilter.all,
    String? page,
  }) async {
    asked.add((filter, page));
    final f = statementFailure;
    if (f != null) {
      return Err(f);
    }

    return Ok(pages[page == null ? 0 : int.parse(page)]);
  }
}
