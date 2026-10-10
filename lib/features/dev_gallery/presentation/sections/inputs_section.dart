import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../gallery_section.dart';

class InputsSection extends StatefulWidget {
  const InputsSection({super.key});

  @override
  State<InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<InputsSection> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  RiderTab _chip = RiderTab.home;
  String _typed = '';

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  static const String _thousands = '000';
  static const int _maxDigits = 9;

  void _append(String digits) {
    final next = '$_typed$digits';
    if (next.length <= _maxDigits) {
      setState(() => _typed = next);
    }
  }

  void _backspace() {
    if (_typed.isNotEmpty) {
      setState(() => _typed = _typed.substring(0, _typed.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GallerySection(
      title: l10n.gallerySectionInputs,
      children: [
        AppTextField(controller: _name, label: l10n.fieldName, hint: l10n.gallerySampleTitle),
        AppTextField(label: l10n.fieldName, error: l10n.errorInvalidInput),
        PhoneField(controller: _phone, label: l10n.fieldPhone),
        OtpBoxes(onCompleted: (_) {}, autofocus: false),
        OtpBoxes(onCompleted: (_) {}, autofocus: false, hasError: true),
        AppChoiceChips<RiderTab>(
          options: [
            (RiderTab.home, l10n.navHome),
            (RiderTab.activity, l10n.navActivity),
            (RiderTab.account, l10n.navAccount),
          ],
          selected: _chip,
          onSelected: (value) => setState(() => _chip = value),
        ),
        MoneyText(int.tryParse(_typed) ?? 0, style: context.typo.amount),
        NumericKeypad(
          extraKey: _thousands,
          onExtraKey: () => _append(_thousands),
          onDigit: _append,
          onBackspace: _backspace,
        ),
      ],
    );
  }
}
