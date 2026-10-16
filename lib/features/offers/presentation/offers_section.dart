import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/format/bidi.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/offer.dart';
import '../offers_providers.dart';
import 'offer_sheet.dart';
import 'offer_texts.dart';
import 'promo_code_sheet.dart';

/// The home's offers: the first-ride or loyalty discount and the featured coupons.
/// Nothing at all when the server has none for the rider (or could not say).
class OffersSection extends ConsumerWidget {
  const OffersSection({super.key, this.top = 0});

  /// The space above the section, only there when it shows.
  final double top;

  static const double cardWidth = 248;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offers = switch (ref.watch(offersProvider).valueOrNull) {
      Ok(:final value) when !value.isEmpty => value,
      _ => null,
    };

    if (offers == null) {
      return const SizedBox.shrink();
    }

    final first = offers.firstRide;
    final loyalty = offers.loyalty;
    final cards = <Widget>[
      if (first != null) _FirstRideCard(offer: first),
      if (loyalty != null) _LoyaltyCard(offer: loyalty),
      for (final coupon in offers.coupons) _CouponCard(offer: coupon),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: top),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.gutter),
          child: Text(l10n.offersTitle, style: context.typo.h3),
        ),
        const SizedBox(height: Space.x3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.gutter),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: Space.x3),
                  SizedBox(width: cardWidth, child: cards[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One offer: an icon, what it gives in large type, then what it is.
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.icon,
    required this.headline,
    required this.lines,
    this.footer,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String headline;
  final List<String> lines;
  final Widget? footer;
  final VoidCallback? onTap;

  /// The brand tint: discounts the rider gets without doing anything.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const radius = BorderRadius.all(Radius.circular(Radii.card));

    return Material(
      color: highlighted ? p.brandSoft : p.surface,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: p.border)),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Space.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: Sizes.icon, color: p.brandStrong),
                  const SizedBox(width: Space.x2),
                  Expanded(
                    child: Text(
                      headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.typo.h3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.x2),
              for (final line in lines)
                Text(
                  line,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.caption.copyWith(color: p.textSecondary),
                ),
              if (footer != null) ...[
                const Spacer(),
                const SizedBox(height: Space.x3),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FirstRideCard extends StatelessWidget {
  const _FirstRideCard({required this.offer});

  final AutomaticOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _OfferCard(
      icon: Icons.celebration_outlined,
      highlighted: true,
      headline: l10n.offerFirstRideTitle('${offer.percent}'),
      lines: [
        if (OfferTexts.cap(l10n, offer.maxAmount) case final cap?) cap,
        l10n.offerAutomatic,
      ],
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({required this.offer});

  final LoyaltyOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final done = (offer.every - offer.tripsToGo).clamp(0, offer.every);

    return _OfferCard(
      icon: Icons.loyalty_outlined,
      highlighted: true,
      headline: l10n.offerLoyaltyTitle('${offer.percent}', offer.every),
      lines: [
        if (OfferTexts.cap(l10n, offer.maxAmount) case final cap?) cap,
        if (offer.tripsToGo <= 1) l10n.offerLoyaltyNext else l10n.offerLoyaltyToGo(offer.tripsToGo),
      ],
      footer: Semantics(
        label: l10n.offerLoyaltyProgress(done, offer.every),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
          child: LinearProgressIndicator(
            value: offer.every == 0 ? 0 : done / offer.every,
            minHeight: Space.x2,
            color: p.brandStrong,
            backgroundColor: p.surface,
          ),
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.offer});

  final CouponOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    return _OfferCard(
      icon: Icons.local_offer_outlined,
      headline: OfferTexts.discount(l10n, offer),
      lines: [OfferTexts.description(l10n, offer), OfferTexts.until(l10n, offer)],
      onTap: () => unawaited(showOfferSheet(context, offer)),
      footer: Row(
        children: [
          Expanded(
            child: Text(
              isolateLtr(offer.code),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typo.bodyStrong.copyWith(letterSpacing: 1),
            ),
          ),
          Text(l10n.offerDetails, style: context.typo.caption.copyWith(color: p.brandStrong)),
        ],
      ),
    );
  }
}

/// "Enter a promo code", and the code kept for the next ride when there is one.
class PromoCodeCard extends ConsumerWidget {
  const PromoCodeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kept = ref.watch(keptCodeProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListRow(
          icon: Icons.confirmation_number_outlined,
          title: l10n.promoTitle,
          subtitle: l10n.promoSubtitle,
          onTap: () => unawaited(showPromoCodeSheet(context)),
        ),
        if (kept != null) ...[
          const SizedBox(height: Space.x2),
          StatusBanner(
            tone: Tone.success,
            message: l10n.offerKept(isolateLtr(kept)),
            actionLabel: l10n.couponRemove,
            onAction: () async {
              await ref.read(keepCodeProvider).forget();
              ref.invalidate(keptCodeProvider);
            },
          ),
        ],
      ],
    );
  }
}
