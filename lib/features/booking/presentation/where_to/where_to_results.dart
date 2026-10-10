import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/format/distance_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/location/distance.dart';
import '../../../../core/location/geo_point.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/spot.dart';
import '../../domain/use_cases/load_suggestions.dart';
import '../spot_view.dart';
import 'where_to_state.dart';

/// Under the fields: "choose on the map", then the suggestions or the search results.
class WhereToResults extends StatelessWidget {
  const WhereToResults({
    super.key,
    required this.view,
    required this.from,
    required this.onChoose,
    required this.onMap,
  });

  final SearchView view;

  /// Distances are measured from here (the pickup), when known.
  final GeoPoint? from;
  final ValueChanged<Spot> onChoose;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: Space.x8),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        AppListRow(
          icon: Icons.map_outlined,
          title: l10n.whereToOnMap,
          onTap: onMap,
        ),
        ...switch (view) {
          SuggestionsView(:final suggestions) => _suggestions(context, suggestions),
          SearchingView() => [const SkeletonList(rows: 4)],
          ResultsView(:final spots) when spots.isEmpty => [
              EmptyState(icon: Icons.search_off, message: l10n.whereToNoResults),
            ],
          ResultsView(:final spots) => spots.map((spot) => _row(context, spot)).toList(),
          SearchFailedView(:final failure, :final suggestions) => [
              const SizedBox(height: Space.x3),
              StatusBanner(tone: Tone.warning, message: _failureMessage(l10n, failure)),
              ..._suggestions(context, suggestions),
            ],
        },
      ],
    );
  }

  /// No connection is the rider's to fix, so it says so. Anything else means the search
  /// itself is down: the map still works, and the message points there.
  static String _failureMessage(AppLocalizations l10n, Failure failure) {
    return switch (failure) {
      NetworkFailure() || TimeoutFailure() => failure.message(l10n),
      _ => l10n.whereToSearchUnavailable,
    };
  }

  List<Widget> _suggestions(BuildContext context, Suggestions? suggestions) {
    final l10n = context.l10n;

    if (suggestions == null) {
      return [const SkeletonList(rows: 3)];
    }

    return [
      if (suggestions.saved.isNotEmpty) ...[
        SectionHeader(title: l10n.whereToSaved),
        ...suggestions.saved.map((spot) => _row(context, spot)),
      ],
      if (suggestions.featured.isNotEmpty) ...[
        SectionHeader(title: l10n.whereToPopular),
        ...suggestions.featured.map((spot) => _row(context, spot)),
      ],
    ];
  }

  Widget _row(BuildContext context, Spot spot) {
    final l10n = context.l10n;
    final start = from;

    return AppListRow(
      icon: SpotView.icon(spot.kind),
      title: SpotView.title(l10n, spot),
      subtitle: spot.detail,
      showChevron: false,
      trailing: start == null
          ? null
          : Text(
              formatDistance(l10n, metersBetween(start, spot.point)),
              style: context.typo.caption.copyWith(color: context.palette.textSecondary),
            ),
      onTap: () => onChoose(spot),
    );
  }
}
