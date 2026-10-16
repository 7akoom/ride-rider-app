import '../../../core/format/money_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/entities/offer.dart';

/// How the offers read, in one place for the cards and the sheets.
abstract final class OfferTexts {
  /// "30% off" or "2,000 IQD off".
  static String discount(AppLocalizations l10n, CouponOffer offer) => switch (offer.kind) {
        OfferDiscount.percent => l10n.offerPercent('${offer.value}'),
        OfferDiscount.amount => l10n.offerAmount(formatMoney(l10n, offer.value)),
      };

  static String description(AppLocalizations l10n, CouponOffer offer) =>
      offer.description.isEmpty ? l10n.offerDefaultDescription : offer.description;

  static String until(AppLocalizations l10n, CouponOffer offer) => l10n.offerUntil(formatDate(l10n, offer.validUntil));

  /// What limits it, each on its own line.
  static List<String> conditions(AppLocalizations l10n, CouponOffer offer) => [
        if (offer.maxDiscount != null) l10n.offerUpTo(formatMoney(l10n, offer.maxDiscount!)),
        if (offer.minimumFare > 0) l10n.offerMinimumFare(formatMoney(l10n, offer.minimumFare)),
        if (offer.vehicleClasses.isNotEmpty) l10n.offerSomeClasses,
        if (offer.limitedArea) l10n.offerSomeAreas,
        if (offer.newRidersOnly) l10n.offerNewRiders,
        l10n.offerUsesLeft(offer.usesLeft),
        until(l10n, offer),
      ];

  static String? cap(AppLocalizations l10n, int? amount) => amount == null ? null : l10n.offerUpTo(formatMoney(l10n, amount));

  /// Why a typed code is not the rider's to use.
  static String refusal(AppLocalizations l10n, CodeCheck check) => switch (check) {
        CodeCheck.usable => '',
        CodeCheck.notFound => l10n.couponNotFound,
        CodeCheck.ended => l10n.couponEnded,
        CodeCheck.notStarted => l10n.couponNotStarted,
        CodeCheck.expired => l10n.couponExpired,
        CodeCheck.usedUp => l10n.couponUsedUp,
        CodeCheck.alreadyUsed => l10n.couponAlreadyUsed,
        CodeCheck.newRidersOnly => l10n.couponNewRidersOnly,
      };
}
