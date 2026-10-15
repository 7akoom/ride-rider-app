import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/security/random_key.dart';
import '../domain/entities/transfer.dart';
import '../domain/entities/wallet_pin.dart';
import '../wallet_providers.dart';
import 'pin_sheet.dart';
import 'wallet_pin_controller.dart';
import 'wallet_state.dart';

enum SendStep { recipient, amount, review, done }

/// Why the money did not go, said on the amount step after the PIN sheet closed.
sealed class SendProblem {
  const SendProblem();
}

/// The amount no longer fits (the balance or a limit changed meanwhile).
final class SendAmountProblem extends SendProblem {
  const SendAmountProblem(this.problem);

  final TransferAmountProblem problem;
}

/// The phone is no rider's any more.
final class SendRecipientGone extends SendProblem {
  const SendRecipientGone();
}

final class SendFailed extends SendProblem {
  const SendFailed(this.failure);

  final Failure failure;
}

const Object _same = Object();

final class SendFlow {
  const SendFlow({
    this.step = SendStep.recipient,
    this.loading = true,
    this.loadFailure,
    this.options,
    this.balance,
    this.recent = const [],
    this.phone,
    this.recipient,
    this.lookingUp = false,
    this.lookupFailure,
    this.amount = 0,
    this.note = '',
    this.problem,
    this.sent,
  });

  final SendStep step;

  /// The limits and the balance are being read.
  final bool loading;
  final Failure? loadFailure;
  final TransferOptions? options;
  final int? balance;

  /// Phones the rider sent to lately.
  final List<PhoneNumber> recent;

  /// The phone typed, once it is a whole number.
  final PhoneNumber? phone;

  /// What the lookup said about [phone].
  final Recipient? recipient;
  final bool lookingUp;
  final Failure? lookupFailure;

  /// Whole currency units; 0 before a digit.
  final int amount;
  final String note;
  final SendProblem? problem;
  final SentMoney? sent;

  /// The amount's problem against the limits and the balance; null when it can go
  /// (or they are not known yet).
  TransferAmountProblem? get amountProblem {
    final options = this.options;
    final balance = this.balance;

    if (options == null || balance == null || amount == 0) {
      return null;
    }

    return options.problemOf(amount, balance: balance);
  }

  bool get canContinue => recipient?.result == RecipientResult.found;

  bool get canSend =>
      canContinue && options != null && balance != null && amount > 0 && amountProblem == null;

  SendFlow copyWith({
    SendStep? step,
    bool? loading,
    Object? loadFailure = _same,
    Object? options = _same,
    Object? balance = _same,
    List<PhoneNumber>? recent,
    Object? phone = _same,
    Object? recipient = _same,
    bool? lookingUp,
    Object? lookupFailure = _same,
    int? amount,
    String? note,
    Object? problem = _same,
    Object? sent = _same,
  }) =>
      SendFlow(
        step: step ?? this.step,
        loading: loading ?? this.loading,
        loadFailure: identical(loadFailure, _same) ? this.loadFailure : loadFailure as Failure?,
        options: identical(options, _same) ? this.options : options as TransferOptions?,
        balance: identical(balance, _same) ? this.balance : balance as int?,
        recent: recent ?? this.recent,
        phone: identical(phone, _same) ? this.phone : phone as PhoneNumber?,
        recipient: identical(recipient, _same) ? this.recipient : recipient as Recipient?,
        lookingUp: lookingUp ?? this.lookingUp,
        lookupFailure: identical(lookupFailure, _same) ? this.lookupFailure : lookupFailure as Failure?,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        problem: identical(problem, _same) ? this.problem : problem as SendProblem?,
        sent: identical(sent, _same) ? this.sent : sent as SentMoney?,
      );
}

final sendMoneyControllerProvider = NotifierProvider.autoDispose<SendMoneyController, SendFlow>(SendMoneyController.new);

/// 33–36: the recipient (looked up as it is typed), the amount within the limits and
/// the balance, the PIN, then the receipt.
class SendMoneyController extends AutoDisposeNotifier<SendFlow> {
  bool _disposed = false;

  /// One key per transfer: a retry (after no answer) is the same transfer.
  String? _key;

  @override
  SendFlow build() {
    ref.onDispose(() => _disposed = true);
    unawaited(Future.microtask(load));

    return const SendFlow();
  }

  /// Reads the limits, the balance and the recent recipients.
  Future<void> load() async {
    if (_disposed) {
      return;
    }

    state = state.copyWith(loading: true, loadFailure: null);
    final (options, wallet, recent) = await (
      ref.read(loadTransferOptionsProvider).call(),
      ref.read(loadWalletProvider).call(),
      ref.read(loadRecentRecipientsProvider).call(),
    ).wait;

    if (_disposed) {
      return;
    }

    final failure = switch ((options, wallet)) {
      (Err(:final failure), _) || (_, Err(:final failure)) => failure,
      _ => null,
    };

    state = state.copyWith(
      loading: false,
      loadFailure: failure,
      options: options is Ok<TransferOptions> ? options.value : state.options,
      balance: switch (wallet) {
        Ok(value: (final overview, _)) => overview.balance,
        _ => state.balance,
      },
      recent: recent is Ok<List<PhoneNumber>> ? recent.value : state.recent,
    );
  }

