import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/fare_quote.dart';
import '../../domain/use_cases/quote_ride.dart';
import 'choose_ride_state.dart';
import 'ride_texts.dart';

/// The ride types with their prices, or what stands in for them: skeletons while they
/// load, the reason when they could not.
class QuoteList extends StatelessWidget {
  const QuoteList({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onRetry,
  });

  final ChooseRideState state;
  final ValueChanged<String> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quotes = state.quotes;
    final failure = state.quoteFailure;

    if (quotes == null && failure != null) {
      return StatusBanner(
        tone: Tone.danger,
        message: RideTexts.quoteFailure(l10n, failure),
        actionLabel: isOutsideServiceArea(failure) ? null : l10n.actionRetry,
        onAction: onRetry,
      );
    }

    if (quotes == null) {
      return const SkeletonView(
        child: Column(
          children: [
            SkeletonBox(height: _skeletonHeight),
            SizedBox(height: Space.x3),
            SkeletonBox(height: _skeletonHeight),
          ],
        ),
      );
    }

    if (quotes.quotes.isEmpty) {
      return StatusBanner(tone: Tone.warning, message: l10n.chooseRideNoCaptains);
    }

    return Column(
      children: [
        for (final quote in quotes.quotes)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Space.x3),
            child: _card(l10n, quote),
          ),
      ],
    );
  }

  /// About the height of a vehicle card.
  static const double _skeletonHeight = 72;

  Widget _card(AppLocalizations l10n, FareQuote quote) {
    final eta = quote.driversAvailable && quote.pickupEtaMinutes > 0
        ? quote.pickupEtaMinutes
        : null;

    return VehicleOptionCard(
      name: RideTexts.vehicle(l10n, quote.vehicleClass),
      seats: RideTexts.seats,
      etaMinutes: eta,
      unavailable: quote.driversAvailable ? null : l10n.chooseRideNoCaptains,
      price: quote.total,
      priceBeforeDiscount: quote.beforeDiscount,
      note: RideTexts.discount(l10n, quote.discount),
      selected: quote.vehicleClass == state.selectedClass,
      onTap: () => onSelect(quote.vehicleClass),
    );
  }
}
