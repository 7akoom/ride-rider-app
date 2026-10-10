import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../onboarding_providers.dart';
import '../onboarding_navigation.dart';

/// 06: why the app wants the location, before the system asks. Shown once; "Not now"
/// carries on without it.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool _busy = false;

  Future<void> _finish({required bool allow}) async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);
    final next = await ref.read(finishLocationStepProvider).call(allow: allow);

    if (mounted) {
      openStep(context, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    return AppScaffold(
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: l10n.locationAllow,
            icon: Icons.my_location,
            loading: _busy,
            onPressed: () => _finish(allow: true),
          ),
          const SizedBox(height: Space.x2),
          AppButton(
            label: l10n.locationNotNow,
            variant: AppButtonVariant.text,
            onPressed: _busy ? null : () => _finish(allow: false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(top: Space.x6),
        children: [
          Center(
            child: Container(
              width: Sizes.hero,
              height: Sizes.hero,
              decoration: BoxDecoration(shape: BoxShape.circle, color: p.brandSoft),
              child: Icon(Icons.location_on_rounded, size: Sizes.heroIcon, color: p.brandStrong),
            ),
          ),
          const SizedBox(height: Space.x6),
          Text(l10n.locationTitle, textAlign: TextAlign.center, style: context.typo.h1),
          const SizedBox(height: Space.x2),
          Text(
            l10n.locationSubtitle,
            textAlign: TextAlign.center,
            style: context.typo.body.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Space.x6),
          AppListRow(
            icon: Icons.near_me_outlined,
            title: l10n.locationPickupTitle,
            subtitle: l10n.locationPickupBody,
            showChevron: false,
          ),
          AppListRow(
            icon: Icons.schedule,
            title: l10n.locationEtaTitle,
            subtitle: l10n.locationEtaBody,
            showChevron: false,
          ),
          AppListRow(
            icon: Icons.shield_outlined,
            title: l10n.locationSafetyTitle,
            subtitle: l10n.locationSafetyBody,
            showChevron: false,
          ),
          const SizedBox(height: Space.x4),
          StatusBanner(tone: Tone.info, message: l10n.locationPrivacy),
        ],
      ),
    );
  }
}
