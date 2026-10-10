import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/phone/phone_number.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/trip_draft.dart';
import '../../domain/use_cases/check_passenger.dart';
import 'choose_ride_controller.dart';

/// 14 (light): the ride is for someone else; the captain gets their name and number.
Future<void> showPassengerSheet(BuildContext context, TripDraft draft) => showAppSheet<void>(
      context: context,
      builder: (_) => SingleChildScrollView(child: PassengerSheet(draft: draft)),
    );

class PassengerSheet extends ConsumerStatefulWidget {
  const PassengerSheet({super.key, required this.draft});

  final TripDraft draft;

  @override
  ConsumerState<PassengerSheet> createState() => _PassengerSheetState();
}

class _PassengerSheetState extends ConsumerState<PassengerSheet> {
  late final _current = ref.read(chooseRideControllerProvider(widget.draft)).passenger;
  late final _name = TextEditingController(text: _current?.name ?? '');
  late final _phone = TextEditingController(
    text: PhoneNumber.tryParse(_current?.phone ?? '')?.national ?? '',
  );
  Set<PassengerProblem> _problems = const {};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  ChooseRideController get _controller =>
      ref.read(chooseRideControllerProvider(widget.draft).notifier);

  void _save() {
    switch (checkPassenger(_name.text, _phone.text)) {
      case PassengerOk(:final passenger):
        _controller.setPassenger(passenger);
        Navigator.of(context).pop();
      case PassengerWrong(:final problems):
        setState(() => _problems = problems);
    }
  }

  void _forMe() {
    _controller.setPassenger(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.passengerTitle, onClose: () => Navigator.of(context).pop()),
        Text(
          l10n.passengerExplain,
          style: context.typo.caption.copyWith(color: context.palette.textSecondary),
        ),
        const SizedBox(height: Space.x4),
        AppTextField(
          controller: _name,
          label: l10n.passengerName,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          error: switch (_problems) {
            final p when p.contains(PassengerProblem.nameMissing) => l10n.passengerNameMissing,
            final p when p.contains(PassengerProblem.nameTooLong) => l10n.passengerNameTooLong,
            _ => null,
          },
        ),
        const SizedBox(height: Space.x3),
        PhoneField(
          controller: _phone,
          label: l10n.passengerPhone,
          error: _problems.contains(PassengerProblem.phoneInvalid) ? l10n.passengerPhoneInvalid : null,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: Space.x5),
        AppButton(label: l10n.passengerSave, icon: Icons.check, onPressed: _save),
        if (_current != null) ...[
          const SizedBox(height: Space.x2),
          AppButton(
            label: l10n.passengerForMe,
            variant: AppButtonVariant.text,
            onPressed: _forMe,
          ),
        ],
      ],
    );
  }
}
