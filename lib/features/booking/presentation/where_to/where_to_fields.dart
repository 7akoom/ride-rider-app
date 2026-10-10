import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/spot.dart';
import '../spot_view.dart';
import 'where_to_state.dart';

/// The trip's points as fields: pickup, the stops, destination. The field being filled
/// takes the typing; the others show their place and can be tapped to change it.
class WhereToFields extends StatelessWidget {
  const WhereToFields({
    super.key,
    required this.state,
    required this.query,
    required this.onFocus,
    required this.onType,
    required this.onAddStop,
    required this.onRemoveStop,
  });

  final WhereToState state;
  final TextEditingController query;
  final ValueChanged<TripField> onFocus;
  final ValueChanged<String> onType;
  final VoidCallback onAddStop;
  final ValueChanged<int> onRemoveStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = state.draft;
    final stopCount = draft.stops.length + (state.addingStop ? 1 : 0);

    return Container(
      padding: const EdgeInsetsDirectional.all(Space.x3),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(
            context,
            field: const PickupField(),
            marker: RoutePointKind.pickup,
            spot: draft.pickup,
            hint: l10n.whereToPickupHint,
          ),
          for (var i = 0; i < stopCount; i++)
            _row(
              context,
              field: StopField(i),
              marker: RoutePointKind.stop,
              spot: i < draft.stops.length ? draft.stops[i] : null,
              hint: l10n.whereToStopHint(i + 1),
              trailing: AppIconButton(
                icon: Icons.close,
                semanticLabel: l10n.whereToRemoveStop,
                onPressed: () => onRemoveStop(i),
              ),
            ),
          _row(
            context,
            field: const DestinationField(),
            marker: RoutePointKind.destination,
            spot: draft.destination,
            hint: l10n.whereToDestinationHint,
            trailing: draft.canAddStop && !state.addingStop
                ? AppIconButton(
                    icon: Icons.add,
                    semanticLabel: l10n.whereToAddStop,
                    onPressed: onAddStop,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required TripField field,
    required RoutePointKind marker,
    required Spot? spot,
    required String hint,
    Widget? trailing,
  }) {
    final l10n = context.l10n;
    final current = spot == null ? null : SpotView.title(l10n, spot);
    final active = state.field == field;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x1),
      child: Row(
        children: [
          RouteMarker(kind: marker),
          const SizedBox(width: Space.x3),
          Expanded(
            child: active
                ? AppTextField(
                    controller: query,
                    hint: current ?? hint,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: onType,
                    suffix: query.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: l10n.whereToClear,
                            onPressed: () {
                              query.clear();
                              onType('');
                            },
                          ),
                  )
                : _FilledField(
                    text: current ?? hint,
                    empty: current == null,
                    onTap: () => onFocus(field),
                  ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Space.x2),
            trailing,
          ],
        ],
      ),
    );
  }
}

class _FilledField extends StatelessWidget {
  const _FilledField({required this.text, required this.empty, required this.onTap});

  final String text;
  final bool empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const radius = BorderRadius.all(Radius.circular(Radii.input));

    return Material(
      color: p.surface2,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: Sizes.inputHeight),
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x4),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typo.body.copyWith(
              color: empty ? p.textTertiary : p.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
