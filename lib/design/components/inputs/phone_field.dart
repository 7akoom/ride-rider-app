import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_env.dart';
import '../../design_context.dart';
import '../../tokens/metrics.dart';
import 'app_text_field.dart';

/// A mobile number field: the country code is fixed (one country per copy of the app)
/// and the number is always written left to right.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// Western, Arabic-Indic and Persian digits are all accepted; the number is
  /// normalized before it is sent. Room is left for separators typed or pasted.
  static const int maxLength = 16;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      error: error,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      fieldDirection: TextDirection.ltr,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9 \-]')),
        LengthLimitingTextInputFormatter(maxLength),
      ],
      prefix: const _DialCode(),
    );
  }
}

class _DialCode extends StatelessWidget {
  const _DialCode();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: Space.x4, end: Space.x2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppEnv.phoneDialCode, style: context.typo.bodyStrong),
          const SizedBox(width: Space.x2),
          Container(width: 1, height: 24, color: context.palette.border),
        ],
      ),
    );
  }
}
