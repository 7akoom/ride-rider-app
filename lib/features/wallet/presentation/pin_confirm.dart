import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/error/result.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../domain/entities/wallet_pin.dart';
import '../wallet_providers.dart';
import 'biometric_unlock.dart';
import 'pin_sheet.dart';
import 'wallet_pin_screen.dart';

/// Money leaving the wallet: the PIN's status is read, a PIN is created first when
/// there is none ([needsPin] is said when the rider does not), then the PIN sheet,
/// with the fingerprint when it is on. [submit] gets each PIN.
Future<void> confirmWithPin(
  BuildContext context,
  WidgetRef ref, {
  required String detail,
  required String needsPin,
  required Future<PinSheetOutcome> Function(String pin) submit,
}) async {
  final l10n = context.l10n;
  final status = await ref.read(loadPinStatusProvider).call();

  if (!context.mounted) {
    return;
  }

  final PinStatus pin;

  switch (status) {
    case Ok(:final value):
      pin = value;
    case Err(:final failure):
      showAppToast(context, failure.message(l10n), tone: Tone.danger);

      return;
  }

  if (!pin.isSet) {
    final created = await openWalletPin(context, pin);

    if (!context.mounted) {
      return;
    }

    if (!created) {
      showAppToast(context, needsPin, tone: Tone.warning);

      return;
    }
  }

  final biometric = await biometricUnlockOf(ref, l10n);

  if (!context.mounted) {
    return;
  }

  final now = DateTime.now();
  await showPinSheet(
    context,
    detail: detail,
    lockedUntil: pin.lockedAt(now) ? pin.lockedUntil : null,
    biometric: biometric,
    submit: submit,
  );
}
