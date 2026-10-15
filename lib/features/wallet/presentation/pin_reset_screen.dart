import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_mapper.dart';
import '../../../core/format/bidi.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/phone/phone_number.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../../../state/api_providers.dart';
import '../../onboarding/presentation/otp/otp_resend_row.dart';
import '../../onboarding/presentation/sign_in_messages.dart';
import 'pin_reset_controller.dart';
import 'wallet_pin_controller.dart';
import 'wallet_pin_screen.dart';

/// A forgotten wallet PIN: a code to the rider's phone, then a new PIN. True when a
/// new PIN was saved.
Future<bool> openPinReset(BuildContext context) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const PinResetScreen()),
  );

  return saved ?? false;
}

/// To reset the PIN the rider proves the phone is theirs again, as when signing in:
/// the new session lets a new PIN be set without the old one for a few minutes.
class PinResetScreen extends ConsumerWidget {
  const PinResetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final phone = ref.watch(myPhoneProvider);

    final Widget body = switch (phone) {
      AsyncData(:final value) => switch (value == null ? null : PhoneNumber.tryParse(value)) {
          final PhoneNumber number => _ResetCode(phone: number),
          null => EmptyState(icon: Icons.phone_disabled_outlined, message: l10n.pinResetNoPhone),
        },
      AsyncError(:final error) => FailureView(
          failure: mapToFailure(error),
          onRetry: () => ref.invalidate(myPhoneProvider),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };

    return AppScaffold(
      topBar: AppTopBar(title: l10n.pinResetTitle),
      body: body,
    );
  }
}

class _ResetCode extends ConsumerWidget {
  const _ResetCode({required this.phone});

  final PhoneNumber phone;

  Future<void> _confirm(BuildContext context, WidgetRef ref, String code) async {
    final signedIn = await ref.read(pinResetControllerProvider(phone).notifier).confirm(code);

    if (!signedIn || !context.mounted) {
      return;
    }

    // The code's keyboard closes: the PIN has its own pad.
    FocusManager.instance.primaryFocus?.unfocus();
    final navigator = Navigator.of(context);
    final saved = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => const WalletPinScreen(mode: PinMode.reset)),
    );

    navigator.pop(saved ?? false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final state = ref.watch(pinResetControllerProvider(phone));
    final controller = ref.read(pinResetControllerProvider(phone).notifier);
    final failure = state.failure;
    final resendAt = state.resendAt;

    return ListView(
      padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x6),
      children: [
        Text(
          l10n.pinResetBody(isolateLtr(phone.display)),
          style: context.typo.body.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Space.x6),
        if (state.challenge == null && state.sending)
          const Center(child: CircularProgressIndicator())
        else if (state.challenge == null) ...[
          if (failure != null) StatusBanner(tone: Tone.danger, message: sendCodeMessage(l10n, failure)),
          const SizedBox(height: Space.x4),
          AppButton(label: l10n.otpResend, onPressed: () => unawaited(controller.send())),
        ] else ...[
          OtpBoxes(
            key: ValueKey(state.attempt),
            hasError: failure != null && !state.failedOnSend,
            onChanged: (_) => controller.clearFailure(),
            onCompleted: (code) => unawaited(_confirm(context, ref, code)),
          ),
          const SizedBox(height: Space.x3),
          if (state.verifying)
            Center(child: LoadingDots(color: p.brandStrong))
          else if (failure != null)
            Text(
              state.failedOnSend ? sendCodeMessage(l10n, failure) : codeMessage(l10n, failure),
              style: context.typo.caption.copyWith(color: p.danger),
            ),
          const SizedBox(height: Space.x4),
          if (resendAt != null)
            OtpResendRow(
              resendAt: resendAt,
              resending: state.sending,
              onResend: () => unawaited(controller.send()),
            ),
        ],
      ],
    );
  }
}
