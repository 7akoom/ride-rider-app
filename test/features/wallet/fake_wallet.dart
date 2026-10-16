import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/phone/phone_number.dart';
import 'package:rider_app/features/wallet/domain/entities/biometric.dart';
import 'package:rider_app/features/wallet/domain/entities/money_request.dart';
import 'package:rider_app/features/wallet/domain/entities/statement.dart';
import 'package:rider_app/features/wallet/domain/entities/top_up.dart';
import 'package:rider_app/features/wallet/domain/entities/transfer.dart';
import 'package:rider_app/features/wallet/domain/entities/voucher_credit.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_movement.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_overview.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_pin.dart';
import 'package:rider_app/features/wallet/domain/repositories/biometric_pin_repository.dart';
import 'package:rider_app/features/wallet/domain/repositories/money_request_repository.dart';
import 'package:rider_app/features/wallet/domain/repositories/transfer_repository.dart';
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

/// Transfers: [riders] are the registered phones with their short names; the rider's
/// own phone is [self]. Each send takes the next of [sendResults] (the last stays);
/// none means it goes through.
class FakeTransfers implements TransferRepository {
  FakeTransfers({
    this.optionsResult = const Ok(TransferOptions(min: 250, max: 100000, dailyAmount: 200000, dailyCount: 10)),
    Map<String, String>? riders,
    this.self = '+9647500000000',
    List<PhoneNumber>? recent,
    this.lookupFailure,
    List<Result<SentMoney>>? sendResults,
  })  : riders = riders ?? {'+9647501234567': 'Haidar K.'},
        recent = recent ?? [],
        sendResults = sendResults ?? [];

  Result<TransferOptions> optionsResult;
  Map<String, String> riders;
  String self;
  List<PhoneNumber> recent;
  Failure? lookupFailure;
  List<Result<SentMoney>> sendResults;
  final List<String> lookedUp = [];
  final List<({String phone, int amount, String note, String pin, String key})> sent = [];

  @override
  Future<Result<TransferOptions>> options() async => optionsResult;

  @override
  Future<Result<Recipient>> lookup(PhoneNumber phone) async {
    lookedUp.add(phone.e164);
    final failure = lookupFailure;

    if (failure != null) {
      return Err(failure);
    }

    if (phone.e164 == self) {
      return Ok(Recipient(phone: phone, result: RecipientResult.self));
    }

    final name = riders[phone.e164];

    return Ok(
      name == null
          ? Recipient(phone: phone, result: RecipientResult.notFound)
          : Recipient(phone: phone, result: RecipientResult.found, name: name),
    );
  }

  @override
  Future<Result<List<PhoneNumber>>> recentRecipients() async => Ok(recent);

  @override
  Future<Result<SentMoney>> send({
    required PhoneNumber phone,
    required int amount,
    required String note,
    required String pin,
    required String key,
  }) async {
    sent.add((phone: phone.e164, amount: amount, note: note, pin: pin, key: key));

    if (sendResults.isNotEmpty) {
      final result = sent.length <= sendResults.length ? sendResults[sent.length - 1] : sendResults.last;

      if (result is Err<SentMoney>) {
        return result;
      }
    }

    return Ok(
      SentMoney(
        id: 'f3a9c2d1-0000-4000-8000-000000000001',
        phone: phone,
        amount: amount,
        note: note,
        at: DateTime(2026, 10, 15, 14, 30),
        balance: 12500 - amount,
      ),
    );
  }
}

/// The phone's fingerprint check: [kind] is what it has (null: none), [confirms] what
/// the prompt answers, [pin] the PIN kept (null: paying this way is off).
class FakeBiometricPin implements BiometricPinRepository {
  FakeBiometricPin({this.kind, this.confirms = true, this.pin});

  BiometricKind? kind;
  bool confirms;
  String? pin;
  final List<String> prompts = [];

  @override
  Future<BiometricKind?> available() async => kind;

  @override
  Future<bool> confirm(String reason) async {
    prompts.add(reason);

    return confirms;
  }

  @override
  Future<String?> kept() async => pin;

  @override
  Future<void> keep(String pin) async => this.pin = pin;

  @override
  Future<void> forget() async => pin = null;
}

