import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// A labelled text field: the label above, the field, then the error or helper text.
///
/// [fieldDirection] forces the field's own direction (phone numbers, codes and amounts
/// are left-to-right in every language) while the label follows the app's language.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.fieldDirection,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? error;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextDirection? fieldDirection;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: obscureText ? 1 : maxLines,
      style: context.typo.body,
      decoration: InputDecoration(
        hintText: hint,
        helperText: helper,
        errorText: error,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: context.typo.caption.copyWith(
            color: context.palette.textSecondary,
          )),
          const SizedBox(height: Space.x2),
        ],
        if (fieldDirection == null)
          field
        else
          Directionality(textDirection: fieldDirection!, child: field),
      ],
    );
  }
}
