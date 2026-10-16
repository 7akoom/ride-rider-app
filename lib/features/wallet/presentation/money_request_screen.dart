import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/format/bidi.dart';
import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/money_request.dart';
import '../domain/entities/transfer.dart';
import 'money_request_controller.dart';
import 'pin_confirm.dart';
import 'request_widgets.dart';

/// Opens a request by its code (a row, "pay with a code", later a QR code).
Future<void> openMoneyRequest(BuildContext context, String code) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MoneyRequestScreen(code: code)),
    );

/// One request: who asks whom for what, and what the rider may do with it: pay it
/// (the PIN), decline it, cancel it, or share it (an open one of theirs).
class MoneyRequestScreen extends ConsumerWidget {
  const MoneyRequestScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(moneyRequestControllerProvider(code));
    final controller = ref.read(moneyRequestControllerProvider(code).notifier);
    final request = view.request;
    final paid = view.paid;

    final Widget body;

    if (paid != null) {
      body = _PaidView(paid: paid);
    } else if (request != null) {
      body = _RequestView(view: view, request: request, code: code);
    } else if (view.failure case final Failure failure) {
      body = failure is NotFoundFailure
          ? EmptyState(icon: Icons.search_off, message: l10n.requestNotFound)
          : FailureView(failure: failure, onRetry: () => unawaited(controller.load()));
    } else {
      body = const SkeletonList(rows: 4);
    }

    return AppScaffold(
      topBar: AppTopBar(title: l10n.requestDetailTitle, showBack: paid == null ? null : false),
      body: body,
    );
  }
}

class _RequestView extends ConsumerWidget {
  const _RequestView({required this.view, required this.request, required this.code});

  final RequestView view;
  final MoneyRequest request;
  final String code;

  String _amountProblem(AppLocalizations l10n, TransferAmountProblem problem, TransferOptions options) =>
      switch (problem) {
        TransferAmountProblem.tooSmall => l10n.requestOutsideLimits,
        TransferAmountProblem.tooBig => l10n.requestOutsideLimits,
        TransferAmountProblem.overToday => l10n.sendOverToday(formatMoney(l10n, options.leftToday)),
        TransferAmountProblem.tooManyToday => l10n.sendTooManyToday,
        TransferAmountProblem.overBalance => l10n.sendOverBalance,
      };

