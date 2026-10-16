import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/format/money_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/biometric.dart';
import '../domain/entities/wallet_pin.dart';
import 'biometric_unlock.dart';
import 'balance_card.dart';
import 'movement_view.dart';
import 'movements_screen.dart';
import 'send_money_screen.dart';
import 'statement_screen.dart';
import 'top_up_screen.dart';
import 'voucher_sheet.dart';
import 'wallet_pin_screen.dart';
import 'wallet_state.dart';

Future<void> openWallet(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WalletScreen()));

/// 28: the balance, fees still owed, what adds to it, and the latest movements.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  /// How many actions fit in the row under the balance.
  static const int _actionPlaces = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final result = ref.watch(walletProvider);
    // Offered only where ZainCash is set up; vouchers always.
    final topUp = switch (ref.watch(topUpOptionsProvider)) {
      AsyncData(value: Ok(:final value)) when value.available => value,
      _ => null,
    };

    final owed = switch (result) {
      AsyncData(value: Ok(value: (final overview, _))) => overview.owed,
      _ => 0,
    };
    final tiles = [
      if (topUp != null)
        ShortcutTile(
          icon: Icons.add_card_outlined,
          label: l10n.walletTopUp,
          onTap: () => openTopUp(context, topUp),
        ),
      ShortcutTile(
        icon: Icons.north_east,
        label: l10n.walletSend,
        onTap: () => openSendMoney(context),
      ),
      ShortcutTile(
        icon: Icons.redeem_outlined,
        label: l10n.walletUseVoucher,
        onTap: () => showVoucherSheet(context, owed: owed),
      ),
    ];

    // The PIN row shows once its status is known; a failure leaves it out.
    final pin = switch (ref.watch(pinStatusProvider)) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };

    // Paying with a fingerprint or the face: offered once there is a PIN, on a phone
    // that has one set up.
    // Read with the last value while it loads again, so the row does not blink.
    final hasPin = switch (ref.watch(pinStatusProvider).valueOrNull) {
      Ok(:final value) => value.isSet,
      _ => false,
    };
    final biometric = switch (ref.watch(biometricProvider).valueOrNull) {
      final BiometricState value when value.available && hasPin => value,
      _ => null,
    };

    final body = switch (result) {
      AsyncData(value: Ok(value: (final overview, final recent))) => [
          BalanceCard(balance: overview.balance),
          if (overview.owed > 0) ...[
            const SizedBox(height: Space.x3),
            StatusBanner(
              tone: Tone.danger,
              message: overview.canRequestTrips
                  ? l10n.walletOwed(formatMoney(l10n, overview.owed))
                  : l10n.walletOwedBlocked(formatMoney(l10n, overview.owed)),
            ),
          ],
          const SizedBox(height: Space.x4),
          // Four equal places, as on Careem's wallet; "request money" takes the free
          // one (5d-3). A long label (Kurdish) shortens instead of overflowing.
          Row(
            children: [
              for (final tile in tiles) Expanded(child: tile),
              for (var free = tiles.length; free < _actionPlaces; free++) const Spacer(),
            ],
          ),
          const SizedBox(height: Space.x4),
          SectionHeader(
            title: l10n.walletRecent,
            actionLabel: recent.isEmpty ? null : l10n.walletAll,
            onAction: () => openMovements(context),
          ),
          if (recent.isEmpty) EmptyState(icon: Icons.receipt_long_outlined, message: l10n.walletEmpty),
          for (final movement in recent) MovementRow(movement: movement),
          const SizedBox(height: Space.x3),
          AppListRow(
            icon: Icons.summarize_outlined,
            title: l10n.statementTitle,
            onTap: () => openStatement(context),
          ),
          if (pin != null)
            AppListRow(
              icon: Icons.password_outlined,
              title: l10n.walletPinRow,
              subtitle: _pinSubtitle(l10n, pin),
              onTap: () => openWalletPin(context, pin),
            ),
          if (biometric != null)
            _BiometricRow(
              state: biometric,
              onChanged: (on) => unawaited(switchBiometric(context, ref, on: on, pin: pin)),
            ),
        ],
      AsyncData(value: Err(:final failure)) => [
          FailureView(failure: failure, onRetry: () => ref.invalidate(walletProvider)),
        ],
      _ => [
          const BalanceCard(balance: null),
          const SizedBox(height: Space.x4),
          const SkeletonList(rows: 4),
        ],
    };

    return AppScaffold(
      topBar: AppTopBar(title: l10n.walletTitle),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(topUpOptionsProvider);
          ref.invalidate(pinStatusProvider);
          ref.invalidate(biometricProvider);

          return ref.refresh(walletProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
          children: body,
        ),
      ),
    );
  }

  static String _pinSubtitle(AppLocalizations l10n, PinStatus pin) {
    final now = DateTime.now();

    if (pin.lockedAt(now)) {
      return l10n.walletPinLockedUntil(formatClock(l10n, pin.lockedUntil!));
    }

    return pin.isSet ? l10n.walletPinIsSet : l10n.walletPinNotSet;
  }
}

/// "Pay with fingerprint": a switch; turning it on takes the PIN once. The wallet
/// screen does the switching: this row may go while the PIN's status loads again.
class _BiometricRow extends StatelessWidget {
  const _BiometricRow({required this.state, required this.onChanged});

  final BiometricState state;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final face = state.kind == BiometricKind.face;
    void flip() => onChanged(!state.enabled);

    return MergeSemantics(
      child: AppListRow(
        icon: face ? Icons.face_outlined : Icons.fingerprint,
        title: face ? l10n.walletBiometricFace : l10n.walletBiometricFingerprint,
        subtitle: l10n.walletBiometricSubtitle,
        onTap: flip,
        trailing: Switch.adaptive(value: state.enabled, onChanged: (_) => flip()),
      ),
    );
  }
}
