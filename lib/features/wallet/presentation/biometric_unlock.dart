import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../domain/entities/biometric.dart';
import '../domain/entities/wallet_pin.dart';
import '../wallet_providers.dart';
import 'pin_sheet.dart';
import 'wallet_pin_controller.dart';
import 'wallet_state.dart';

/// The PIN sheet's way to the kept PIN: the phone's prompt, then the PIN.
final class BiometricUnlock {
  const BiometricUnlock({required this.kind, required this.unlock, required this.keep});

  final BiometricKind kind;

  /// The kept PIN once the phone confirmed the rider; null when it did not.
  final Future<String?> Function() unlock;

  /// Keeps a PIN the rider typed and the server took (it changed elsewhere).
  final Future<void> Function(String pin) keep;
}

/// The unlock for a payment's PIN sheet; null when paying this way is off.
Future<BiometricUnlock?> biometricUnlockOf(WidgetRef ref, AppLocalizations l10n) async {
  final biometric = ref.read(biometricPinProvider);
  final kind = await biometric.available();

  if (kind == null || await biometric.kept() == null) {
    return null;
  }

  return BiometricUnlock(
    kind: kind,
    unlock: () async {
      if (!await biometric.confirm(l10n.biometricPayReason)) {
        return null;
      }

      return biometric.kept();
    },
    keep: biometric.keep,
  );
}

/// The wallet's switch: on takes the PIN once (checked by the server) and the phone's
/// prompt; off forgets the kept PIN.
Future<void> switchBiometric(BuildContext context, WidgetRef ref, {required bool on, PinStatus? pin}) async {
  final l10n = context.l10n;
  final biometric = ref.read(biometricPinProvider);

  if (!on) {
    await biometric.forget();
    ref.invalidate(biometricProvider);

    if (context.mounted) {
      showAppToast(context, l10n.biometricOff, tone: Tone.info);
    }

    return;
  }

  var confirmed = true;
  final now = DateTime.now();
  final accepted = await showPinSheet(
    context,
    detail: l10n.biometricEnableDetail,
    lockedUntil: pin != null && pin.lockedAt(now) ? pin.lockedUntil : null,
    submit: (typed) async {
      final check = await ref.read(verifyWalletPinProvider).call(typed);

      switch (check) {
        case Ok(value: PinCheck(result: PinCheckResult.ok)):
          if (!await biometric.confirm(l10n.biometricEnableReason)) {
            confirmed = false;

            return const PinSheetClosed();
          }

          await biometric.keep(typed);

          return const PinAccepted();

        case Ok(value: PinCheck(result: PinCheckResult.wrong, :final attemptsLeft)):
          ref.invalidate(pinStatusProvider);

          return PinRefused(WrongCurrentPin(attemptsLeft));

        case Ok(value: PinCheck(result: PinCheckResult.locked, :final lockedUntil)):
          ref.invalidate(pinStatusProvider);

          return PinRefused(PinLocked(lockedUntil ?? DateTime.now().add(const Duration(minutes: 15))));

        // No PIN any more (reset elsewhere): the wallet's PIN row says so.
        case Ok(value: PinCheck(result: PinCheckResult.notSet)):
          ref.invalidate(pinStatusProvider);

          return const PinSheetClosed();

        case Err(:final failure):
          return PinRefused(PinFailed(failure));
      }
    },
  );

  ref.invalidate(biometricProvider);

  if (!context.mounted) {
    return;
  }

  if (accepted) {
    showAppToast(context, l10n.biometricOn);
  } else if (!confirmed) {
    showAppToast(context, l10n.biometricNotConfirmed, tone: Tone.warning);
  }
}
