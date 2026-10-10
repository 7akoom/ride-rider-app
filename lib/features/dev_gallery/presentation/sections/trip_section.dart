import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../gallery_section.dart';

class TripSection extends StatefulWidget {
  const TripSection({super.key});

  @override
  State<TripSection> createState() => _TripSectionState();
}

class _TripSectionState extends State<TripSection> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GallerySection(
      title: l10n.gallerySectionTrip,
      children: [
        RouteSummary(points: [
          RoutePoint(
            kind: RoutePointKind.pickup,
            label: l10n.routePickup,
            title: l10n.gallerySamplePickup,
          ),
          RoutePoint(
            kind: RoutePointKind.stop,
            label: l10n.routeStop(1),
            title: l10n.gallerySampleTitle,
            subtitle: l10n.gallerySampleBody,
          ),
          RoutePoint(
            kind: RoutePointKind.destination,
            label: l10n.routeDestination,
            title: l10n.gallerySampleDestination,
          ),
        ]),
        VehicleOptionCard(
          name: l10n.vehicleEconomy,
          seats: 4,
          etaMinutes: 5,
          price: 3000,
          priceBeforeDiscount: 4250,
          note: l10n.gallerySampleTitle,
          selected: _selected == 0,
          onTap: () => setState(() => _selected = 0),
        ),
        VehicleOptionCard(
          name: l10n.vehicleComfort,
          seats: 4,
          etaMinutes: 7,
          price: 3750,
          selected: _selected == 1,
          onTap: () => setState(() => _selected = 1),
        ),
        DriverCard(
          name: l10n.gallerySampleDriver,
          car: l10n.gallerySampleCar,
          plate: '22 A 25626',
          rating: 4.9,
          onCall: () {},
          onChat: () {},
          hasUnreadMessage: true,
        ),
      ],
    );
  }
}
