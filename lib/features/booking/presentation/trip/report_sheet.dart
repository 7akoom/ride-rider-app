import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/tokens/metrics.dart';
import '../../booking_providers.dart';
import '../../domain/use_cases/stay_safe.dart';

/// What went wrong on the trip, for the safety team. True once it was sent.
Future<bool?> showReportSheet(BuildContext context, String tripId) => showAppSheet<bool>(
      context: context,
      builder: (_) => SingleChildScrollView(child: ReportSheet(tripId: tripId)),
    );

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    setState(() {
      _sending = true;
      _error = null;
    });

    final result = await ref.read(reportSafetyProvider).call(widget.tripId, _text.text);

    if (!mounted) {
      return;
    }

    switch (result) {
      case Ok():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        setState(() {
          _sending = false;
          _error = failure is InvalidInputFailure ? l10n.safetyReportEmpty : failure.message(l10n);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.safetyReportTitle, onClose: () => Navigator.of(context).pop()),
        AppTextField(
          controller: _text,
          hint: l10n.safetyReportField,
          error: _error,
          maxLines: 5,
          autofocus: true,
          inputFormatters: [LengthLimitingTextInputFormatter(ReportSafety.maxText)],
        ),
        const SizedBox(height: Space.x4),
        AppButton(
          label: l10n.safetyReportSend,
          icon: Icons.send_outlined,
          loading: _sending,
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }
}