/// A request as wallet-service would give it; [role] is the signed-in rider's.
MoneyRequest requestOf({
  String code = 'K7XMQ2PQRX',
  MoneyRequestRole role = MoneyRequestRole.payer,
  bool open = false,
  int amount = 5000,
  MoneyRequestStatus status = MoneyRequestStatus.pending,
  String requesterName = 'Haidar K.',
  String requesterPhone = '+9647501234567',
  String payerName = '',
  String payerPhone = '',
  String note = 'dinner',
}) =>
    MoneyRequest(
      id: 'request-$code',
      code: code,
      role: role,
      open: open,
      amount: amount,
      status: status,
      expiresAt: DateTime(2026, 10, 19, 14, 30),
      createdAt: DateTime(2026, 10, 16, 14, 30),
      requesterName: requesterName,
      requesterPhone: requesterPhone,
      payerName: payerName,
      payerPhone: payerPhone,
      note: note,
    );

/// Money requests: [requests] are those the rider sees (any role); [riders] the
/// registered phones with their short names, [self] the rider's own phone. Paying
/// takes [pin]; [payFailure], when set, is the next payment's answer.
class FakeMoneyRequests implements MoneyRequestRepository {
  FakeMoneyRequests({
    List<MoneyRequest>? requests,
    Map<String, String>? riders,
    this.self = '+9647500000000',
    this.pin = '2580',
    this.payFailure,
    this.createFailure,
  })  : requests = requests ?? [],
        riders = riders ?? {'+9647501234567': 'Haidar K.'};

  final List<MoneyRequest> requests;
  Map<String, String> riders;
  String self;
  String pin;
  Failure? payFailure;
  Failure? createFailure;
  final List<({String? phone, int amount, String note, String key})> created = [];
  final List<(String, String)> paid = [];
  final List<String> declined = [];
  final List<String> cancelled = [];

  int _index(String code) => requests.indexWhere((r) => r.code == code);

  @override
  Future<Result<MoneyRequest>> create({PhoneNumber? payer, required int amount, required String note, required String key}) async {
    created.add((phone: payer?.e164, amount: amount, note: note, key: key));

    final failure = createFailure;
    if (failure != null) {
      return Err(failure);
    }

    if (payer != null && payer.e164 == self) {
      return const Err(InvalidInputFailure());
    }

    final name = payer == null ? '' : riders[payer.e164];

    if (name == null) {
      return const Err(NotFoundFailure());
    }

    final request = requestOf(
      code: 'NEWRQ${created.length + 1}ABCD',
      role: MoneyRequestRole.requester,
      open: payer == null,
      amount: amount,
      note: note,
      requesterName: 'Me',
      requesterPhone: self,
      payerName: name,
      payerPhone: payer?.e164 ?? '',
    );
    requests.insert(0, request);

    return Ok(request);
  }

  @override
  Future<Result<List<MoneyRequest>>> list(MoneyRequestSide side, {MoneyRequestStatus? status}) async => Ok([
        for (final r in requests)
          if ((side == MoneyRequestSide.outgoing) == (r.role == MoneyRequestRole.requester) &&
              (status == null || r.status == status))
            r,
      ]);

  @override
  Future<Result<MoneyRequest>> byCode(String code) async {
    final i = _index(code);

    return i < 0 ? const Err(NotFoundFailure()) : Ok(requests[i]);
  }

  @override
  Future<Result<PaidRequest>> pay(String code, String pin) async {
    paid.add((code, pin));

    final failure = payFailure;
    if (failure != null) {
      payFailure = null;

      return Err(failure);
    }

    if (pin != this.pin) {
      return const Err(ForbiddenFailure());
    }

    final i = _index(code);
    if (i < 0) {
      return const Err(NotFoundFailure());
    }

    final request = requests[i].copyWith(status: MoneyRequestStatus.paid, closedAt: DateTime(2026, 10, 16, 15));
    requests[i] = request;

    return Ok(PaidRequest(
      request: request,
      transferId: 'f3a9c2d1-0000-4000-8000-000000000002',
      at: DateTime(2026, 10, 16, 15),
      balance: 12500 - request.amount,
    ));
  }

  Result<MoneyRequest> _close(String code, MoneyRequestStatus status) {
    final i = _index(code);
    if (i < 0) {
      return const Err(NotFoundFailure());
    }

    requests[i] = requests[i].copyWith(status: status, closedAt: DateTime(2026, 10, 16, 15));

    return Ok(requests[i]);
  }

  @override
  Future<Result<MoneyRequest>> decline(String code) async {
    declined.add(code);

    return _close(code, MoneyRequestStatus.declined);
  }

  @override
  Future<Result<MoneyRequest>> cancel(String code) async {
    cancelled.add(code);

    return _close(code, MoneyRequestStatus.cancelled);
  }
}
