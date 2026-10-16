import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/format/bidi.dart';
import '../../../core/format/money_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/share/share_text.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/money_request.dart';

String requestStatusLabel(AppLocalizations l10n, MoneyRequestStatus status) => switch (status) {
      MoneyRequestStatus.pending => l10n.requestStatusPending,
      MoneyRequestStatus.paid => l10n.requestStatusPaid,
      MoneyRequestStatus.declined => l10n.requestStatusDeclined,
      MoneyRequestStatus.cancelled => l10n.requestStatusCancelled,
      MoneyRequestStatus.expired => l10n.requestStatusExpired,
    };

Tone requestStatusTone(MoneyRequestStatus status) => switch (status) {
      MoneyRequestStatus.pending => Tone.warning,
      MoneyRequestStatus.paid => Tone.success,
      MoneyRequestStatus.declined => Tone.danger,
      MoneyRequestStatus.cancelled || MoneyRequestStatus.expired => Tone.info,
    };

/// A date and a time: "16/10/2026 · 14:30".
String requestTime(AppLocalizations l10n, DateTime at) => '${formatDate(l10n, at)} · ${formatClock(l10n, at)}';

/// The other side's name: whom the rider asked, or who asks the rider.
String counterpartName(AppLocalizations l10n, MoneyRequest request) {
  final name = request.role == MoneyRequestRole.requester ? request.payerName : request.requesterName;

  return name.isEmpty ? l10n.requestSomeone : name;
}

/// The other side's phone as the server gave it (a viewer's is masked), for showing.
String counterpartPhone(MoneyRequest request) {
  final raw = request.role == MoneyRequestRole.requester ? request.payerPhone : request.requesterPhone;
  final phone = PhoneNumber.tryParse(raw);

  return raw.isEmpty ? '' : isolateLtr(phone?.display ?? raw);
}

/// "Haidar K. asks you", "You asked Sara A.", or "Open link".
String requestHeadline(AppLocalizations l10n, MoneyRequest request) {
  if (request.role == MoneyRequestRole.requester) {
    return request.open && request.payerName.isEmpty
        ? l10n.requestKindOpen
        : l10n.requestTo(counterpartName(l10n, request));
  }

  return l10n.requestFrom(counterpartName(l10n, request));
}

/// When it ends (pending), or when it was paid or closed; null when the server did
/// not say (an expired one ended at its end).
String? requestWhen(AppLocalizations l10n, MoneyRequest request) {
  final closed = request.closedAt;

  return switch (request.status) {
    MoneyRequestStatus.pending => l10n.requestValidUntil(requestTime(l10n, request.expiresAt)),
    MoneyRequestStatus.expired => l10n.requestClosedAt(requestTime(l10n, request.expiresAt)),
    _ => closed == null ? null : l10n.requestClosedAt(requestTime(l10n, closed)),
  };
}

/// The status as a small pill.
class RequestStatusPill extends StatelessWidget {
  const RequestStatusPill({super.key, required this.status});

  final MoneyRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tone = requestStatusTone(status);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x2, vertical: Space.x1 / 2),
      decoration: BoxDecoration(
        color: tone.background(p),
        borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
      ),
      child: Text(
        requestStatusLabel(context.l10n, status),
        style: context.typo.micro.copyWith(color: tone.foreground(p)),
      ),
    );
  }
}

/// One request in a list: who, its status and end, and the amount.
class MoneyRequestRow extends StatelessWidget {
  const MoneyRequestRow({super.key, required this.request, required this.onTap});

  final MoneyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final incoming = request.role != MoneyRequestRole.requester;
    final ends = requestWhen(l10n, request);
    final about = [if (request.note.isNotEmpty) request.note, if (ends != null) ends].join(' · ');

    return AppListRow(
      // Paying what is asked of the rider sends money out; their own requests bring it in.
      icon: request.open && !incoming ? Icons.qr_code_2 : (incoming ? Icons.north_east : Icons.south_west),
      title: requestHeadline(l10n, request),
      subtitle: about.isEmpty ? null : about,
      onTap: onTap,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatMoney(l10n, request.amount), style: context.typo.bodyStrong.copyWith(color: p.textPrimary)),
          const SizedBox(height: Space.x1),
          RequestStatusPill(status: request.status),
        ],
      ),
    );
  }
}

/// An open request to show and share: the QR code (it carries the code), the code
/// in two groups, until when it may be paid, "share" and "copy".
class RequestQrCard extends ConsumerWidget {
  const RequestQrCard({super.key, required this.request});

  final MoneyRequest request;

  /// The QR code's side; it stays black on white in both themes, so any scanner
  /// reads it.
  static const double qrSize = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final until = requestTime(l10n, request.expiresAt);

    return Container(
      padding: const EdgeInsets.all(Space.x4),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(Space.x3),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(Radii.input)),
              ),
              child: Semantics(
                label: l10n.requestCode,
                child: QrImageView(data: request.code, size: qrSize, padding: EdgeInsets.zero),
              ),
            ),
          ),
          const SizedBox(height: Space.x4),
          Text(l10n.requestCode, textAlign: TextAlign.center, style: context.typo.caption.copyWith(color: p.textSecondary)),
          const SizedBox(height: Space.x1),
          SelectableText(
            isolateLtr(request.displayCode),
            textAlign: TextAlign.center,
            style: context.typo.h2.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: Space.x1),
          Text(
            l10n.requestValidUntil(until),
            textAlign: TextAlign.center,
            style: context.typo.caption.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Space.x4),
          AppButton(
            label: l10n.requestShare,
            icon: Icons.ios_share,
            onPressed: () => unawaited(
              ref.read(shareTextProvider)(
                l10n.requestShareText(formatMoney(l10n, request.amount), isolateLtr(request.displayCode), until),
              ),
            ),
          ),
          const SizedBox(height: Space.x2),
          AppButton(
            label: l10n.requestCopyCode,
            icon: Icons.copy_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: request.code));

              if (context.mounted) {
                showAppToast(context, l10n.requestCodeCopied);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// A label and its value on one line.
class RequestLine extends StatelessWidget {
  const RequestLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x2),
      child: Row(
        children: [
          Text(label, style: context.typo.caption.copyWith(color: context.palette.textSecondary)),
          const SizedBox(width: Space.x3),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: context.typo.bodyStrong)),
        ],
      ),
    );
  }
}

/// The other side: an avatar, the name and the phone.
class RequestPersonCard extends StatelessWidget {
  const RequestPersonCard({super.key, required this.name, required this.phone, this.trailing});

  final String name;
  final String phone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(Space.x4),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
      ),
      child: Row(
        children: [
          AppAvatar(name: name),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.typo.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (phone.isNotEmpty) Text(phone, style: context.typo.caption.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
