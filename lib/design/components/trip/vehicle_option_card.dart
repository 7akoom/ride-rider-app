import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../design_context.dart';
import '../../tokens/metrics.dart';
import '../money/money_text.dart';

/// One vehicle class in the fare list: picture, name, seats and pickup time, price.
/// The selected one gets a brand border and tint.
///
/// Without [etaMinutes] the line shows [unavailable] instead (no captain nearby), or
/// only the seats.
class VehicleOptionCard extends StatelessWidget {
  const VehicleOptionCard({
    super.key,
    required this.name,
    required this.seats,
    required this.price,
    required this.selected,
    required this.onTap,
    this.priceBeforeDiscount,
    this.note,
    this.picture,
    this.etaMinutes,
    this.unavailable,
  });

  final String name;
  final int seats;
  final int? etaMinutes;
  final String? unavailable;
  final int price;
  final int? priceBeforeDiscount;

  /// A short success line under the price ("coupon applied").
  final String? note;

  /// The vehicle picture; a car icon when null.
  final Widget? picture;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.typo;
    final l10n = context.l10n;
    const radius = BorderRadius.all(Radius.circular(Radii.card));

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.brandSoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? p.brand : p.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Space.x4),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 40,
                  child: picture ?? Icon(Icons.directions_car, color: p.textSecondary),
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: t.bodyStrong),
                      Text(
                        [
                          l10n.seatsCount(seats),
                          if (etaMinutes != null) l10n.etaMinutes(etaMinutes!),
                          if (etaMinutes == null && unavailable != null) unavailable!,
                        ].join(' · '),
                        style: t.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (priceBeforeDiscount != null)
                      MoneyText(priceBeforeDiscount!, style: t.caption, tone: MoneyTone.struck),
                    MoneyText(price),
                    if (note != null)
                      Text(note!, style: t.micro.copyWith(color: p.success)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
