import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/format/bidi.dart';
import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/phone/phone_number.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/money_request.dart';
import '../domain/entities/transfer.dart';
import '../domain/use_cases/send_money.dart';
import 'amount_choice.dart';
import 'contact_picker.dart';
import 'request_money_controller.dart';
import 'request_widgets.dart';

Future<void> openRequestMoney(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RequestMoneyScreen()));

/// 37: ask for money: the amount, then a rider by phone or an open link (a QR code
/// and a code to share).
class RequestMoneyScreen extends ConsumerStatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  ConsumerState<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends ConsumerState<RequestMoneyScreen> {
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  RequestMoneyController get _controller => ref.read(requestMoneyControllerProvider.notifier);

  Future<void> _pickContact() async {
    List<String>? numbers;

    try {
      numbers = await ref.read(pickContactNumbersProvider)();
    } catch (_) {
      numbers = null;
    }

    if (!mounted || numbers == null) {
      return;
    }

    // The first of the contact's numbers that is an Iraqi mobile.
    final phone = numbers.map(PhoneNumber.tryParse).whereType<PhoneNumber>().firstOrNull;

    if (phone == null) {
      showAppToast(context, context.l10n.sendContactNoNumber, tone: Tone.warning);
    } else {
      _phone.text = phone.national;
      _controller.phoneTyped(phone.e164);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flow = ref.watch(requestMoneyControllerProvider);
    final created = flow.created;

    if (flow.step == RequestStep.done && created != null) {
      return AppScaffold(
        topBar: AppTopBar(title: l10n.requestTitle, showBack: false),
        body: _CreatedView(request: created),
      );
    }

    return PopScope(
      // Back goes one step back, not out of the flow.
      canPop: flow.step == RequestStep.amount,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _controller.back();
        }
      },
      child: AppScaffold(
        topBar: AppTopBar(title: l10n.requestTitle),
        body: switch (flow.step) {
          RequestStep.amount => _AmountView(
              flow: flow,
              onAmount: _controller.setAmount,
              onNote: _controller.noteChanged,
              onRetryLoad: () => unawaited(_controller.load()),
              onContinue: _controller.toWho,
            ),
          _ => _WhoView(
              flow: flow,
              phone: _phone,
              onKind: _controller.chooseKind,
              onChanged: _controller.phoneTyped,
              onPickContact: _pickContact,
              onRetry: _controller.retryLookup,
              onCreate: () => unawaited(_controller.create()),
            ),
        },
      ),
    );
  }
}

class _AmountView extends StatefulWidget {
  const _AmountView({
    required this.flow,
    required this.onAmount,
    required this.onNote,
    required this.onRetryLoad,
    required this.onContinue,
  });

  final RequestFlow flow;
  final ValueChanged<int> onAmount;
  final ValueChanged<String> onNote;
  final VoidCallback onRetryLoad;
  final VoidCallback onContinue;

  static const List<int> amounts = [1000, 3000, 5000, 10000, 25000];

  @override
  State<_AmountView> createState() => _AmountViewState();
}

