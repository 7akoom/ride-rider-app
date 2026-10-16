import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/entities/money_request.dart';
import '../domain/entities/transfer.dart';
import '../domain/entities/wallet_pin.dart';
import '../wallet_providers.dart';
import 'pin_sheet.dart';
import 'wallet_pin_controller.dart';
import 'wallet_state.dart';

/// Why a payment did not go, said on the request after the PIN sheet closed.
sealed class PayProblem {
  const PayProblem();
}

/// The amount does not fit now (the balance, the day's transfers).
final class PayAmountProblem extends PayProblem {
  const PayAmountProblem(this.problem);

  final TransferAmountProblem problem;
}

/// The transfer limits changed since it was asked: it cannot be paid now.
final class PayOutsideLimits extends PayProblem {
  const PayOutsideLimits();
}

final class PayFailed extends PayProblem {
  const PayFailed(this.failure);

  final Failure failure;
}

const Object _same = Object();

final class RequestView {
  const RequestView({
    this.loading = true,
    this.failure,
    this.request,
    this.options,
    this.balance,
    this.closing = false,
    this.closeFailure,
    this.paid,
    this.problem,
  });

  final bool loading;

  /// The request could not be read (NotFoundFailure: no request the rider may see).
  final Failure? failure;
  final MoneyRequest? request;

  /// For paying: the transfer limits and the balance.
  final TransferOptions? options;
  final int? balance;

  /// Declining or cancelling.
  final bool closing;
  final Failure? closeFailure;

  /// Paid just now, here.
  final PaidRequest? paid;
  final PayProblem? problem;

  /// What is wrong with paying it now (the limits and the balance); null when it can
  /// be paid (or they are not known yet).
  TransferAmountProblem? get amountProblem {
    final request = this.request;
    final options = this.options;
    final balance = this.balance;

    if (request == null || options == null || balance == null) {
      return null;
    }

    return options.problemOf(request.amount, balance: balance);
  }

  bool get canPay =>
      (request?.payable ?? false) && options != null && balance != null && amountProblem == null && !closing;

  RequestView copyWith({
    bool? loading,
    Object? failure = _same,
    Object? request = _same,
    Object? options = _same,
    Object? balance = _same,
    bool? closing,
    Object? closeFailure = _same,
    Object? paid = _same,
    Object? problem = _same,
  }) =>
      RequestView(
        loading: loading ?? this.loading,
        failure: identical(failure, _same) ? this.failure : failure as Failure?,
        request: identical(request, _same) ? this.request : request as MoneyRequest?,
        options: identical(options, _same) ? this.options : options as TransferOptions?,
        balance: identical(balance, _same) ? this.balance : balance as int?,
        closing: closing ?? this.closing,
        closeFailure: identical(closeFailure, _same) ? this.closeFailure : closeFailure as Failure?,
        paid: identical(paid, _same) ? this.paid : paid as PaidRequest?,
        problem: identical(problem, _same) ? this.problem : problem as PayProblem?,
      );
}

final moneyRequestControllerProvider =
    NotifierProvider.autoDispose.family<MoneyRequestController, RequestView, String>(MoneyRequestController.new);

/// One request, opened by its code: paid with the PIN (after a look at who asks and
/// what), declined by the rider it is for, or cancelled by the requester.
class MoneyRequestController extends AutoDisposeFamilyNotifier<RequestView, String> {
  bool _disposed = false;

  @override
  RequestView build(String arg) {
    ref.onDispose(() => _disposed = true);
    unawaited(Future.microtask(load));

    return const RequestView();
  }

  /// Reads the request, and for one the rider may pay the limits and the balance.
  Future<void> load() async {
    if (_disposed) {
      return;
    }

    state = state.copyWith(loading: true, failure: null);
    final result = await ref.read(openMoneyRequestProvider).call(arg);

    if (_disposed) {
      return;
    }

    switch (result) {
      case Err(:final failure):
        state = state.copyWith(loading: false, failure: failure);

        return;
      case Ok(value: final request):
        state = state.copyWith(loading: false, request: request);

        if (request.payable) {
          await _loadPaying();
        }
    }
  }

