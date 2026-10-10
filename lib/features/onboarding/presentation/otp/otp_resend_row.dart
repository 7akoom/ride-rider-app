import 'package:flutter/material.dart';

import '../../../../core/format/bidi.dart';
import '../../../../core/format/duration_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';

/// "Resend in 0:43" until a new code may be asked for, then the "Resend code" button.
class OtpResendRow extends StatelessWidget {
  const OtpResendRow({
    super.key,
    required this.resendAt,
    required this.resending,
    required this.onResend,
  });

  final DateTime resendAt;
  final bool resending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: CountdownBuilder(
        until: resendAt,
        builder: (context, remaining) {
          if (remaining == Duration.zero) {
            return AppButton(
              label: l10n.otpResend,
              variant: AppButtonVariant.text,
              expand: false,
              loading: resending,
              onPressed: onResend,
            );
          }

          return Text(
            l10n.otpResendIn(isolateLtr(formatCountdown(remaining))),
            style: context.typo.caption.copyWith(color: context.palette.textSecondary),
          );
        },
      ),
    );
  }
}
