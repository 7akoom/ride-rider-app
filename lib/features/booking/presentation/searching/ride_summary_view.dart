import 'package:flutter/material.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/ride.dart';
import '../choose_ride/ride_texts.dart';

/// A requested ride at a glance, in one card: where from and to, then the ride
/// type, the price and how it is paid, each with its label.
class RideSummaryView extends StatelessWidget {
  const RideSummaryView({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final fare = ride.fare;

    return Container(
      padding: const EdgeInsetsDirectional.all(Space.x4),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RouteSummary(points: [
            RoutePoint(
              kind: RoutePointKind.pickup,
              label: l10n.routePickup,
              title: _named(l10n, ride.pickupAddress),
            ),
            for (var i = 0; i < ride.stops.length; i++)
              RoutePoint(
                kind: RoutePointKind.stop,
                label: l10n.routeStop(i + 1),
                title: _named(l10n, ride.stops[i].address),
              ),
            RoutePoint(
              kind: RoutePointKind.destination,
              label: l10n.routeDestination,
              title: _named(l10n, ride.dropoffAddress),
            ),
          ]),
          Divider(height: Space.x6, color: p.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.local_taxi_outlined,
                  label: l10n.rideType,
                  value: RideTexts.vehicle(l10n, ride.vehicleClass),
                ),
              ),
              if (fare != null)
                Expanded(
                  child: _Fact(
                    icon: Icons.receipt_long_outlined,
                    label: l10n.paymentTotal,
                    value: formatMoney(l10n, fare),
                  ),
                ),
              Expanded(
                child: _Fact(
                  icon: RideTexts.paymentIcon(ride.payment),
                  label: l10n.paymentTitle,
                  value: RideTexts.payment(l10n, ride.payment),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A point picked on the map has no address: it is "the selected point".
  static String _named(AppLocalizations l10n, String address) =>
      address.isEmpty ? l10n.spotPinned : address;
}

/// One fact under the route: an icon and a small label, the value under them. The
/// value shrinks to fit rather than being cut (an amount must be read whole).
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: Sizes.iconSmall, color: p.textSecondary),
            const SizedBox(width: Space.x1),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typo.micro.copyWith(color: p.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(value, maxLines: 1, style: context.typo.bodyStrong),
        ),
      ],
    );
  }
}
