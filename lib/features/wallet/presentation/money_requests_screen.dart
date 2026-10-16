import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/money_request.dart';
import 'money_request_screen.dart';
import 'request_money_screen.dart';
import 'request_widgets.dart';
import 'wallet_state.dart';

Future<void> openMoneyRequests(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MoneyRequestsScreen()));

/// The rider's money requests: asked of them and asked by them, "pay with a code"
/// and a new request.
class MoneyRequestsScreen extends ConsumerStatefulWidget {
  const MoneyRequestsScreen({super.key});

  @override
  ConsumerState<MoneyRequestsScreen> createState() => _MoneyRequestsScreenState();
}

class _MoneyRequestsScreenState extends ConsumerState<MoneyRequestsScreen> {
  MoneyRequestSide _side = MoneyRequestSide.incoming;

  Future<void> _open(String code) async {
    await openMoneyRequest(context, code);

    if (mounted) {
      // It may have been paid, declined or cancelled there.
      ref.invalidate(moneyRequestsProvider(_side));
    }
  }

  Future<void> _payWithCode() async {
    final code = await showPayCodeSheet(context);

    if (code != null && mounted) {
      await _open(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = ref.watch(moneyRequestsProvider(_side));

    final List<Widget> items = switch (result) {
      AsyncData(value: Ok(value: final requests)) when requests.isEmpty => [
          EmptyState(
            icon: Icons.request_page_outlined,
            message: _side == MoneyRequestSide.incoming ? l10n.requestsEmptyIncoming : l10n.requestsEmptyOutgoing,
          ),
        ],
      AsyncData(value: Ok(value: final requests)) => [
          for (final request in requests)
            MoneyRequestRow(request: request, onTap: () => unawaited(_open(request.code))),
        ],
      AsyncData(value: Err(:final failure)) => [
          FailureView(failure: failure, onRetry: () => ref.invalidate(moneyRequestsProvider(_side))),
        ],
      _ => [const SkeletonList(rows: 4)],
    };

    return AppScaffold(
      topBar: AppTopBar(title: l10n.walletRequests),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(moneyRequestsProvider(_side).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
          children: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.requestPayWithCode,
                    icon: Icons.keyboard_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => unawaited(_payWithCode()),
                  ),
                ),
                const SizedBox(width: Space.x2),
                Expanded(
                  child: AppButton(
                    label: l10n.requestNew,
                    icon: Icons.south_west,
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      await openRequestMoney(context);

                      if (mounted) {
                        ref.invalidate(moneyRequestsProvider(MoneyRequestSide.outgoing));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x4),
            AppChoiceChips<MoneyRequestSide>(
              options: [
                (MoneyRequestSide.incoming, l10n.requestsIncoming),
                (MoneyRequestSide.outgoing, l10n.requestsOutgoing),
              ],
              selected: _side,
              onSelected: (side) => setState(() => _side = side),
            ),
            const SizedBox(height: Space.x3),
            ...items,
          ],
        ),
      ),
    );
  }
}

/// "Pay with a code": the code as it was sent (lower case, spaces or a dash are
/// fine); the normalized code, or null.
Future<String?> showPayCodeSheet(BuildContext context) =>
    showAppSheet<String>(context: context, builder: (_) => const _PayCodeSheet());

class _PayCodeSheet extends StatefulWidget {
  const _PayCodeSheet();

  @override
  State<_PayCodeSheet> createState() => _PayCodeSheetState();
}

class _PayCodeSheetState extends State<_PayCodeSheet> {
  final TextEditingController _code = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final code = normalizeRequestCode(_code.text);

    if (code == null) {
      setState(() => _tried = true);
    } else {
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final invalid = _tried && normalizeRequestCode(_code.text) == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.requestPayWithCode, onClose: () => Navigator.of(context).pop()),
        Text(l10n.payCodeBody, style: context.typo.body),
        const SizedBox(height: Space.x4),
        AppTextField(
          controller: _code,
          hint: 'K7XMQ-2PQRX',
          autofocus: true,
          textInputAction: TextInputAction.go,
          fieldDirection: TextDirection.ltr,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
            LengthLimitingTextInputFormatter(14),
            // Codes are upper case; typed in lower case they read the same.
            TextInputFormatter.withFunction(
              (_, typed) => typed.copyWith(text: typed.text.toUpperCase()),
            ),
          ],
          error: invalid ? l10n.payCodeInvalid : null,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: Space.x4),
        AppButton(label: l10n.payCodeOpen, onPressed: _code.text.trim().isEmpty ? null : _submit),
      ],
    );
  }
}
