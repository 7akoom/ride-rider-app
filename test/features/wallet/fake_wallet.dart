import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/wallet/domain/entities/statement.dart';
import 'package:rider_app/features/wallet/domain/entities/top_up.dart';
import 'package:rider_app/features/wallet/domain/entities/voucher_credit.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_movement.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_overview.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_pin.dart';
import 'package:rider_app/features/wallet/domain/repositories/wallet_pin_repository.dart';
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
    this.voucherResult = const Ok(VoucherCredit(amount: 10000, balance: 22500)),
    this.topUpOptionsResult = const Ok(TopUpOptions(min: 1000, max: 1000000, providers: [TopUpOptions.zainCash])),
    Result<TopUpStart>? startResult,
    List<Result<TopUpStatus>>? statuses,
  })  : startResult = startResult ?? Ok(TopUpStart(id: 'topup-1', page: Uri.parse('https://pay.example/topup-1'))),
        statuses = statuses ?? [const Ok(TopUpStatus.pending)],
        latest = latest ??
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
  Result<VoucherCredit> voucherResult;
  Result<TopUpOptions> topUpOptionsResult;
  Result<TopUpStart> startResult;

  /// How the top-up stands at each check, in order; the last one stays.
  List<Result<TopUpStatus>> statuses;
  final List<(int, String)> startedTopUps = [];
  int topUpChecks = 0;
  final List<(MovementFilter, String?)> asked = [];
  final List<String> redeemed = [];

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

  @override
  Future<Result<VoucherCredit>> redeemVoucher(String code) async {
    redeemed.add(code);

    return voucherResult;
  }

  @override
  Future<Result<TopUpOptions>> topUpOptions() async => topUpOptionsResult;

  @override
  Future<Result<TopUpStart>> startTopUp({required int amount, required String language}) async {
    startedTopUps.add((amount, language));

    return startResult;
  }

  @override
  Future<Result<TopUpStatus>> topUpStatus(String id) async {
    final status = statuses[topUpChecks < statuses.length ? topUpChecks : statuses.length - 1];
    topUpChecks++;

    return status;
  }
}

/// The wallet PIN as identity-service keeps it: [pin] is the PIN set (null: none),
/// [lockedUntil] a lock. A wrong current PIN counts like the server's.
class FakeWalletPin implements WalletPinRepository {
  FakeWalletPin({this.pin, this.lockedUntil, this.attemptsLeft = 5, this.freshSignIn = false, this.setFailure});

  String? pin;
  DateTime? lockedUntil;
  int attemptsLeft;

  /// The rider signed in moments ago: a new PIN without the current one is accepted.
  bool freshSignIn;

  /// When set, saving fails with it.
  Failure? setFailure;
  final List<(String, String?)> sets = [];

  PinStatus get _status => PinStatus(isSet: pin != null, lockedUntil: lockedUntil, attemptsLeft: attemptsLeft);

  @override
  Future<Result<PinStatus>> status() async => Ok(_status);

  final List<String> verified = [];

  @override
  Future<Result<PinCheck>> verify(String pin) async {
    verified.add(pin);
    final locked = lockedUntil;

    if (this.pin == null) {
      return const Ok(PinCheck(PinCheckResult.notSet));
    }

    if (locked != null && locked.isAfter(DateTime.now())) {
      return Ok(PinCheck(PinCheckResult.locked, lockedUntil: locked));
    }

    if (pin == this.pin) {
      attemptsLeft = 5;

      return const Ok(PinCheck(PinCheckResult.ok, attemptsLeft: 5));
    }

    attemptsLeft--;

    if (attemptsLeft <= 0) {
      lockedUntil = DateTime.now().add(const Duration(minutes: 15));

      return Ok(PinCheck(PinCheckResult.locked, lockedUntil: lockedUntil));
    }

    return Ok(PinCheck(PinCheckResult.wrong, attemptsLeft: attemptsLeft));
  }

  @override
  Future<Result<PinStatus>> set({required String newPin, String? currentPin}) async {
    sets.add((newPin, currentPin));
    final failure = setFailure;

    if (failure != null) {
      return Err(failure);
    }

    if (pin != null && !freshSignIn) {
      if (lockedUntil != null) {
        return const Err(PreconditionFailure());
      }

      if (currentPin == null) {
        return const Err(PreconditionFailure());
      }

      if (currentPin != pin) {
        attemptsLeft--;

        return const Err(ForbiddenFailure());
      }
    }

    pin = newPin;
    lockedUntil = null;
    attemptsLeft = 5;

    return Ok(_status);
  }
}
