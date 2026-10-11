import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/entities/statement.dart';
import '../domain/entities/wallet_movement.dart';
import '../domain/use_cases/follow_wallet.dart';
import '../wallet_providers.dart';

typedef StatementQuery = (StatementPeriod, MovementFilter);

final statementControllerProvider =
    NotifierProvider.autoDispose.family<StatementController, StatementState, StatementQuery>(
  StatementController.new,
);

final class StatementState {
  const StatementState({this.first, this.movements = const [], this.next, this.loading = true, this.failure});

  /// The first page: the period's totals come with it.
  final StatementPage? first;
  final List<WalletMovement> movements;
  final String? next;
  final bool loading;
  final Failure? failure;

  bool get hasMore => next != null;
}

/// The wallet's history over a period, a page at a time as the rider scrolls.
class StatementController extends AutoDisposeFamilyNotifier<StatementState, StatementQuery> {
  /// The period ends when the screen opened, so the pages stay the same list.
  final DateTime _now = DateTime.now();
  bool _busy = false;

  @override
  StatementState build(StatementQuery arg) {
    unawaited(Future.microtask(_load));

    return const StatementState();
  }

  Future<void> _load([String? page]) async {
    if (_busy) {
      return;
    }

    _busy = true;
    final (period, filter) = arg;
    final result = await ref.read(loadStatementProvider).call(
          period: period,
          now: _now,
          filter: filter,
          page: page,
        );
    _busy = false;

    state = switch (result) {
      Ok(:final value) => StatementState(
          first: state.first ?? value,
          movements: [...state.movements, ...value.movements],
          next: value.next,
          loading: false,
        ),
      Err(:final failure) => StatementState(
          first: state.first,
          movements: state.movements,
          next: state.next,
          loading: false,
          failure: failure,
        ),
    };
  }

  /// The next page, when there is one.
  void more() {
    if (state.hasMore && state.failure == null) {
      unawaited(_load(state.next));
    }
  }

  /// After a failure: the page that failed again.
  void retry() {
    state = StatementState(first: state.first, movements: state.movements, next: state.next);
    unawaited(_load(state.next));
  }
}
