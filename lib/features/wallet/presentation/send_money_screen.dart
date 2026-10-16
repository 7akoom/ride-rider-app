import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/format/bidi.dart';
import '../../../core/format/money_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/share/share_text.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/transfer.dart';
import '../domain/use_cases/send_money.dart';
import 'amount_choice.dart';
import 'contact_picker.dart';
import 'pin_confirm.dart';
import 'send_money_controller.dart';

Future<void> openSendMoney(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SendMoneyScreen()));

/// 33–36: send money to another rider, by phone.
class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  SendMoneyController get _controller => ref.read(sendMoneyControllerProvider.notifier);

  void _usePhone(PhoneNumber phone) {
    _phone.text = phone.national;
    _controller.phoneTyped(phone.e164);
  }

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
      _usePhone(phone);
    }
  }

  /// The PIN: created first when there is none, then the sheet.
  Future<void> _confirm() {
    final l10n = context.l10n;
    final flow = ref.read(sendMoneyControllerProvider);

    return confirmWithPin(
      context,
      ref,
      detail: l10n.sendPinDetail(formatMoney(l10n, flow.amount), flow.recipient?.name ?? ''),
      needsPin: l10n.sendNeedsPin,
      submit: _controller.confirm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flow = ref.watch(sendMoneyControllerProvider);

    if (flow.step == SendStep.done && flow.sent != null) {
      return AppScaffold(
        topBar: AppTopBar(title: l10n.sendTitle, showBack: false),
        body: _SentView(sent: flow.sent!, name: flow.recipient?.name ?? ''),
      );
    }

    return PopScope(
      // Back goes one step back, not out of the flow.
      canPop: flow.step == SendStep.recipient,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _controller.back();
        }
      },
      child: AppScaffold(
        topBar: AppTopBar(title: l10n.sendTitle),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Steps(step: flow.step),
            const SizedBox(height: Space.x4),
            Expanded(
              child: switch (flow.step) {
                SendStep.recipient => _RecipientView(
                    flow: flow,
                    phone: _phone,
                    onChanged: _controller.phoneTyped,
                    onPickContact: _pickContact,
                    onRecent: _usePhone,
                    onRetry: _controller.retryLookup,
                    onContinue: _controller.toAmount,
                  ),
                SendStep.amount => _AmountView(
                    flow: flow,
                    onAmount: _controller.setAmount,
                    onNote: _controller.noteChanged,
                    onChangeRecipient: _controller.toRecipient,
                    onRetryLoad: () => unawaited(_controller.load()),
                    onContinue: _controller.toReview,
                  ),
                _ => _ReviewView(
                    flow: flow,
                    onSend: _confirm,
                    onEdit: _controller.back,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 recipient, 2 amount, 3 confirm (the PIN).
class _Steps extends StatelessWidget {
  const _Steps({required this.step});

  final SendStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final current = switch (step) {
      SendStep.recipient => 0,
      SendStep.amount => 1,
      _ => 2,
    };
    final labels = [l10n.sendStepRecipient, l10n.sendStepAmount, l10n.sendStepConfirm];

    // Three equal places, the label under its number: a long label (Kurdish)
    // shortens instead of pushing the row off the screen.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: i < current ? p.brandStrong : (i == current ? p.ink : p.surface2),
                  child: i < current
                      ? Icon(Icons.check, size: 14, color: p.onInk)
                      : Text(
                          '${i + 1}',
                          style: context.typo.micro.copyWith(color: i == current ? p.onInk : p.textSecondary),
                        ),
                ),
                const SizedBox(height: Space.x1),
                Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.typo.caption.copyWith(color: i <= current ? p.textPrimary : p.textTertiary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecipientView extends StatelessWidget {
  const _RecipientView({
    required this.flow,
    required this.phone,
    required this.onChanged,
    required this.onPickContact,
    required this.onRecent,
    required this.onRetry,
    required this.onContinue,
  });

  final SendFlow flow;
  final TextEditingController phone;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickContact;
  final ValueChanged<PhoneNumber> onRecent;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recipient = flow.recipient;
    final failure = flow.lookupFailure;

    final Widget? answer = switch (recipient?.result) {
      _ when flow.lookingUp => Center(child: LoadingDots(color: context.palette.brandStrong)),
      RecipientResult.found => _RecipientCard(name: recipient!.name, phone: recipient.phone),
      RecipientResult.notFound => StatusBanner(tone: Tone.warning, message: l10n.sendNotRegistered),
      RecipientResult.self => StatusBanner(tone: Tone.warning, message: l10n.sendSelf),
      null when failure != null => StatusBanner(
          tone: Tone.danger,
          message: failure is RateLimitedFailure ? l10n.sendLookupTooMany : failure.message(l10n),
          actionLabel: failure is RateLimitedFailure ? null : l10n.actionRetry,
          onAction: failure is RateLimitedFailure ? null : onRetry,
        ),
      null => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              if (flow.problem is SendRecipientGone) ...[
                StatusBanner(tone: Tone.danger, message: l10n.sendRecipientGone),
                const SizedBox(height: Space.x4),
              ],
              PhoneField(controller: phone, label: l10n.sendPhoneLabel, onChanged: onChanged, autofocus: true),
              const SizedBox(height: Space.x2),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PillButton(icon: Icons.contacts_outlined, label: l10n.sendPickContact, onPressed: onPickContact),
              ),
              if (answer != null) ...[
                const SizedBox(height: Space.x4),
                answer,
              ],
              if (flow.recent.isNotEmpty) ...[
                const SizedBox(height: Space.x6),
                SectionHeader(title: l10n.sendRecent),
                for (final recent in flow.recent)
                  AppListRow(
                    icon: Icons.history,
                    title: isolateLtr(recent.display),
                    onTap: () => onRecent(recent),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        AppButton(label: l10n.sendContinue, onPressed: flow.canContinue ? onContinue : null),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.name, required this.phone, this.onChange});

  final String name;
  final PhoneNumber phone;
  final VoidCallback? onChange;

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
                Text(
                  isolateLtr(phone.display),
                  style: context.typo.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          if (onChange != null)
            AppButton(
              label: context.l10n.sendChange,
              variant: AppButtonVariant.text,
              expand: false,
              onPressed: onChange,
            )
          else
            Icon(Icons.verified_outlined, color: p.success),
        ],
      ),
    );
  }
}

class _AmountView extends StatefulWidget {
  const _AmountView({
    required this.flow,
    required this.onAmount,
    required this.onNote,
    required this.onChangeRecipient,
    required this.onRetryLoad,
    required this.onContinue,
  });

  final SendFlow flow;
  final ValueChanged<int> onAmount;
  final ValueChanged<String> onNote;
  final VoidCallback onChangeRecipient;
  final VoidCallback onRetryLoad;
  final VoidCallback onContinue;

  /// The ready amounts; those the rider may not send now show but cannot be picked.
  static const List<int> amounts = [1000, 3000, 5000, 10000, 25000];

  @override
  State<_AmountView> createState() => _AmountViewState();
}

class _AmountViewState extends State<_AmountView> {
  // The note stays as typed when the rider goes to the review and back.
  late final TextEditingController _note = TextEditingController(text: widget.flow.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _problemText(AppLocalizations l10n, TransferAmountProblem problem, TransferOptions options) =>
      switch (problem) {
        TransferAmountProblem.tooSmall => l10n.sendTooSmall(formatMoney(l10n, options.min)),
        TransferAmountProblem.tooBig => l10n.sendTooBig(formatMoney(l10n, options.max)),
        TransferAmountProblem.overToday => l10n.sendOverToday(formatMoney(l10n, options.leftToday)),
        TransferAmountProblem.tooManyToday => l10n.sendTooManyToday,
        TransferAmountProblem.overBalance => l10n.sendOverBalance,
      };

  String _limits(AppLocalizations l10n, TransferOptions options) =>
      l10n.sendLimits(formatMoney(l10n, options.min), formatMoney(l10n, options.max));

  Future<void> _other(TransferOptions options, int balance) async {
    final l10n = context.l10n;
    final amount = await showAmountSheet(
      context,
      initial: _AmountView.amounts.contains(widget.flow.amount) ? 0 : widget.flow.amount,
      hint: _limits(l10n, options),
      problemOf: (amount) => switch (options.problemOf(amount, balance: balance)) {
        final TransferAmountProblem problem => _problemText(l10n, problem, options),
        null => null,
      },
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
    final balance = flow.balance;
    final recipient = flow.recipient;

    if (options == null || balance == null) {
      final failure = flow.loadFailure;

      return failure == null
          ? Center(child: LoadingDots(color: p.brandStrong))
          : FailureView(failure: failure, onRetry: widget.onRetryLoad);
    }

    final problem = flow.amountProblem;
    final String? sendProblem = switch (flow.problem) {
      SendAmountProblem(problem: final amountProblem) => _problemText(l10n, amountProblem, options),
      SendFailed(:final failure) => failure is PreconditionFailure ? l10n.sendNotSent : failure.message(l10n),
      _ => null,
    };
    final hint = sendProblem ?? (problem != null ? _problemText(l10n, problem, options) : _limits(l10n, options));
    final wrong = sendProblem != null || problem != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              if (recipient != null)
                _RecipientCard(name: recipient.name, phone: recipient.phone, onChange: widget.onChangeRecipient),
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
                l10n.sendAvailable(formatMoney(l10n, balance)),
                textAlign: TextAlign.center,
                style: t.caption.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Space.x1),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: t.caption.copyWith(color: wrong ? p.danger : p.textSecondary),
              ),
              const SizedBox(height: Space.x6),
              AmountChoice(
                amounts: _AmountView.amounts,
                selected: flow.amount,
                allowed: (amount) => options.problemOf(amount, balance: balance) == null,
                onSelected: widget.onAmount,
                onOther: () => unawaited(_other(options, balance)),
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
        AppButton(label: l10n.sendContinue, onPressed: flow.canSend ? widget.onContinue : null),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}

/// The transfer as it will go: who, how much, the note, and the balance after it.
/// "Send" is what asks for the PIN.
class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.flow, required this.onSend, required this.onEdit});

  final SendFlow flow;
  final VoidCallback onSend;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final recipient = flow.recipient;
    final balance = flow.balance;
    final amount = formatMoney(l10n, flow.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(l10n.sendReviewTitle, style: context.typo.h2),
              const SizedBox(height: Space.x4),
              if (recipient != null) _RecipientCard(name: recipient.name, phone: recipient.phone),
              const SizedBox(height: Space.x4),
              Container(
                padding: const EdgeInsets.all(Space.x4),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border.all(color: p.border),
                  borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.sendStepAmount, style: context.typo.caption.copyWith(color: p.textSecondary)),
                    const SizedBox(height: Space.x1),
                    Text(amount, style: context.typo.display),
                    const Divider(height: Space.x6),
                    if (flow.note.trim().isNotEmpty) _Line(label: l10n.sendReceiptNote, value: flow.note.trim()),
                    if (balance != null) _Line(label: l10n.sendBalanceAfter, value: formatMoney(l10n, balance - flow.amount)),
                  ],
                ),
              ),
              const SizedBox(height: Space.x3),
              Text(l10n.sendReviewNote, style: context.typo.caption.copyWith(color: p.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        AppButton(label: l10n.sendNow(amount), icon: Icons.north_east, onPressed: onSend),
        const SizedBox(height: Space.x2),
        AppButton(label: l10n.sendEditAmount, variant: AppButtonVariant.text, onPressed: onEdit),
        const SizedBox(height: Space.x2),
      ],
    );
  }
}

