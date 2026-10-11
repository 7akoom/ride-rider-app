import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/error/result.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/voucher_code.dart';
import '../domain/entities/voucher_credit.dart';
import '../wallet_providers.dart';
import 'voucher_done_view.dart';
import 'wallet_state.dart';

/// The voucher sheet; [owed] is what the rider owed before, paid first from the voucher.
Future<void> showVoucherSheet(BuildContext context, {int owed = 0}) => showAppSheet<void>(
      context: context,
      builder: (_) => SingleChildScrollView(child: VoucherSheet(owed: owed)),
    );

/// 38: the code of a voucher bought from a seller (Zain Cash, a shop) adds its amount
/// to the wallet.
class VoucherSheet extends ConsumerStatefulWidget {
  const VoucherSheet({super.key, this.owed = 0});

  final int owed;

  @override
  ConsumerState<VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends ConsumerState<VoucherSheet> {
  final TextEditingController _code = TextEditingController();
  bool _busy = false;
  Failure? _failure;
  VoucherCredit? _credit;

  static final _capitals = TextInputFormatter.withFunction(
    (_, value) => value.copyWith(text: value.text.toUpperCase()),
  );

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    if (_busy || !VoucherCode.isComplete(_code.text)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref.read(redeemVoucherProvider).call(_code.text);

    if (!mounted) {
      return;
    }
    if (result is Ok<VoucherCredit>) {
      // The wallet screen and the home screen's balance load again.
      ref.invalidate(walletProvider);
    }
    setState(() {
      _busy = false;
      switch (result) {
        case Ok(:final value):
          _credit = value;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  String? _error(AppLocalizations l10n) {
    if (VoucherCode.isWrong(_code.text)) {
      return l10n.voucherFormat;
    }

    return switch (_failure) {
      null => null,
      NotFoundFailure() => l10n.voucherWrong,
      PreconditionFailure() => l10n.voucherUnusable,
      RateLimitedFailure() => l10n.voucherTooMany,
      InvalidInputFailure() => l10n.voucherFormat,
      final Failure other => other.message(l10n),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final credit = _credit;

    if (credit != null) {
      return VoucherDoneView(credit: credit, owed: widget.owed);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.voucherTitle, onClose: () => Navigator.of(context).pop()),
        Text(l10n.voucherBody, style: context.typo.body),
        const SizedBox(height: Space.x4),
        AppTextField(
          controller: _code,
          hint: VoucherCode.example,
          helper: l10n.voucherHelper,
          error: _error(l10n),
          autofocus: true,
          fieldDirection: TextDirection.ltr,
          // No suggestions or autocorrect: a code is not a word.
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          inputFormatters: [_capitals],
          prefix: const Icon(Icons.redeem_outlined),
          onChanged: (_) => setState(() => _failure = null),
          onSubmitted: (_) => _redeem(),
        ),
        const SizedBox(height: Space.x6),
        AppButton(
          label: l10n.voucherApply,
          loading: _busy,
          onPressed: VoucherCode.isComplete(_code.text) ? _redeem : null,
        ),
      ],
    );
  }
}
