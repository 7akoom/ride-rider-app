import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/payment_method.dart';
import '../domain/entities/ride.dart';
import 'choose_ride/ride_texts.dart';

/// A ride at a glance, in one card: where from and to, then the ride type, the
/// price and how it is paid, each with its label. For a requested ride and a booked
/// one alike.
class RideSummaryView extends StatelessWidget {
  const RideSummaryView({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.vehicleClass,
    required this.payment,
    this.stops = const [],
    this.fare,
  });

  RideSummaryView.ofRide(Ride ride, {Key? key})
      : this(
          key: key,
          pickup: ride.pickupAddress,
          dropoff: ride.dropoffAddress,
          stops: [for (final stop in ride.stops) stop.address],
          vehicleClass: ride.vehicleClass,
          payment: ride.payment,
          fare: ride.fare,
        );

  /// Addresses; an empty one is a point picked on the map.
  final String pickup;
  final String dropoff;
  final List<String> stops;
  final String vehicleClass;
  final PaymentMethod payment;

  /// Whole currency units, when known.
  final int? fare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final fare = this.fare;

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
              title: _named(l10n, pickup),
            ),
            for (var i = 0; i < stops.length; i++)
              RoutePoint(
                kind: RoutePointKind.stop,
                label: l10n.routeStop(i + 1),
                title: _named(l10n, stops[i]),
              ),
            RoutePoint(
              kind: RoutePointKind.destination,
              label: l10n.routeDestination,
              title: _named(l10n, dropoff),
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
                  value: RideTexts.vehicle(l10n, vehicleClass),
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
                  icon: RideTexts.paymentIcon(payment),
                  label: l10n.paymentTitle,
                  value: RideTexts.payment(l10n, payment),
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
