import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/spot.dart';
import '../choose_ride/choose_ride_screen.dart';
import '../map_picker/map_picker_screen.dart';
import 'where_to_controller.dart';
import 'where_to_fields.dart';
import 'where_to_results.dart';
import 'where_to_state.dart';

/// 08 and 09: where the trip goes, with up to two stops. Once both ends are known the
/// ride is chosen.
class WhereToScreen extends ConsumerStatefulWidget {
  const WhereToScreen({super.key, required this.start});

  final WhereToStart start;

  @override
  ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends ConsumerState<WhereToScreen> {
  final _query = TextEditingController();

  WhereToController get _controller =>
      ref.read(whereToControllerProvider(widget.start).notifier);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _focus(TripField field) {
    _query.clear();
    _controller.focus(field);
  }

  Future<void> _choose(Spot spot) async {
    _query.clear();
    final complete = _controller.choose(spot);

    if (complete && mounted) {
      final draft = ref.read(whereToControllerProvider(widget.start)).draft;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChooseRideScreen(draft: draft)),
      );
    }
  }

  Future<void> _pickOnMap() async {
    final draft = ref.read(whereToControllerProvider(widget.start)).draft;
    final spot = await Navigator.of(context).push<Spot>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          start: draft.destination?.point ?? draft.pickup?.point,
        ),
      ),
    );

    if (spot != null && mounted) {
      await _choose(spot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(whereToControllerProvider(widget.start));

    return AppScaffold(
      topBar: AppTopBar(title: context.l10n.whereToTitle),
      body: Column(
        children: [
          WhereToFields(
            state: state,
            query: _query,
            onFocus: _focus,
            onType: (text) {
              setState(() {});
              _controller.type(text);
            },
            onAddStop: () {
              _query.clear();
              _controller.addStop();
            },
            onRemoveStop: (index) {
              _query.clear();
              if (index >= state.draft.stops.length) {
                _controller.cancelNewStop();
              } else {
                _controller.removeStop(index);
              }
            },
          ),
          const SizedBox(height: Space.x3),
          Expanded(
            child: WhereToResults(
              view: state.view,
              from: state.draft.pickup?.point,
              onChoose: _choose,
              onMap: _pickOnMap,
            ),
          ),
        ],
      ),
    );
  }
}
