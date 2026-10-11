import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens/metrics.dart';
import 'balance_card.dart';
import 'movement_view.dart';
import 'movements_screen.dart';
import 'statement_screen.dart';
import 'wallet_state.dart';

Future<void> openWallet(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WalletScreen()));

/// 28: the balance, fees still owed, and the latest movements.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final result = ref.watch(walletProvider);

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
        onRefresh: () => ref.refresh(walletProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
          children: body,
        ),
      ),
    );
  }
}
