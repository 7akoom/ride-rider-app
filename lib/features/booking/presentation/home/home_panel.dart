import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/location/location_access.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/saved_place.dart';
import 'home_state.dart';

/// The sheet under the map: the pickup, the location notice when needed, "Where to?"
/// and the saved places.
class HomePanel extends ConsumerWidget {
  const HomePanel({
    super.key,
    required this.onWhereTo,
    required this.onSavedPlace,
    required this.onTurnOnLocation,
  });

  final VoidCallback onWhereTo;
  final ValueChanged<SavedPlace> onSavedPlace;
  final VoidCallback onTurnOnLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(locationStatusProvider).valueOrNull;
    final shortcuts = ref.watch(shortcutsProvider).valueOrNull ?? const <SavedPlace>[];

    return MapPanel(
      children: [
        Text(l10n.homeRide, style: context.typo.h2),
        const SizedBox(height: Space.x1),
        const _PickupLine(),
        if (status != null && status != LocationAccessStatus.granted) ...[
          const SizedBox(height: Space.x3),
          StatusBanner(
            tone: Tone.warning,
            message: l10n.homeLocationOff,
            actionLabel: l10n.homeLocationTurnOn,
            onAction: onTurnOnLocation,
          ),
        ],
        const SizedBox(height: Space.x4),
        SearchBarButton(label: l10n.homeWhereTo, onTap: onWhereTo),
        if (shortcuts.isNotEmpty) ...[
          const SizedBox(height: Space.x4),
          Row(
            children: [
              for (final place in shortcuts)
                Expanded(
                  child: ShortcutTile(
                    icon: _iconOf(place.kind),
                    label: _nameOf(l10n, place),
                    onTap: () => onSavedPlace(place),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: Space.x2),
      ],
    );
  }

  static IconData _iconOf(SavedPlaceKind kind) => switch (kind) {
        SavedPlaceKind.home => Icons.home_outlined,
        SavedPlaceKind.work => Icons.work_outline,
        SavedPlaceKind.other => Icons.place_outlined,
      };

  static String _nameOf(AppLocalizations l10n, SavedPlace place) => switch (place.kind) {
        SavedPlaceKind.home => l10n.savedHome,
        SavedPlaceKind.work => l10n.savedWork,
        SavedPlaceKind.other => place.label,
      };
}

class _PickupLine extends ConsumerWidget {
  const _PickupLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pickup = ref.watch(pickupProvider);

    final String? text = switch (pickup) {
      AsyncData(:final value) when value == null => null,
      AsyncData(:final value) => value!.title == null
          ? l10n.homePickupHere
          : l10n.homePickupFrom(value.title!),
      AsyncError() => null,
      _ => l10n.homePickupFinding,
    };

    if (text == null) {
      return const SizedBox.shrink();
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.typo.caption.copyWith(color: context.palette.textSecondary),
    );
  }
}
