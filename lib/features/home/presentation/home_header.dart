import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../../booking/domain/entities/day_part.dart';
import '../../booking/presentation/home/home_state.dart';

/// The top of the home, in the brand colour: the greeting, the notifications, and
/// "Where to?".
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onWhereTo, required this.onNotifications});

  final VoidCallback onWhereTo;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.x4, Space.x4, Space.x3, Space.x4),
      decoration: BoxDecoration(
        color: p.brand,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.sheet)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: _Greeting()),
              const SizedBox(width: Space.x2),
              AppIconButton(
                icon: Icons.notifications_outlined,
                semanticLabel: l10n.homeNotifications,
                onPressed: onNotifications,
              ),
            ],
          ),
          const SizedBox(height: Space.x4),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: Space.x1),
            child: _WhereTo(label: l10n.homeWhereTo, onTap: onWhereTo),
          ),
        ],
      ),
    );
  }
}

/// "Where to?" on the brand colour: a white field, as the search it opens.
class _WhereTo extends StatelessWidget {
  const _WhereTo({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const radius = BorderRadius.all(Radius.circular(Radii.input));

    return Semantics(
      button: true,
      child: Material(
        color: p.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.inputHeight),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x4),
              child: Row(
                children: [
                  Icon(Icons.search, color: p.textPrimary),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.typo.bodyStrong),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = ref.watch(riderFirstNameProvider);

    if (name.isLoading) {
      return const Align(
        alignment: AlignmentDirectional.centerStart,
        child: SkeletonView(child: SkeletonBox(width: 180, height: 28)),
      );
    }

    final first = name.valueOrNull;
    final text = first == null
        ? l10n.homeGreetingPlain
        : switch (DayPart.of(DateTime.now())) {
            DayPart.morning => l10n.homeGreetingMorning(first),
            DayPart.afternoon => l10n.homeGreetingAfternoon(first),
            DayPart.evening => l10n.homeGreetingEvening(first),
          };

    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.typo.h2.copyWith(color: context.palette.onBrand),
    );
  }
}
