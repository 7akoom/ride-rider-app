import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/format/time_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/statement.dart';
import '../domain/use_cases/follow_wallet.dart';
import 'movement_view.dart';
import 'statement_controller.dart';

Future<void> openStatement(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StatementScreen()));

/// 30: a period of the wallet: balance at its start and end, what came in and went
/// out, and its movements with the balance after each.
class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({super.key});

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  StatementPeriod _period = StatementPeriod.days30;

  static String _label(AppLocalizations l10n, StatementPeriod period) => switch (period) {
        StatementPeriod.days30 => l10n.period30Days,
        StatementPeriod.months3 => l10n.period3Months,
        StatementPeriod.year => l10n.periodYear,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = (_period, MovementFilter.all);
    final state = ref.watch(statementControllerProvider(query));
    final controller = ref.read(statementControllerProvider(query).notifier);
    final first = state.first;
    final failure = state.failure;
    final now = DateTime.now();

    return AppScaffold(
      topBar: AppTopBar(title: l10n.statementTitle),
      body: NotificationListener<ScrollNotification>(
        onNotification: (note) {
          if (note.metrics.extentAfter < Sizes.hero * 3) {
            controller.more();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
          children: [
            AppChoiceChips<StatementPeriod>(
              options: [for (final p in StatementPeriod.values) (p, _label(l10n, p))],
              selected: _period,
              onSelected: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: Space.x4),
            Text(
              l10n.statementRange(
                formatDate(l10n, now.subtract(LoadStatement.lengthOf(_period))),
                formatDate(l10n, now),
              ),
              style: context.typo.h3,
            ),
            const SizedBox(height: Space.x3),
            if (first == null && failure == null)
              const SkeletonView(child: SkeletonBox(height: 150, radius: Radii.card))
            else if (first != null)
              _Totals(page: first),
            if (failure != null) ...[
              const SizedBox(height: Space.x3),
              StatusBanner(
                tone: Tone.danger,
                message: failure.message(l10n),
                actionLabel: l10n.actionRetry,
                onAction: controller.retry,
              ),
            ],
            ...movementsByDay(context, state.movements, showBalance: true),
            if (state.hasMore && failure == null)
              Padding(
                padding: const EdgeInsetsDirectional.all(Space.x4),
                child: Center(child: LoadingDots(color: context.palette.brandStrong)),
              ),
          ],
        ),
      ),
    );
  }
}

/// The period's four figures, two by two.
class _Totals extends StatelessWidget {
  const _Totals({required this.page});

  final StatementPage page;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    Widget tile(String label, int amount, Color background, {MoneyTone tone = MoneyTone.neutral}) => Expanded(
          child: Container(
            padding: const EdgeInsetsDirectional.all(Space.x3),
            decoration: BoxDecoration(color: background, borderRadius: const BorderRadius.all(Radius.circular(Radii.card))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.typo.caption.copyWith(color: p.textSecondary)),
                const SizedBox(height: Space.x1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: MoneyText(amount, style: context.typo.bodyStrong, tone: tone),
                ),
              ],
            ),
          ),
        );

    return Column(
      children: [
        Row(children: [
          tile(l10n.statementOpening, page.opening, p.surface2),
          const SizedBox(width: Space.x2),
          tile(l10n.statementIn, page.totalIn, p.successSoft, tone: MoneyTone.credit),
        ]),
        const SizedBox(height: Space.x2),
        Row(children: [
          tile(l10n.statementOut, -page.totalOut, p.surface2),
          const SizedBox(width: Space.x2),
          tile(l10n.statementClosing, page.closing, p.brandSoft),
        ]),
      ],
    );
  }
}