  /// The phone field changed: a whole number is looked up once.
  void phoneTyped(String typed) {
    final phone = PhoneNumber.tryParse(typed);

    if (phone == state.phone) {
      return;
    }

    _key = null;
    state = state.copyWith(phone: phone, recipient: null, lookupFailure: null, lookingUp: phone != null, problem: null);

    if (phone != null) {
      unawaited(_lookup(phone));
    }
  }

  Future<void> _lookup(PhoneNumber phone) async {
    final result = await ref.read(lookupRecipientProvider).call(phone);

    // The rider typed another number meanwhile: this answer is not about it.
    if (_disposed || state.phone != phone) {
      return;
    }

    state = switch (result) {
      Ok(:final value) => state.copyWith(lookingUp: false, recipient: value),
      Err(:final failure) => state.copyWith(lookingUp: false, lookupFailure: failure),
    };
  }

  /// Looks the phone up again (after a failure).
  void retryLookup() {
    final phone = state.phone;

    if (phone != null && !state.lookingUp) {
      state = state.copyWith(lookingUp: true, lookupFailure: null);
      unawaited(_lookup(phone));
    }
  }

  void toAmount() {
    if (state.canContinue) {
      state = state.copyWith(step: SendStep.amount, problem: null);
    }
  }

  void toRecipient() {
    state = state.copyWith(step: SendStep.recipient, problem: null);
  }

  /// The amount is fine: the rider reviews the transfer before the PIN.
  void toReview() {
    if (state.canSend) {
      state = state.copyWith(step: SendStep.review, problem: null);
    }
  }

  /// One step back (the system back button).
  void back() {
    state = switch (state.step) {
      SendStep.review => state.copyWith(step: SendStep.amount),
      _ => state.copyWith(step: SendStep.recipient, problem: null),
    };
  }

  void setAmount(int amount) {
    _key = null;
    state = state.copyWith(amount: amount, problem: null);
  }

  void noteChanged(String note) {
    _key = null;
    state = state.copyWith(note: note);
  }

  /// Sends with [pin]; what the PIN sheet does next.
  Future<PinSheetOutcome> confirm(String pin) async {
    final phone = state.phone;

    if (!state.canSend || phone == null) {
      return const PinSheetClosed();
    }

    final key = _key ??= randomKey();
    final result = await ref.read(sendMoneyProvider).call(
          phone: phone,
          amount: state.amount,
          note: state.note,
          pin: pin,
          key: key,
        );

    if (_disposed) {
      return const PinSheetClosed();
    }

    switch (result) {
      case Ok(:final value):
        _key = null;
        state = state.copyWith(step: SendStep.done, sent: value, balance: value.balance ?? state.balance);
        // The wallet screen and the home screen's balance load again.
        ref.invalidate(walletProvider);

        return const PinAccepted();

      // A wrong PIN (PermissionDenied).
      case Err(failure: ForbiddenFailure()):
        return _refused(wrongPin: true);

      // A locked PIN, the limits or the balance (FailedPrecondition).
      case Err(failure: PreconditionFailure()):
        return _refused(wrongPin: false);

      case Err(failure: NotFoundFailure()):
        state = state.copyWith(step: SendStep.recipient, recipient: null, problem: const SendRecipientGone());

        return const PinSheetClosed();

      case Err(failure: InvalidInputFailure() && final failure):
        state = state.copyWith(step: SendStep.amount, problem: SendFailed(failure));

        return const PinSheetClosed();

      case Err(:final failure):
        // No answer: nothing or the whole transfer went; the same key again settles
        // which, so the rider types the PIN again.
        return PinRefused(PinFailed(failure));
    }
  }

  /// A refusal the server does not explain in detail: the PIN's status and the
  /// wallet as they are now say why (a wrong or locked PIN, or the amount no longer
  /// fits after the balance or the day's transfers changed).
  Future<PinSheetOutcome> _refused({required bool wrongPin}) async {
    ref.invalidate(pinStatusProvider);
    final status = await ref.read(loadPinStatusProvider).call();

    if (_disposed) {
      return const PinSheetClosed();
    }

    switch (status) {
      case Ok(value: final PinStatus pin) when pin.lockedAt(DateTime.now()):
        return PinRefused(PinLocked(pin.lockedUntil!));
      case Ok(value: final PinStatus pin) when wrongPin:
        return PinRefused(WrongCurrentPin(pin.attemptsLeft));
      case Err(:final failure) when wrongPin:
        return PinRefused(PinFailed(failure));
      case _:
        break;
    }

    await load();

    if (_disposed) {
      return const PinSheetClosed();
    }

    state = state.copyWith(
      step: SendStep.amount,
      problem: switch (state.amountProblem) {
        final TransferAmountProblem problem => SendAmountProblem(problem),
        null => const SendFailed(PreconditionFailure()),
      },
    );

    return const PinSheetClosed();
  }
}
