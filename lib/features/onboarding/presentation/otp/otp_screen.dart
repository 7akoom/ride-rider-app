import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/bidi.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/security/secure_screen.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/values/otp_code.dart';
import '../onboarding_navigation.dart';
import '../sign_in_messages.dart';
import 'otp_controller.dart';
import 'otp_resend_row.dart';

/// 04: the six-digit code. It is checked as soon as the sixth digit is in; a refused
/// code empties the boxes. Screenshots are blocked while it is open.
class OtpScreen extends ConsumerWidget {
  const OtpScreen({super.key, required this.challenge});

  final OtpChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = otpControllerProvider(challenge);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final failure = state.failure;

    Future<void> confirm(String code) async {
      final next = await controller.confirm(code);

      if (next != null && context.mounted) {
        openStep(context, next);
      }
    }

    Future<void> resend() async {
      if (await controller.resend() && context.mounted) {
        showAppToast(context, l10n.otpResent);
      }
    }

    return SecureScreen(
      child: AppScaffold(
        topBar: const AppTopBar(),
        body: ListView(
          children: [
            Text(l10n.otpTitle, style: context.typo.h1),
            const SizedBox(height: Space.x2),
            Text(
              l10n.otpSentTo(isolateLtr(state.challenge.phone.display)),
              style: context.typo.body.copyWith(color: context.palette.textSecondary),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: l10n.otpEditNumber,
                variant: AppButtonVariant.text,
                expand: false,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: Space.x4),
            OtpBoxes(
              key: ValueKey(state.attempt),
              length: OtpCode.length,
              hasError: failure != null && !state.failedOnResend,
              onChanged: (_) => controller.clearFailure(),
              onCompleted: confirm,
            ),
            const SizedBox(height: Space.x4),
            if (state.verifying)
              Center(child: LoadingDots(color: context.palette.brandStrong)),
            if (failure != null)
              StatusBanner(
                tone: Tone.danger,
                message: state.failedOnResend
                    ? sendCodeMessage(l10n, failure)
                    : codeMessage(l10n, failure),
              ),
            const SizedBox(height: Space.x4),
            OtpResendRow(
              resendAt: state.resendAt,
              resending: state.resending,
              onResend: resend,
            ),
          ],
        ),
      ),
    );
  }
}
