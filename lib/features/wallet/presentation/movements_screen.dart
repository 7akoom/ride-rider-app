import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/statement.dart';
import '../domain/use_cases/follow_wallet.dart';
import 'movement_view.dart';
import 'statement_controller.dart';
import 'statement_screen.dart';

Future<void> openMovements(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MovementsScreen()));

/// 29: every movement of the past year by day, filtered by kind; more as the rider
/// scrolls.
class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({super.key});

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen> {
  MovementFilter _filter = MovementFilter.all;

  static String _label(AppLocalizations l10n, MovementFilter filter) => switch (filter) {
        MovementFilter.all => l10n.filterAll,
        MovementFilter.moneyIn => l10n.filterIn,
        MovementFilter.moneyOut => l10n.filterOut,
        MovementFilter.tips => l10n.filterTips,
        MovementFilter.refunds => l10n.filterRefunds,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = (StatementPeriod.year, _filter);
    final state = ref.watch(statementControllerProvider(query));
    final controller = ref.read(statementControllerProvider(query).notifier);
    final failure = state.failure;

    return AppScaffold(
      topBar: AppTopBar(title: l10n.movementsTitle),
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
            AppChoiceChips<MovementFilter>(
              options: [for (final f in MovementFilter.values) (f, _label(l10n, f))],
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            if (state.loading && state.movements.isEmpty)
              const Padding(
                padding: EdgeInsetsDirectional.only(top: Space.x4),
                child: SkeletonList(rows: 6),
              )
            else if (state.movements.isEmpty && failure == null)
              EmptyState(icon: Icons.receipt_long_outlined, message: l10n.walletEmpty),
            ...movementsByDay(context, state.movements),
            if (failure != null) ...[
              const SizedBox(height: Space.x3),
              StatusBanner(
                tone: Tone.danger,
                message: failure.message(l10n),
                actionLabel: l10n.actionRetry,
                onAction: controller.retry,
              ),
            ],
            if (state.hasMore && failure == null)
              Padding(
                padding: const EdgeInsetsDirectional.all(Space.x4),
                child: Center(child: LoadingDots(color: context.palette.brandStrong)),
              ),
            const SizedBox(height: Space.x3),
            AppListRow(
              icon: Icons.summarize_outlined,
              title: l10n.statementTitle,
              onTap: () => openStatement(context),
            ),
          ],
        ),
      ),
    );
  }
}
