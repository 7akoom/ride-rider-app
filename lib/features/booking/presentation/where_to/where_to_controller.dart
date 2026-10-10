import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/geo_point.dart';
import '../../../../state/locale_provider.dart';
import '../../booking_providers.dart';
import '../../domain/entities/spot.dart';
import '../../domain/entities/trip_draft.dart';
import '../../domain/use_cases/load_suggestions.dart';
import '../../domain/use_cases/search_places.dart';
import 'where_to_state.dart';

/// Where the where-to screen starts: the pickup the home screen found, and a
/// destination when a saved place was tapped.
final class WhereToStart {
  const WhereToStart({this.pickup, this.destination});

  final Spot? pickup;
  final Spot? destination;
}

final whereToControllerProvider = NotifierProvider.autoDispose
    .family<WhereToController, WhereToState, WhereToStart>(WhereToController.new);

class WhereToController extends AutoDisposeFamilyNotifier<WhereToState, WhereToStart> {
  Timer? _wait;
  int _searchNumber = 0;
  bool _closed = false;
  Suggestions? _suggestions;

  /// Typing pauses this long before searching, so a word is one request, not one per
  /// letter.
  static const Duration typingPause = Duration(milliseconds: 350);

  @override
  WhereToState build(WhereToStart arg) {
    ref.onDispose(() {
      _closed = true;
      _wait?.cancel();
    });
    unawaited(_loadSuggestions(arg.pickup?.point));

    return WhereToState(
      draft: TripDraft(pickup: arg.pickup, destination: arg.destination),
      field: arg.pickup == null && arg.destination != null
          ? const PickupField()
          : const DestinationField(),
      view: const SuggestionsView(null),
    );
  }

  String get _language => ref.read(localeProvider).languageCode;

  Future<void> _loadSuggestions(GeoPoint? near) async {
    final suggestions = await ref
        .read(loadSuggestionsProvider)
        .call(near: near, languageCode: _language);
    _suggestions = suggestions;

    if (!_closed && state.view is SuggestionsView) {
      state = state.copyWith(view: SuggestionsView(suggestions));
    }
  }

  void _stopSearching() {
    _wait?.cancel();
    _searchNumber++;
  }

  void focus(TripField field) {
    _stopSearching();
    state = state.copyWith(
      field: field,
      view: SuggestionsView(_suggestions),
      addingStop: field is StopField && field.index >= state.draft.stops.length,
    );
  }

  void type(String text) {
    _stopSearching();

    if (text.trim().runes.length < SearchPlaces.minLength) {
      state = state.copyWith(view: SuggestionsView(_suggestions));

      return;
    }

    state = state.copyWith(view: const SearchingView());
    final number = _searchNumber;
    _wait = Timer(typingPause, () => _search(text, number));
  }

  Future<void> _search(String text, int number) async {
    final result = await ref.read(searchPlacesProvider).call(
          text,
          near: state.draft.pickup?.point,
          languageCode: _language,
        );

    // The screen closed, or a newer search or a choice came after this one.
    if (_closed || number != _searchNumber) {
      return;
    }

    state = state.copyWith(
      view: result.fold<SearchView>(
        ResultsView.new,
        (failure) => SearchFailedView(failure, _suggestions),
      ),
    );
  }

  /// Puts [spot] in the field being filled. True when the trip now has both ends.
  bool choose(Spot spot) {
    _stopSearching();

    final draft = switch (state.field) {
      PickupField() => state.draft.withPickup(spot),
      DestinationField() => state.draft.withDestination(spot),
      StopField(:final index) => state.draft.withStop(index, spot),
    };

    state = WhereToState(
      draft: draft,
      field: draft.pickup == null ? const PickupField() : const DestinationField(),
      view: SuggestionsView(_suggestions),
    );

    return draft.isComplete;
  }

  void addStop() {
    if (state.draft.canAddStop && !state.addingStop) {
      focus(StopField(state.draft.stops.length));
    }
  }

  void removeStop(int index) {
    _stopSearching();
    state = WhereToState(
      draft: state.draft.withoutStop(index),
      field: const DestinationField(),
      view: SuggestionsView(_suggestions),
    );
  }

  /// Drops the empty stop row that was being filled.
  void cancelNewStop() {
    if (state.addingStop) {
      focus(const DestinationField());
    }
  }
}