/// 36: the transfer went through.
class _SentView extends ConsumerWidget {
  const _SentView({required this.sent, required this.name});

  final SentMoney sent;
  final String name;

  String _when(AppLocalizations l10n) => '${formatDate(l10n, sent.at)} · ${formatClock(l10n, sent.at)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final amount = formatMoney(l10n, sent.amount);
    final balance = sent.balance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x6),
            children: [
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
                child: Text(l10n.sendDoneTitle(amount, name), textAlign: TextAlign.center, style: context.typo.h2),
              ),
              const SizedBox(height: Space.x2),
              Text(
                l10n.sendDoneBody,
                textAlign: TextAlign.center,
                style: context.typo.body.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Space.x6),
              _RecipientCard(name: name, phone: sent.phone),
              const SizedBox(height: Space.x3),
              _Line(label: l10n.sendReceiptId, value: isolateLtr(sent.id.split('-').first.toUpperCase())),
              _Line(label: l10n.sendReceiptTime, value: _when(l10n)),
              if (sent.note.isNotEmpty) _Line(label: l10n.sendReceiptNote, value: sent.note),
              if (balance != null) _Line(label: l10n.sendNewBalance, value: formatMoney(l10n, balance)),
            ],
          ),
        ),
        AppButton(label: l10n.sendDone, onPressed: () => Navigator.of(context).pop()),
        const SizedBox(height: Space.x2),
        AppButton(
          label: l10n.sendShare,
          icon: Icons.ios_share,
          variant: AppButtonVariant.secondary,
          onPressed: () => unawaited(
            ref.read(shareTextProvider)(
              l10n.sendShareText(
                amount,
                name,
                isolateLtr(sent.id.split('-').first.toUpperCase()),
                _when(l10n),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

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
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: context.typo.bodyStrong),
          ),
        ],
      ),
    );
  }
}
