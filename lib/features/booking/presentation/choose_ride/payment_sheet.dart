import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../booking_providers.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/trip_draft.dart';
import 'choose_ride_controller.dart';
import 'coupon_section.dart';
import 'ride_texts.dart';

final _walletBalanceProvider = FutureProvider.autoDispose<Result<int>>(
  (ref) => ref.watch(loadWalletBalanceProvider).call(),
);

/// 12: how to pay, the coupon, and the price that results.
Future<void> showPaymentSheet(BuildContext context, TripDraft draft) => showAppSheet<void>(
      context: context,
      builder: (_) => SingleChildScrollView(child: PaymentSheet(draft: draft)),
    );

class PaymentSheet extends ConsumerWidget {
  const PaymentSheet({super.key, required this.draft});

  final TripDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(chooseRideControllerProvider(draft));
    final controller = ref.read(chooseRideControllerProvider(draft).notifier);
    final wallet = ref.watch(_walletBalanceProvider);
    final balance = switch (wallet) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };
    final selected = state.selected;
    final walletLow = state.payment == PaymentMethod.wallet &&
        balance != null &&
        selected != null &&
        balance < selected.total;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.paymentTitle, onClose: () => Navigator.of(context).pop()),
        for (final method in PaymentMethod.values) ...[
          AppRadioTile(
            title: RideTexts.payment(l10n, method),
            subtitle: switch (method) {
              PaymentMethod.cash => l10n.paymentCashDetail,
              PaymentMethod.wallet => wallet.isLoading ? null : _walletLine(l10n, balance),
            },
            leading: Icon(RideTexts.paymentIcon(method)),
            selected: state.payment == method,
            onTap: () => controller.choosePayment(method),
          ),
          const SizedBox(height: Space.x3),
        ],
        if (walletLow) StatusBanner(tone: Tone.warning, message: l10n.paymentWalletLow),
        const SizedBox(height: Space.x5),
        CouponSection(draft: draft),
        const SizedBox(height: Space.x5),
        if (selected != null)
          Row(
            children: [
              Expanded(child: Text(l10n.paymentTotal, style: context.typo.body)),
              if (selected.beforeDiscount != null) ...[
                MoneyText(selected.beforeDiscount!, tone: MoneyTone.struck),
                const SizedBox(width: Space.x2),
              ],
              MoneyText(selected.total),
            ],
          ),
        const SizedBox(height: Space.x4),
        AppButton(label: l10n.actionConfirm, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  static String _walletLine(AppLocalizations l10n, int? balance) => balance == null
      ? l10n.paymentWalletUnknown
      : l10n.paymentWalletBalance(formatMoney(l10n, balance));
}
