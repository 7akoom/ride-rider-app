import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/format/time_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/wallet_pin.dart';
import 'pin_pad.dart';
import 'pin_reset_screen.dart';
import 'wallet_pin_controller.dart';

/// What the sheet's owner made of a typed PIN.
sealed class PinSheetOutcome {
  const PinSheetOutcome();
}

/// Done: the sheet closes with true.
final class PinAccepted extends PinSheetOutcome {
  const PinAccepted();
}

/// The PIN was not taken: the sheet stays and says why (a wrong PIN, a lock, no
/// connection), and the rider types again or resets it.
final class PinRefused extends PinSheetOutcome {
  const PinRefused(this.problem);

  final PinProblem problem;
}

/// Something the PIN cannot fix (the balance, a limit): the sheet closes with false
/// and its owner says what.
final class PinSheetClosed extends PinSheetOutcome {
  const PinSheetClosed();
}

/// 35: confirms money leaving the wallet with the PIN. [submit] gets each PIN typed;
/// true when it was accepted. [lockedUntil] opens it on a locked PIN.
Future<bool> showPinSheet(
  BuildContext context, {
  required String detail,
  required Future<PinSheetOutcome> Function(String pin) submit,
  DateTime? lockedUntil,
}) async {
  final accepted = await showAppSheet<bool>(
    context: context,
    builder: (_) => PinSheet(detail: detail, submit: submit, lockedUntil: lockedUntil),
  );

  return accepted ?? false;
}

class PinSheet extends StatefulWidget {
  const PinSheet({super.key, required this.detail, required this.submit, this.lockedUntil});

  /// What the PIN confirms ("5,000 IQD to Haidar K.").
  final String detail;
  final Future<PinSheetOutcome> Function(String pin) submit;
  final DateTime? lockedUntil;

  @override
  State<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<PinSheet> {
  String _typed = '';
  bool _busy = false;
  PinProblem? _problem;

  @override
  void initState() {
    super.initState();
    final locked = widget.lockedUntil;

    if (locked != null) {
      _problem = PinLocked(locked);
    }
  }

  bool get _locked => _problem is PinLocked;

  void _digit(String digit) {
    if (_busy || _locked || _typed.length >= WalletPin.length) {
      return;
    }

    setState(() {
      // A new PIN after a refusal: the message goes once the rider types again.
      if (_typed.isEmpty) {
        _problem = null;
      }
      _typed = '$_typed$digit';
    });

    if (_typed.length == WalletPin.length) {
      unawaited(_submit(_typed));
    }
  }

  void _backspace() {
    if (_busy || _typed.isEmpty) {
      return;
    }

    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  Future<void> _submit(String pin) async {
    setState(() => _busy = true);
    final outcome = await widget.submit(pin);

    if (!mounted) {
      return;
    }

    switch (outcome) {
      case PinAccepted():
        Navigator.of(context).pop(true);
      case PinSheetClosed():
        Navigator.of(context).pop(false);
      case PinRefused(:final problem):
        setState(() {
          _busy = false;
          _typed = '';
          _problem = problem;
        });
    }
  }

  Future<void> _reset() async {
    final saved = await openPinReset(context);

    if (saved && mounted) {
      // A new PIN: the rider types it here to go on.
      setState(() {
        _problem = null;
        _typed = '';
      });
    }
  }

  String? _message(AppLocalizations l10n) => switch (_problem) {
        null => null,
        WrongCurrentPin(:final attemptsLeft) => l10n.pinWrongCurrent(attemptsLeft),
        PinLocked(:final until) => l10n.pinLocked(formatClock(l10n, until)),
        PinFailed(:final failure) => failure.message(l10n),
        WeakPin() || PinMismatch() || PinSignInAgain() => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = _message(l10n);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(title: l10n.pinSheetTitle, onClose: _busy ? null : () => Navigator.of(context).pop(false)),
          Text(widget.detail, style: context.typo.body.copyWith(color: context.palette.textSecondary)),
          const SizedBox(height: Space.x4),
          if (_locked) ...[
            StatusBanner(tone: Tone.danger, message: message ?? ''),
            const SizedBox(height: Space.x4),
            AppButton(label: l10n.pinForgot, onPressed: _reset),
          ] else ...[
            PinPad(
              typed: _typed.length,
              error: message,
              enabled: !_busy,
              onDigit: _digit,
              onBackspace: _backspace,
            ),
            if (_busy)
              SizedBox(height: Sizes.buttonHeight, child: Center(child: LoadingDots(color: context.palette.brandStrong)))
            else
              AppButton(label: l10n.pinForgot, variant: AppButtonVariant.text, onPressed: _reset),
          ],
        ],
      ),
    );
  }
}
