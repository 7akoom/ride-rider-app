import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/share/share_text.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../booking_providers.dart';
import 'report_sheet.dart';

/// 21: the safety centre of a trip. True when the alarm went to the safety team (the
/// trip screen then says so).
Future<bool?> showSafetySheet(BuildContext context, String tripId) => showAppSheet<bool>(
      context: context,
      builder: (_) => SingleChildScrollView(child: SafetySheet(tripId: tripId)),
    );

/// The trip has live links (made in this run of the app): stopping them is offered.
final sharingTripProvider = StateProvider.family<bool, String>((ref, tripId) => false);

class SafetySheet extends ConsumerStatefulWidget {
  const SafetySheet({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<SafetySheet> createState() => _SafetySheetState();
}

class _SafetySheetState extends ConsumerState<SafetySheet> {
  bool _busy = false;
  bool _alarming = false;

  /// What the last action came to, in the sheet itself (a toast would hide under it).
  (Tone, String)? _note;

  void _show(Tone tone, String message) => setState(() => _note = (tone, message));

  Future<void> _share() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await ref.read(shareTripProvider).call(widget.tripId);

    if (!mounted) {
      return;
    }

    setState(() => _busy = false);
    switch (result) {
      case Ok(value: final url?):
        ref.read(sharingTripProvider(widget.tripId).notifier).state = true;
        await ref.read(shareTextProvider)(l10n.safetyShareMessage(url));
      case Ok():
        _show(Tone.warning, l10n.safetyShareUnavailable);
      case Err(:final failure):
        _show(Tone.danger, failure.message(l10n));
    }
  }

  Future<void> _stop() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await ref.read(stopSharingProvider).call(widget.tripId);

    if (!mounted) {
      return;
    }

    setState(() => _busy = false);
    switch (result) {
      case Ok():
        ref.read(sharingTripProvider(widget.tripId).notifier).state = false;
        _show(Tone.info, l10n.safetyStopped);
      case Err(:final failure):
        _show(Tone.danger, failure.message(l10n));
    }
  }

  Future<void> _report() async {
    final sent = await showReportSheet(context, widget.tripId);

    if (sent == true && mounted) {
      _show(Tone.success, context.l10n.safetyReportSent);
    }
  }

  Future<void> _alarm() async {
    final l10n = context.l10n;
    final yes = await confirmSheet(
      context,
      title: l10n.safetySosConfirmTitle,
      message: l10n.safetySosConfirmBody,
      confirmLabel: l10n.safetySosConfirmYes,
      keepLabel: l10n.actionCancel,
    );

    if (!yes || !mounted) {
      return;
    }

    setState(() => _alarming = true);
    final result = await ref.read(raiseAlarmProvider).call(widget.tripId);

    if (!mounted) {
      return;
    }

    setState(() => _alarming = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        _show(Tone.danger, failure.message(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final note = _note;
    final sharing = ref.watch(sharingTripProvider(widget.tripId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.safetyTitle, onClose: () => Navigator.of(context).pop()),
        if (note != null) ...[
          StatusBanner(tone: note.$1, message: note.$2),
          const SizedBox(height: Space.x3),
        ],
        AppListRow(
          icon: Icons.share_location,
          title: l10n.safetyShare,
          subtitle: l10n.safetyShareHint,
          trailing: _busy ? LoadingDots(color: p.brandStrong) : null,
          onTap: _busy ? null : _share,
        ),
        if (sharing)
          AppListRow(
            icon: Icons.link_off,
            title: l10n.safetyStopShare,
            subtitle: l10n.safetyStopShareHint,
            onTap: _busy ? null : _stop,
          ),
        AppListRow(
          icon: Icons.report_outlined,
          title: l10n.safetyReport,
          subtitle: l10n.safetyReportHint,
          onTap: _report,
        ),
        const SizedBox(height: Space.x4),
        Container(
          padding: const EdgeInsetsDirectional.all(Space.x4),
          decoration: BoxDecoration(
            color: p.dangerSoft,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.safetySosTitle, style: context.typo.h3.copyWith(color: p.danger)),
              const SizedBox(height: Space.x1),
              Text(l10n.safetySosBody, style: context.typo.body),
              const SizedBox(height: Space.x4),
              AppButton(
                label: l10n.safetySosSend,
                icon: Icons.notifications_active_outlined,
                variant: AppButtonVariant.danger,
                loading: _alarming,
                onPressed: _alarming ? null : _alarm,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
