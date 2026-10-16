import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/bidi.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/offer.dart';
import '../offers_providers.dart';
import 'offer_texts.dart';

/// A coupon in full: what it gives, what limits it, its code to copy, and "use it on
/// my next ride" (the price then applies it by itself).
Future<void> showOfferSheet(BuildContext context, CouponOffer offer) =>
    showAppSheet<void>(context: context, builder: (_) => OfferSheet(offer: offer));

class OfferSheet extends ConsumerWidget {
  const OfferSheet({super.key, required this.offer});

  final CouponOffer offer;

  Future<void> _keep(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await ref.read(keepCodeProvider).keep(offer.code);
    ref.invalidate(keptCodeProvider);

    if (context.mounted) {
      Navigator.of(context).pop();
      showAppToast(context, l10n.offerKept(isolateLtr(offer.code)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final kept = ref.watch(keptCodeProvider).valueOrNull == offer.code;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(title: OfferTexts.discount(l10n, offer), onClose: () => Navigator.of(context).pop()),
          Text(OfferTexts.description(l10n, offer), style: context.typo.body),
          const SizedBox(height: Space.x4),
          for (final line in OfferTexts.conditions(l10n, offer))
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: Space.x2),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: Sizes.iconSmall, color: p.textSecondary),
                  const SizedBox(width: Space.x2),
                  Expanded(child: Text(line, style: context.typo.caption.copyWith(color: p.textSecondary))),
                ],
              ),
            ),
          const SizedBox(height: Space.x2),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x4, vertical: Space.x3),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: const BorderRadius.all(Radius.circular(Radii.input)),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Text(l10n.offerCode, style: context.typo.caption.copyWith(color: p.textSecondary)),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Text(isolateLtr(offer.code), style: context.typo.bodyStrong.copyWith(letterSpacing: 1)),
                ),
                AppIconButton(
                  icon: Icons.copy_outlined,
                  semanticLabel: l10n.offerCopy,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: offer.code));

                    if (context.mounted) {
                      showAppToast(context, l10n.offerCopied);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x4),
          if (kept)
            StatusBanner(tone: Tone.success, message: l10n.offerKeptBadge)
          else
            AppButton(label: l10n.offerUseNext, onPressed: () => unawaited(_keep(context, ref))),
        ],
      ),
    );
  }
}
