import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../domain/entities/top_up.dart';
import 'payment_page_screen.dart';
import 'top_up_controller.dart';
import 'top_up_entry_view.dart';
import 'top_up_progress_view.dart';
import 'top_up_review_sheet.dart';

Future<void> openTopUp(BuildContext context, TopUpOptions options) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TopUpScreen(options: options)),
    );

/// Opens the provider's payment page inside the app and returns when it closes (it
/// closes by itself on our return page); false when it could not open. Tests replace it.
final topUpPageOpenerProvider = Provider<Future<bool> Function(BuildContext, Uri)>(
  (ref) => (context, page) async {
    await openPaymentPage(context, page);

    return true;
  },
);

/// 31–32: top up the wallet through ZainCash. The amount, a review, ZainCash's own
/// page (no card number or PIN ever reaches the app), and the payment followed until
/// it ends.
class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key, required this.options});

  final TopUpOptions options;

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from a provider's own app opened from its page: ask at once rather than
    // at the next tick.
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(topUpControllerProvider.notifier).check());
    }
  }

  Future<void> _next() async {
    final amount = ref.read(topUpControllerProvider).amount;
    final pay = await showTopUpReviewSheet(context, amount);

    if (pay != true || !mounted) {
      return;
    }

    final language = Localizations.localeOf(context).languageCode;
    final page = await ref.read(topUpControllerProvider.notifier).pay(widget.options, language);

    if (page != null && mounted) {
      await _open(page);
    }
  }

  Future<void> _open(Uri page) async {
    var opened = false;

    try {
      opened = await ref.read(topUpPageOpenerProvider)(context, page);
    } catch (_) {
      opened = false;
    }

    if (!mounted) {
      return;
    }

    if (opened) {
      // The page closed (paid, failed, or closed by the rider): ask at once.
      unawaited(ref.read(topUpControllerProvider.notifier).check());
    } else {
      showAppToast(context, context.l10n.topUpOpenFailed, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(topUpControllerProvider);
    final controller = ref.read(topUpControllerProvider.notifier);
    final entering = flow.phase == TopUpPhase.entering || flow.phase == TopUpPhase.opening;

    return AppScaffold(
      topBar: AppTopBar(title: context.l10n.topUpTitle),
      body: entering
          ? TopUpEntryView(
              flow: flow,
              options: widget.options,
              onAmount: controller.setAmount,
              onNext: _next,
            )
          : TopUpProgressView(
              flow: flow,
              onReopen: () {
                final page = flow.page;

                if (page != null) {
                  unawaited(_open(page));
                }
              },
              onTryAgain: controller.tryAgain,
              onDone: () => Navigator.of(context).pop(),
            ),
    );
  }
}
