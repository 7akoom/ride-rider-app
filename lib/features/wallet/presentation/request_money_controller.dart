import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/security/random_key.dart';
import '../domain/entities/money_request.dart';
import '../domain/entities/transfer.dart';
import '../wallet_providers.dart';
import 'wallet_state.dart';

enum RequestStep { amount, who, done }

/// Whom the money is asked of: one rider (by phone), or whoever opens the code.
enum RequestKind { person, open }

const Object _same = Object();

final class RequestFlow {
  const RequestFlow({
    this.step = RequestStep.amount,
    this.loading = true,
    this.loadFailure,
    this.options,
    this.amount = 0,
    this.note = '',
    this.kind = RequestKind.person,
    this.phone,
    this.recipient,
    this.lookingUp = false,
    this.lookupFailure,
    this.creating = false,
    this.createFailure,
    this.created,
  });

  final RequestStep step;

  /// The transfer limits are being read: what may be asked is what may be sent.
  final bool loading;
  final Failure? loadFailure;
  final TransferOptions? options;

  /// Whole currency units; 0 before one is picked.
  final int amount;
  final String note;
  final RequestKind kind;

  /// The phone typed, once it is a whole number.
  final PhoneNumber? phone;
  final Recipient? recipient;
  final bool lookingUp;
  final Failure? lookupFailure;
  final bool creating;
  final Failure? createFailure;
  final MoneyRequest? created;

  /// Too small or too big for a transfer; null when it may be asked (or unknown yet).
  TransferAmountProblem? get amountProblem {
    final options = this.options;

    if (options == null || amount == 0) {
      return null;
    }

    if (amount < options.min) {
      return TransferAmountProblem.tooSmall;
    }

    return amount > options.max ? TransferAmountProblem.tooBig : null;
  }

  bool get amountReady => options != null && amount > 0 && amountProblem == null;

  bool get canCreate =>
      amountReady && !creating && (kind == RequestKind.open || recipient?.result == RecipientResult.found);

  RequestFlow copyWith({
    RequestStep? step,
    bool? loading,
    Object? loadFailure = _same,
    Object? options = _same,
    int? amount,
    String? note,
    RequestKind? kind,
    Object? phone = _same,
    Object? recipient = _same,
    bool? lookingUp,
    Object? lookupFailure = _same,
    bool? creating,
    Object? createFailure = _same,
    Object? created = _same,
  }) =>
      RequestFlow(
        step: step ?? this.step,
        loading: loading ?? this.loading,
        loadFailure: identical(loadFailure, _same) ? this.loadFailure : loadFailure as Failure?,
        options: identical(options, _same) ? this.options : options as TransferOptions?,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        kind: kind ?? this.kind,
        phone: identical(phone, _same) ? this.phone : phone as PhoneNumber?,
        recipient: identical(recipient, _same) ? this.recipient : recipient as Recipient?,
        lookingUp: lookingUp ?? this.lookingUp,
        lookupFailure: identical(lookupFailure, _same) ? this.lookupFailure : lookupFailure as Failure?,
        creating: creating ?? this.creating,
        createFailure: identical(createFailure, _same) ? this.createFailure : createFailure as Failure?,
        created: identical(created, _same) ? this.created : created as MoneyRequest?,
      );
}

final requestMoneyControllerProvider =
    NotifierProvider.autoDispose<RequestMoneyController, RequestFlow>(RequestMoneyController.new);

/// 37: the amount (within the transfer limits) and a note, then whom to ask: a
/// rider by phone (looked up as it is typed, so the rider sees whom) or an open
/// request with a QR code and a code to share.
class RequestMoneyController extends AutoDisposeNotifier<RequestFlow> {
  bool _disposed = false;

  /// One key per request: a retry (after no answer) is the same request.
  String? _key;

  @override
  RequestFlow build() {
    ref.onDispose(() => _disposed = true);
    unawaited(Future.microtask(load));

    return const RequestFlow();
  }

  Future<void> load() async {
    if (_disposed) {
      return;
    }

    state = state.copyWith(loading: true, loadFailure: null);
    final options = await ref.read(loadTransferOptionsProvider).call();

    if (_disposed) {
      return;
    }

    state = switch (options) {
      Ok(:final value) => state.copyWith(loading: false, options: value),
      Err(:final failure) => state.copyWith(loading: false, loadFailure: failure),
    };
  }

  void setAmount(int amount) {
    _key = null;
    state = state.copyWith(amount: amount, createFailure: null);
  }

  void noteChanged(String note) {
    _key = null;
    state = state.copyWith(note: note);
  }

  void toWho() {
    if (state.amountReady) {
      state = state.copyWith(step: RequestStep.who, createFailure: null);
    }
  }

  /// One step back (the system back button).
  void back() {
    state = state.copyWith(step: RequestStep.amount, createFailure: null);
  }

  void chooseKind(RequestKind kind) {
    _key = null;
    state = state.copyWith(kind: kind, createFailure: null);
  }

  /// The phone field changed: a whole number is looked up once.
  void phoneTyped(String typed) {
    final phone = PhoneNumber.tryParse(typed);

    if (phone == state.phone) {
      return;
    }

    _key = null;
    state = state.copyWith(
      phone: phone,
      recipient: null,
      lookupFailure: null,
      lookingUp: phone != null,
      createFailure: null,
    );

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

  void retryLookup() {
    final phone = state.phone;

    if (phone != null && !state.lookingUp) {
      state = state.copyWith(lookingUp: true, lookupFailure: null);
      unawaited(_lookup(phone));
    }
  }

  Future<void> create() async {
    if (!state.canCreate) {
      return;
    }

    final payer = state.kind == RequestKind.person ? state.phone : null;
    final key = _key ??= randomKey();
    state = state.copyWith(creating: true, createFailure: null);

    final result = await ref.read(requestMoneyProvider).call(
          payer: payer,
          amount: state.amount,
          note: state.note,
          key: key,
        );

    if (_disposed) {
      return;
    }

    switch (result) {
      case Ok(:final value):
        _key = null;
        state = state.copyWith(creating: false, step: RequestStep.done, created: value);
        ref.invalidate(moneyRequestsProvider(MoneyRequestSide.outgoing));

      // The phone is no rider's any more: the rider picks again.
      case Err(failure: NotFoundFailure() && final failure):
        state = state.copyWith(creating: false, recipient: null, createFailure: failure);

      case Err(:final failure):
        state = state.copyWith(creating: false, createFailure: failure);
    }
  }
}
