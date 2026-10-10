import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/location/geo_point.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/map/app_map.dart';
import '../../../../design/tokens/metrics.dart';
import '../../../../state/locale_provider.dart';
import '../../booking_providers.dart';
import '../../domain/entities/spot.dart';
import '../spot_view.dart';

/// The name of a point under the pin; re-read when the map stops somewhere else.
final _pinnedSpotProvider = FutureProvider.autoDispose.family<Spot, GeoPoint>(
  (ref, point) => ref
      .watch(namePointProvider)
      .call(point, languageCode: ref.watch(localeProvider).languageCode),
);

/// 10: a pin in the middle of the map; the rider moves the map under it and confirms.
/// Returns the chosen spot.
class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key, this.start});

  /// Where the map opens; the copy's city when null.
  final GeoPoint? start;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  late GeoPoint _point = widget.start ?? AppMap.defaultCenter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final pinned = ref.watch(_pinnedSpotProvider(_point));

    return AppScaffold(
      topBar: const AppTopBar(),
      padded: false,
      body: Column(
        // The map takes the full width: in a centred column the stack would shrink to
        // the pin, its only child with a size of its own.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AppMap(
                    center: _point,
                    zoom: AppMap.streetZoom,
                    onSettled: (point) => setState(() => _point = point),
                  ),
                ),
                // The pin's tip is the chosen point: it stands above the middle.
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: Sizes.icon * 2),
                    child: Icon(Icons.location_on, size: Sizes.icon * 2, color: p.brandStrong),
                  ),
                ),
                PositionedDirectional(
                  top: Space.x3,
                  start: Space.gutter,
                  end: Space.gutter,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: Space.x4,
                        vertical: Space.x2,
                      ),
                      decoration: BoxDecoration(
                        color: p.ink,
                        borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
                      ),
                      child: Text(
                        l10n.mapPickerHint,
                        style: context.typo.caption.copyWith(color: p.onInk),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          MapPanel(
            children: [
              switch (pinned) {
                AsyncData(:final value) => Text(
                    SpotView.title(l10n, value),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.h3,
                  ),
                _ => const SkeletonView(child: SkeletonBox(height: 22)),
              },
              const SizedBox(height: Space.x4),
              AppButton(
                label: l10n.mapPickerConfirm,
                icon: Icons.check,
                // Only the name of the point under the pin now, not of an earlier one.
                onPressed: switch (pinned) {
                  AsyncData(:final value) => () => Navigator.of(context).pop(value),
                  _ => null,
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
