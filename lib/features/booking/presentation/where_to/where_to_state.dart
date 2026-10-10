import '../../../../core/error/failure.dart';
import '../../domain/entities/spot.dart';
import '../../domain/entities/trip_draft.dart';
import '../../domain/use_cases/load_suggestions.dart';

/// The field being filled in on the where-to screen.
sealed class TripField {
  const TripField();
}

final class PickupField extends TripField {
  const PickupField();
}

final class DestinationField extends TripField {
  const DestinationField();
}

/// Stop [index] (from 0): an existing stop to change, or the next one to add.
final class StopField extends TripField {
  const StopField(this.index);

  final int index;

  @override
  bool operator ==(Object other) => other is StopField && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

/// What the search area shows.
sealed class SearchView {
  const SearchView();
}

/// Nothing typed yet: saved and popular places (null while they load).
final class SuggestionsView extends SearchView {
  const SuggestionsView(this.suggestions);

  final Suggestions? suggestions;
}

final class SearchingView extends SearchView {
  const SearchingView();
}

final class ResultsView extends SearchView {
  const ResultsView(this.spots);

  final List<Spot> spots;
}

/// The search did not answer. The suggestions stay under the message, so the rider
/// can still pick a saved or popular place, or choose on the map.
final class SearchFailedView extends SearchView {
  const SearchFailedView(this.failure, this.suggestions);

  final Failure failure;
  final Suggestions? suggestions;
}

final class WhereToState {
  const WhereToState({
    required this.draft,
    required this.field,
    required this.view,
    this.addingStop = false,
  });

  final TripDraft draft;
  final TripField field;
  final SearchView view;

  /// An empty stop row is shown while its place is being chosen.
  final bool addingStop;

  WhereToState copyWith({
    TripDraft? draft,
    TripField? field,
    SearchView? view,
    bool? addingStop,
  }) =>
      WhereToState(
        draft: draft ?? this.draft,
        field: field ?? this.field,
        view: view ?? this.view,
        addingStop: addingStop ?? this.addingStop,
      );
}
