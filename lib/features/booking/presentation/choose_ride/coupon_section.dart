import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/fare_quote.dart';
import '../../domain/entities/trip_draft.dart';
import 'choose_ride_controller.dart';
import 'ride_texts.dart';

/// The coupon code field and what became of the code on the chosen ride type.
class CouponSection extends ConsumerStatefulWidget {
  const CouponSection({super.key, required this.draft});

  final TripDraft draft;

  @override
  ConsumerState<CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends ConsumerState<CouponSection> {
  late final TextEditingController _code = TextEditingController(
    text: ref.read(chooseRideControllerProvider(widget.draft)).couponCode ?? '',
  );
  bool _applying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_code.text.trim().isEmpty || _applying) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _applying = true);
    await ref.read(chooseRideControllerProvider(widget.draft).notifier).applyCoupon(_code.text);

    if (mounted) {
      setState(() => _applying = false);
    }
  }

  Future<void> _remove() async {
    _code.clear();
    await ref.read(chooseRideControllerProvider(widget.draft).notifier).removeCoupon();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(chooseRideControllerProvider(widget.draft));
    final code = state.couponCode;
    final message = code == null || state.loading
        ? null
        : RideTexts.coupon(l10n, state.coupon, code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.couponTitle, style: context.typo.h3),
        const SizedBox(height: Space.x3),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _code,
                hint: l10n.couponHint,
                fieldDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                prefix: const Icon(Icons.local_offer_outlined),
                onSubmitted: (_) => _apply(),
              ),
            ),
            const SizedBox(width: Space.x2),
            AppButton(
              label: l10n.couponApply,
              variant: AppButtonVariant.ink,
              expand: false,
              loading: _applying,
              onPressed: _apply,
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: Space.x3),
          StatusBanner(
            tone: state.coupon == CouponResult.applied ? Tone.success : Tone.warning,
            message: message,
            actionLabel: l10n.couponRemove,
            onAction: _remove,
          ),
        ],
      ],
    );
  }
}
