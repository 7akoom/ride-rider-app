import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// One-time code entry: [length] boxes, always left to right, backed by one invisible
/// text field so the system keyboard, paste and SMS autofill all work.
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    required this.onCompleted,
    this.length = 6,
    this.hasError = false,
    this.onChanged,
    this.autofocus = true,
  });

  final int length;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_refresh);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    widget.onChanged?.call(value);

    if (value.length == widget.length) {
      widget.onCompleted(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: Space.x2),
                Expanded(
                  child: _Box(
                    digit: i < code.length ? code[i] : null,
                    active: _focus.hasFocus && i == code.length,
                    hasError: widget.hasError,
                  ),
                ),
              ],
            ],
          ),
          // The real input, invisible on top of the boxes: taps, the keyboard, paste
          // and SMS autofill all go to it.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: _changed,
                showCursor: false,
                decoration: const InputDecoration.collapsed(hintText: null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.digit, required this.active, required this.hasError});

  final String? digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderColor = hasError
        ? p.danger
        : active
            ? p.brandStrong
            : p.surface2;

    return AspectRatio(
      aspectRatio: 0.85,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? p.brandSoft : p.surface2,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.input)),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(digit ?? '', style: context.typo.h2),
      ),
    );
  }
}