class _AmountViewState extends State<_AmountView> {
  // The note stays as typed when the rider goes on and back.
  late final TextEditingController _note = TextEditingController(text: widget.flow.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String? _problemOf(AppLocalizations l10n, TransferOptions options, int amount) {
    if (amount < options.min) {
      return l10n.requestTooSmall(formatMoney(l10n, options.min));
    }

    return amount > options.max ? l10n.requestTooBig(formatMoney(l10n, options.max)) : null;
  }

  String _limits(AppLocalizations l10n, TransferOptions options) =>
      l10n.requestLimits(formatMoney(l10n, options.min), formatMoney(l10n, options.max));

  Future<void> _other(TransferOptions options) async {
    final l10n = context.l10n;
    final amount = await showAmountSheet(
      context,
      initial: _AmountView.amounts.contains(widget.flow.amount) ? 0 : widget.flow.amount,
      hint: _limits(l10n, options),
      problemOf: (amount) => _problemOf(l10n, options, amount),
    );

    if (amount != null) {
      widget.onAmount(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final flow = widget.flow;
    final options = flow.options;

    if (options == null) {
      final failure = flow.loadFailure;

      return failure == null
          ? Center(child: LoadingDots(color: p.brandStrong))
          : FailureView(failure: failure, onRetry: widget.onRetryLoad);
    }

    final problem = flow.amount == 0 ? null : _problemOf(l10n, options, flow.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: Space.x2),
              Text(l10n.requestAmountTitle, style: t.h2),
              const SizedBox(height: Space.x6),
              Semantics(
                liveRegion: true,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatMoney(l10n, flow.amount),
                      style: t.display.copyWith(color: flow.amount == 0 ? p.textTertiary : p.textPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.x1),
              Text(
                problem ?? _limits(l10n, options),
                textAlign: TextAlign.center,
                style: t.caption.copyWith(color: problem != null ? p.danger : p.textSecondary),
              ),
              const SizedBox(height: Space.x6),
              AmountChoice(
                amounts: _AmountView.amounts,
                selected: flow.amount,
                allowed: (amount) => _problemOf(l10n, options, amount) == null,
                onSelected: widget.onAmount,
                onOther: () => unawaited(_other(options)),
              ),
              const SizedBox(height: Space.x4),
              AppTextField(
                controller: _note,
                hint: l10n.sendNote,
                prefix: const Icon(Icons.notes_outlined),
                textInputAction: TextInputAction.done,
                inputFormatters: [LengthLimitingTextInputFormatter(SendMoney.maxNote)],
                onChanged: widget.onNote,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        AppButton(label: l10n.sendContinue, onPressed: flow.amountReady ? widget.onContinue : null),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}

class _WhoView extends StatelessWidget {
  const _WhoView({
    required this.flow,
    required this.phone,
    required this.onKind,
    required this.onChanged,
    required this.onPickContact,
    required this.onRetry,
    required this.onCreate,
  });

  final RequestFlow flow;
  final TextEditingController phone;
  final ValueChanged<RequestKind> onKind;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickContact;
  final VoidCallback onRetry;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final amount = formatMoney(l10n, flow.amount);
    final recipient = flow.recipient;
    final lookupFailure = flow.lookupFailure;
    final createFailure = flow.createFailure;

    final Widget? answer = switch (recipient?.result) {
      _ when flow.lookingUp => Center(child: LoadingDots(color: p.brandStrong)),
      RecipientResult.found => RequestPersonCard(
          name: recipient!.name.isEmpty ? l10n.requestSomeone : recipient.name,
          phone: isolateLtr(recipient.phone.display),
          trailing: Icon(Icons.verified_outlined, color: p.success),
        ),
      RecipientResult.notFound => StatusBanner(tone: Tone.warning, message: l10n.requestNotRegistered),
      RecipientResult.self => StatusBanner(tone: Tone.warning, message: l10n.requestSelf),
      null when lookupFailure != null => StatusBanner(
          tone: Tone.danger,
          message: lookupFailure is RateLimitedFailure ? l10n.sendLookupTooMany : lookupFailure.message(l10n),
          actionLabel: lookupFailure is RateLimitedFailure ? null : l10n.actionRetry,
          onAction: lookupFailure is RateLimitedFailure ? null : onRetry,
        ),
      null => null,
    };

    final String? createMessage = switch (createFailure) {
      null => null,
      NotFoundFailure() => l10n.requestGone,
      RateLimitedFailure() => l10n.sendLookupTooMany,
      InvalidInputFailure() || PreconditionFailure() => l10n.requestNotCreated,
      final Failure failure => failure.message(l10n),
    };

    final open = flow.kind == RequestKind.open;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: Space.x2),
              Text(l10n.requestWhoTitle, style: context.typo.h2),
              const SizedBox(height: Space.x1),
              Text(
                flow.note.trim().isEmpty ? amount : '$amount · ${flow.note.trim()}',
                style: context.typo.body.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Space.x4),
              AppChoiceChips<RequestKind>(
                options: [
                  (RequestKind.person, l10n.requestKindPerson),
                  (RequestKind.open, l10n.requestKindOpen),
                ],
                selected: flow.kind,
                onSelected: onKind,
              ),
              const SizedBox(height: Space.x4),
              if (createMessage != null) ...[
                StatusBanner(tone: Tone.danger, message: createMessage),
                const SizedBox(height: Space.x4),
              ],
              if (open)
                StatusBanner(tone: Tone.info, message: l10n.requestOpenBody)
              else ...[
                PhoneField(controller: phone, label: l10n.requestPhoneLabel, onChanged: onChanged),
                const SizedBox(height: Space.x2),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PillButton(icon: Icons.contacts_outlined, label: l10n.sendPickContact, onPressed: onPickContact),
                ),
                if (answer != null) ...[
                  const SizedBox(height: Space.x4),
                  answer,
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        AppButton(
          label: open ? l10n.requestCreateOpen(amount) : l10n.requestCreate(amount),
          icon: open ? Icons.qr_code_2 : Icons.south_west,
          loading: flow.creating,
          onPressed: flow.canCreate ? onCreate : null,
        ),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}

/// The request is made: for a rider, who was asked; for an open one, its QR code
/// and code to share.
class _CreatedView extends StatelessWidget {
  const _CreatedView({required this.request});

  final MoneyRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final amount = formatMoney(l10n, request.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
            children: [
              if (request.open) ...[
                Semantics(
                  header: true,
                  child: Text(l10n.requestOpenTitle(amount), textAlign: TextAlign.center, style: context.typo.h2),
                ),
                if (request.note.isNotEmpty) ...[
                  const SizedBox(height: Space.x1),
                  Text(
                    request.note,
                    textAlign: TextAlign.center,
                    style: context.typo.body.copyWith(color: p.textSecondary),
                  ),
                ],
                const SizedBox(height: Space.x4),
                RequestQrCard(request: request),
                const SizedBox(height: Space.x3),
                Text(
                  l10n.requestOpenHow,
                  textAlign: TextAlign.center,
                  style: context.typo.caption.copyWith(color: p.textSecondary),
                ),
              ] else ...[
                const SizedBox(height: Space.x4),
                Center(
                  child: Container(
                    width: Sizes.hero,
                    height: Sizes.hero,
                    decoration: BoxDecoration(color: p.successSoft, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: Sizes.heroIcon, color: p.success),
                  ),
                ),
                const SizedBox(height: Space.x6),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.requestSentTitle(counterpartName(l10n, request), amount),
                    textAlign: TextAlign.center,
                    style: context.typo.h2,
                  ),
                ),
                const SizedBox(height: Space.x2),
                Text(
                  l10n.requestSentBody(requestTime(l10n, request.expiresAt)),
                  textAlign: TextAlign.center,
                  style: context.typo.body.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: Space.x6),
                RequestPersonCard(name: counterpartName(l10n, request), phone: counterpartPhone(request)),
                if (request.note.isNotEmpty) RequestLine(label: l10n.sendReceiptNote, value: request.note),
              ],
            ],
          ),
        ),
        AppButton(label: l10n.sendDone, onPressed: () => Navigator.of(context).pop()),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}
