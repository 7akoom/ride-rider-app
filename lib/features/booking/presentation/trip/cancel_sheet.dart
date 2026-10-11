import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/cancellation.dart';

/// 23: why the rider cancels a ride a captain took. Null when they keep the ride.
Future<Cancellation?> showCancelSheet(BuildContext context) => showAppSheet<Cancellation>(
      context: context,
      builder: (_) => const SingleChildScrollView(child: CancelSheet()),
    );

class CancelSheet extends StatefulWidget {
  const CancelSheet({super.key});

  @override
  State<CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<CancelSheet> {
  CancelReason? _reason;
  final _text = TextEditingController();
  bool _missing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _choose(CancelReason reason) => setState(() {
        _reason = reason;
        _missing = false;
      });

  void _cancel() {
    final reason = _reason;
    final why = reason == null ? null : Cancellation.of(reason, _text.text);

    if (why == null) {
      setState(() => _missing = true);
      return;
    }

    Navigator.of(context).pop(why);
  }

  static String _label(AppLocalizations l10n, CancelReason reason) => switch (reason) {
        CancelReason.captainLate => l10n.cancelReasonLate,
        CancelReason.changedMind => l10n.cancelReasonChangedMind,
        CancelReason.orderedByMistake => l10n.cancelReasonMistake,
        CancelReason.captainAsked => l10n.cancelReasonCaptainAsked,
        CancelReason.other => l10n.cancelReasonOther,
      };

  static IconData _icon(CancelReason reason) => switch (reason) {
        CancelReason.captainLate => Icons.schedule,
        CancelReason.changedMind => Icons.sync_alt,
        CancelReason.orderedByMistake => Icons.touch_app_outlined,
        CancelReason.captainAsked => Icons.call_outlined,
        CancelReason.other => Icons.edit_note,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.cancelWhyTitle, onClose: () => Navigator.of(context).pop()),
        for (final reason in CancelReason.values)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Space.x2),
            child: AppRadioTile(
              title: _label(l10n, reason),
              leading: Icon(_icon(reason)),
              selected: _reason == reason,
              onTap: () => _choose(reason),
            ),
          ),
        if (_reason == CancelReason.other)
          AppTextField(
            controller: _text,
            hint: l10n.cancelOtherHint,
            error: _missing ? l10n.cancelOtherEmpty : null,
            maxLines: 3,
            autofocus: true,
            inputFormatters: [LengthLimitingTextInputFormatter(Cancellation.maxText)],
          ),
        const SizedBox(height: Space.x3),
        StatusBanner(tone: Tone.warning, message: l10n.tripCancelBody),
        const SizedBox(height: Space.x4),
        AppButton(
          label: l10n.tripCancel,
          icon: Icons.close,
          variant: AppButtonVariant.danger,
          onPressed: _reason == null ? null : _cancel,
        ),
        const SizedBox(height: Space.x2),
        AppButton(
          label: l10n.cancelBack,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
