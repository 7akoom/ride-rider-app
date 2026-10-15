import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Opens the PIN screen that fits [status]: create one, or change it (a locked PIN
/// offers only the reset). True when a PIN was saved.
Future<bool> openWalletPin(BuildContext context, PinStatus status) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => WalletPinScreen(
        mode: status.isSet ? PinMode.change : PinMode.create,
        lockedUntil: status.lockedAt(DateTime.now()) ? status.lockedUntil : null,
      ),
    ),
  );

  return saved ?? false;
}

/// 38: the wallet PIN that confirms money leaving the wallet: created, changed, or
/// chosen again after a reset.
class WalletPinScreen extends ConsumerStatefulWidget {
  const WalletPinScreen({super.key, required this.mode, this.lockedUntil});

  final PinMode mode;

  /// The PIN was locked already when the screen opened.
  final DateTime? lockedUntil;

  @override
  ConsumerState<WalletPinScreen> createState() => _WalletPinScreenState();
}

class _WalletPinScreenState extends ConsumerState<WalletPinScreen> {
  @override
  void initState() {
    super.initState();
    final locked = widget.lockedUntil;

    if (locked != null) {
      // After the first frame: a provider may not change while the tree builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(walletPinControllerProvider(widget.mode).notifier).startLocked(locked);
        }
      });
    }
  }

  Future<void> _reset() async {
    final navigator = Navigator.of(context);
    final saved = await openPinReset(context);

    if (saved && mounted) {
      navigator.pop(true);
    }
  }

  String _title(AppLocalizations l10n, PinFlow flow) => switch (flow.step) {
        PinStep.current || PinStep.checking => l10n.pinCurrentTitle,
        PinStep.fresh when flow.mode == PinMode.create => l10n.pinCreateTitle,
        PinStep.fresh => l10n.pinNewTitle,
        PinStep.confirm || PinStep.saving => l10n.pinConfirmTitle,
        PinStep.done => l10n.pinSaved,
      };

  String? _problem(AppLocalizations l10n, PinProblem? problem) => switch (problem) {
        null => null,
        WeakPin() => l10n.pinWeak,
        PinMismatch() => l10n.pinMismatch,
        WrongCurrentPin(:final attemptsLeft) => l10n.pinWrongCurrent(attemptsLeft),
        PinLocked(:final until) => l10n.pinLocked(formatClock(l10n, until)),
        PinSignInAgain() => l10n.pinSignInAgain,
        PinFailed(:final failure) => failure.message(l10n),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flow = ref.watch(walletPinControllerProvider(widget.mode));
    final controller = ref.read(walletPinControllerProvider(widget.mode).notifier);

    if (flow.step == PinStep.done) {
      return AppScaffold(
        topBar: AppTopBar(title: l10n.walletPinRow, showBack: false),
        body: _PinSaved(onDone: () => Navigator.of(context).pop(true)),
      );
    }

    final problem = _problem(l10n, flow.problem);
    // A forgotten PIN is reset by signing in again: offered where the current PIN is
    // asked for, and as the only way on once it is locked.
    final offerReset = flow.step == PinStep.current || flow.stuck;

    return AppScaffold(
      topBar: AppTopBar(title: l10n.walletPinRow),
      // Fills the screen, and scrolls instead of overflowing when it is short (a
      // small phone, large text).
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x6),
                      child: Column(
                        children: [
                          Icon(Icons.shield_outlined, size: Sizes.heroIcon, color: context.palette.brandStrong),
                          const SizedBox(height: Space.x4),
                          Semantics(
                            header: true,
                            child: Text(_title(l10n, flow), textAlign: TextAlign.center, style: context.typo.h2),
                          ),
                          const SizedBox(height: Space.x2),
                          Text(
                            l10n.pinCreateBody,
                            textAlign: TextAlign.center,
                            style: context.typo.body.copyWith(color: context.palette.textSecondary),
                          ),
                          if (flow.busy) ...[
                            const SizedBox(height: Space.x4),
                            LoadingDots(color: context.palette.brandStrong),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (flow.stuck) ...[
                    StatusBanner(tone: Tone.danger, message: problem ?? ''),
                    const SizedBox(height: Space.x4),
                    AppButton(label: l10n.pinForgot, onPressed: _reset),
                    const SizedBox(height: Space.x4),
                  ] else ...[
                    PinPad(
                      typed: flow.typed.length,
                      error: problem,
                      enabled: !flow.busy,
                      onDigit: controller.digit,
                      onBackspace: controller.backspace,
                    ),
                    if (offerReset)
                      AppButton(label: l10n.pinForgot, variant: AppButtonVariant.text, onPressed: _reset)
                    else
                      const SizedBox(height: Sizes.buttonHeight),
                    const SizedBox(height: Space.x2),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinSaved extends StatelessWidget {
  const _PinSaved({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: Sizes.hero,
                  height: Sizes.hero,
                  decoration: BoxDecoration(color: p.successSoft, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: Sizes.heroIcon, color: p.success),
                ),
                const SizedBox(height: Space.x6),
                Semantics(
                  header: true,
                  child: Text(l10n.pinSaved, textAlign: TextAlign.center, style: context.typo.h2),
                ),
                const SizedBox(height: Space.x2),
                Text(
                  l10n.pinSavedBody,
                  textAlign: TextAlign.center,
                  style: context.typo.body.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AppButton(label: l10n.pinDone, onPressed: onDone),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}