  Future<void> _loadPaying() async {
    final (options, wallet) = await (
      ref.read(loadTransferOptionsProvider).call(),
      ref.read(loadWalletProvider).call(),
    ).wait;

    if (_disposed) {
      return;
    }

    final failure = switch ((options, wallet)) {
      (Err(:final failure), _) || (_, Err(:final failure)) => failure,
      _ => null,
    };

    state = state.copyWith(
      options: options is Ok<TransferOptions> ? options.value : state.options,
      balance: switch (wallet) {
        Ok(value: (final overview, _)) => overview.balance,
        _ => state.balance,
      },
      problem: failure == null ? state.problem : PayFailed(failure),
    );
  }

  void _changed() {
    ref.invalidate(incomingRequestsProvider);
    ref.invalidate(moneyRequestsProvider(MoneyRequestSide.incoming));
    ref.invalidate(moneyRequestsProvider(MoneyRequestSide.outgoing));
  }

  /// Pays with [pin]; what the PIN sheet does next.
  Future<PinSheetOutcome> confirm(String pin) async {
    final request = state.request;

    if (request == null || !state.canPay) {
      return const PinSheetClosed();
    }

    final result = await ref.read(payMoneyRequestProvider).call(request.code, pin);

    if (_disposed) {
      return const PinSheetClosed();
    }

    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          request: value.request,
          paid: value,
          balance: value.balance ?? state.balance,
          problem: null,
        );
        // The wallet's balance and its requests load again.
        ref.invalidate(walletProvider);
        _changed();

        return const PinAccepted();

      // A wrong PIN (PermissionDenied).
      case Err(failure: ForbiddenFailure()):
        return _refused(wrongPin: true);

      // A locked PIN, the limits, the balance, or the request no longer pending.
      case Err(failure: PreconditionFailure()):
        return _refused(wrongPin: false);

      // The limits changed since it was asked.
      case Err(failure: InvalidInputFailure()):
        state = state.copyWith(problem: const PayOutsideLimits());

        return const PinSheetClosed();

      case Err(failure: NotFoundFailure() && final failure):
        state = state.copyWith(failure: failure, request: null);

        return const PinSheetClosed();

      case Err(:final failure):
        // No answer: nothing or the payment went; paying again settles which (the
        // server returns a payment already made), so the rider types the PIN again.
        return PinRefused(PinFailed(failure));
    }
  }

  /// A refusal the server does not explain in detail: the PIN's status, the request
  /// and the wallet as they are now say why.
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

    // Paid by someone else meanwhile, declined, cancelled or expired: the request
    // says so. Otherwise the amount no longer fits.
    await load();

    if (_disposed) {
      return const PinSheetClosed();
    }

    if (state.request?.payable ?? false) {
      state = state.copyWith(
        problem: switch (state.amountProblem) {
          final TransferAmountProblem problem => PayAmountProblem(problem),
          null => const PayFailed(PreconditionFailure()),
        },
      );
    } else {
      _changed();
    }

    return const PinSheetClosed();
  }

  /// The rider it is for says no.
  Future<bool> decline() => _close(ref.read(declineMoneyRequestProvider).call);

  /// The requester takes it back.
  Future<bool> cancel() => _close(ref.read(cancelMoneyRequestProvider).call);

  Future<bool> _close(Future<Result<MoneyRequest>> Function(String code) close) async {
    final request = state.request;

    if (request == null || state.closing) {
      return false;
    }

    state = state.copyWith(closing: true, closeFailure: null);
    final result = await close(request.code);

    if (_disposed) {
      return false;
    }

    switch (result) {
      case Ok(:final value):
        state = state.copyWith(closing: false, request: value);
        _changed();

        return true;

      // Paid, closed or expired meanwhile: the request as it is now says so.
      case Err(failure: PreconditionFailure()):
        state = state.copyWith(closing: false);
        await load();
        _changed();

        return false;

      case Err(:final failure):
        state = state.copyWith(closing: false, closeFailure: failure);

        return false;
    }
  }
}
