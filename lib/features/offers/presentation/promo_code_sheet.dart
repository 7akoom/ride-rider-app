import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/error/result.dart';
import '../../../core/format/bidi.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/offer.dart';
import '../offers_providers.dart';
import 'offer_texts.dart';

/// "Enter a promo code": the code is checked for the rider and, when it is theirs to
/// use, kept for their next ride.
Future<void> showPromoCodeSheet(BuildContext context) =>
    showAppSheet<void>(context: context, builder: (_) => const PromoCodeSheet());

class PromoCodeSheet extends ConsumerStatefulWidget {
  const PromoCodeSheet({super.key});

  @override
  ConsumerState<PromoCodeSheet> createState() => _PromoCodeSheetState();
}

class _PromoCodeSheetState extends ConsumerState<PromoCodeSheet> {
  final TextEditingController _code = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final l10n = context.l10n;

    setState(() {
      _checking = true;
      _error = null;
    });

    final result = await ref.read(checkCodeProvider).call(_code.text);

    if (!mounted) {
      return;
    }

    switch (result) {
      case Ok(value: CodeCheckResult(check: CodeCheck.usable, coupon: final CouponOffer coupon)):
        await ref.read(keepCodeProvider).keep(coupon.code);
        ref.invalidate(keptCodeProvider);

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();
        showAppToast(context, l10n.offerKept(isolateLtr(coupon.code)));
      case Ok(:final value):
        setState(() {
          _checking = false;
          _error = OfferTexts.refusal(l10n, value.check);
        });
      case Err(:final failure):
        setState(() {
          _checking = false;
          _error = failure.message(l10n);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.promoTitle, onClose: () => Navigator.of(context).pop()),
        Text(l10n.promoBody, style: context.typo.body),
        const SizedBox(height: Space.x4),
        AppTextField(
          controller: _code,
          hint: l10n.couponHint,
          autofocus: true,
          fieldDirection: TextDirection.ltr,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-]')),
            LengthLimitingTextInputFormatter(40),
            TextInputFormatter.withFunction((_, typed) => typed.copyWith(text: typed.text.toUpperCase())),
          ],
          error: _error,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => unawaited(_check()),
        ),
        const SizedBox(height: Space.x4),
        AppButton(
          label: l10n.couponApply,
          loading: _checking,
          onPressed: _checking || _code.text.trim().length < 3 ? null : () => unawaited(_check()),
        ),
      ],
    );
  }
}