  Future<void> _pay(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(moneyRequestControllerProvider(code).notifier);

    return confirmWithPin(
      context,
      ref,
      detail: l10n.requestPinDetail(formatMoney(l10n, request.amount), counterpartName(l10n, request)),
      needsPin: l10n.requestNeedsPin,
      submit: controller.confirm,
    );
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await confirmSheet(
      context,
      title: l10n.requestDeclineTitle,
      message: l10n.requestDeclineBody(counterpartName(l10n, request)),
      confirmLabel: l10n.requestDecline,
      keepLabel: l10n.requestKeep,
    );

    if (confirmed) {
      await ref.read(moneyRequestControllerProvider(code).notifier).decline();
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await confirmSheet(
      context,
      title: l10n.requestCancelTitle,
      message: l10n.requestCancelBody,
      confirmLabel: l10n.requestCancel,
      keepLabel: l10n.requestKeep,
    );

    if (confirmed) {
      await ref.read(moneyRequestControllerProvider(code).notifier).cancel();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final options = view.options;
    final balance = view.balance;
    final amount = formatMoney(l10n, request.amount);
    final mine = request.role == MoneyRequestRole.requester;

    final String? problem = switch (view.problem) {
      PayAmountProblem(problem: final amountProblem) when options != null =>
        _amountProblem(l10n, amountProblem, options),
      PayOutsideLimits() => l10n.requestOutsideLimits,
      PayFailed(:final failure) => failure is PreconditionFailure ? l10n.requestNotPaid : failure.message(l10n),
      _ => switch (view.amountProblem) {
          final TransferAmountProblem amountProblem when options != null =>
            _amountProblem(l10n, amountProblem, options),
          _ => null,
        },
    };
    final closeFailure = view.closeFailure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x2),
            children: [
              // An open request of the rider's has no one on the other side yet.
              if (!(mine && request.open && request.payerName.isEmpty)) ...[
                RequestPersonCard(name: counterpartName(l10n, request), phone: counterpartPhone(request)),
                const SizedBox(height: Space.x4),
              ],
              Text(
                requestHeadline(l10n, request),
                textAlign: TextAlign.center,
                style: context.typo.body.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Space.x1),
              Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(amount, style: context.typo.display)),
              ),
              const SizedBox(height: Space.x2),
              Center(child: RequestStatusPill(status: request.status)),
              const SizedBox(height: Space.x4),
              if (request.note.isNotEmpty) RequestLine(label: l10n.sendReceiptNote, value: request.note),
              RequestLine(label: l10n.sendReceiptTime, value: requestTime(l10n, request.createdAt)),
              RequestLine(
                label: l10n.requestCode,
                value: isolateLtr(request.displayCode),
              ),
              if (requestWhen(l10n, request) case final String ends)
                Text(ends, style: context.typo.caption.copyWith(color: p.textSecondary)),
              if (mine && request.status == MoneyRequestStatus.paid && request.payerName.isNotEmpty) ...[
                const SizedBox(height: Space.x2),
                StatusBanner(tone: Tone.success, message: l10n.requestPaidBy(request.payerName)),
              ],
              if (mine && request.open && request.pending) ...[
                const SizedBox(height: Space.x4),
                RequestQrCard(request: request),
              ],
              if (request.payable) ...[
                const SizedBox(height: Space.x4),
                if (balance != null)
                  Text(
                    l10n.sendAvailable(formatMoney(l10n, balance)),
                    textAlign: TextAlign.center,
                    style: context.typo.caption.copyWith(color: p.textSecondary),
                  ),
                if (problem != null) ...[
                  const SizedBox(height: Space.x2),
                  StatusBanner(tone: Tone.danger, message: problem),
                ],
              ],
              if (closeFailure != null) ...[
                const SizedBox(height: Space.x2),
                StatusBanner(tone: Tone.danger, message: closeFailure.message(l10n)),
              ],
            ],
          ),
        ),
        if (request.payable) ...[
          const SizedBox(height: Space.x3),
          AppButton(
            label: l10n.requestPay(amount),
            icon: Icons.north_east,
            onPressed: view.canPay ? () => unawaited(_pay(context, ref)) : null,
          ),
          if (request.declinable) ...[
            const SizedBox(height: Space.x2),
            AppButton(
              label: l10n.requestDecline,
              variant: AppButtonVariant.text,
              loading: view.closing,
              onPressed: view.closing ? null : () => unawaited(_decline(context, ref)),
            ),
          ],
          const SizedBox(height: Space.x2),
        ],
        if (request.cancellable) ...[
          const SizedBox(height: Space.x3),
          AppButton(
            label: l10n.requestCancel,
            variant: AppButtonVariant.danger,
            loading: view.closing,
            onPressed: view.closing ? null : () => unawaited(_cancel(context, ref)),
          ),
          const SizedBox(height: Space.x4),
        ],
      ],
    );
  }
}

/// The request was paid, here, just now.
class _PaidView extends StatelessWidget {
  const _PaidView({required this.paid});

  final PaidRequest paid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final request = paid.request;
    final balance = paid.balance;
    final name = counterpartName(l10n, request);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x6),
            children: [
              Center(
                child: Container(
                  width: Sizes.hero,
                  height: Sizes.hero,
                  decoration: BoxDecoration(color: p.successSoft, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: Sizes.heroIcon, color: p.success),
                ),
              ),
              const SizedBox(height: Space.x6),
              Semantics(
                header: true,
                child: Text(
                  l10n.requestPaidTitle(formatMoney(l10n, request.amount), name),
                  textAlign: TextAlign.center,
                  style: context.typo.h2,
                ),
              ),
              const SizedBox(height: Space.x2),
              Text(
                l10n.sendDoneBody,
                textAlign: TextAlign.center,
                style: context.typo.body.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Space.x6),
              RequestPersonCard(name: name, phone: counterpartPhone(request)),
              const SizedBox(height: Space.x3),
              RequestLine(label: l10n.sendReceiptId, value: isolateLtr(paid.transferId.split('-').first.toUpperCase())),
              RequestLine(label: l10n.sendReceiptTime, value: requestTime(l10n, paid.at)),
              if (request.note.isNotEmpty) RequestLine(label: l10n.sendReceiptNote, value: request.note),
              if (balance != null) RequestLine(label: l10n.sendNewBalance, value: formatMoney(l10n, balance)),
            ],
          ),
        ),
        AppButton(label: l10n.sendDone, onPressed: () => Navigator.of(context).pop()),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}
