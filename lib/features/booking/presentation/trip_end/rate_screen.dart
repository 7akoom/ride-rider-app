import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/captain.dart';
import '../../domain/entities/ride.dart';
import '../../domain/use_cases/finish_trip.dart';
import 'rate_controller.dart';
import 'thanks_view.dart';

Future<void> openRate(BuildContext context, Ride ride, Captain? captain) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RateScreen(ride: ride, captain: captain)),
    );

/// 25: stars for the captain, a word for the operator, a tip; 26 once sent.
class RateScreen extends ConsumerWidget {
  const RateScreen({super.key, required this.ride, this.captain});

  final Ride ride;
  final Captain? captain;

  /// The tips offered; "other" is any amount within the limits.
  static const List<int> tips = [500, 1000, 2000];
  static const int _other = -1;

  static String _word(AppLocalizations l10n, int stars) => switch (stars) {
        1 => l10n.rateWord1,
        2 => l10n.rateWord2,
        3 => l10n.rateWord3,
        4 => l10n.rateWord4,
        _ => l10n.rateWord5,
      };

  static String? _problem(AppLocalizations l10n, RateState state) => switch (state.tipProblem) {
        TipProblem.tooSmall => l10n.tipTooSmall(formatMoney(l10n, TipCaptain.minTip)),
        TipProblem.tooBig => l10n.tipTooBig(formatMoney(l10n, TipCaptain.maxTip)),
        TipProblem.notEnoughMoney => l10n.tipNotEnough,
        null => switch (state.failure) {
            PreconditionFailure() => l10n.tipNotNow,
            final Failure failure => failure.message(l10n),
            null => null,
          },
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.typo;
    final provider = rateControllerProvider(ride);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final name = captain?.name ?? '';
    final other = state.customTip ? _other : state.tip;
    final problem = _problem(l10n, state);
    final balance = state.balance;

    if (state.done) {
      return AppScaffold(
        topBar: AppTopBar(title: l10n.rateBarTitle),
        body: ThanksView(tipped: state.tipped),
      );
    }

    return AppScaffold(
      topBar: AppTopBar(title: l10n.rateBarTitle),
      bottomAction: AppButton(
        label: l10n.rateSend,
        loading: state.sending,
        onPressed: state.canSend ? controller.send : null,
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x4),
        children: [
          Center(child: AppAvatar(name: name, imageUrl: captain?.photoUrl, size: Sizes.hero)),
          const SizedBox(height: Space.x3),
          Text(
            l10n.rateQuestion(name.isEmpty ? l10n.tripCaptain : name),
            style: t.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.x4),
          StarRating(value: state.stars, onChanged: controller.setStars),
          if (state.stars > 0)
            Text(_word(l10n, state.stars), style: t.caption, textAlign: TextAlign.center),
          const SizedBox(height: Space.x4),
          AppTextField(
            hint: l10n.rateComment,
            maxLines: 3,
            onChanged: controller.setComment,
            inputFormatters: [LengthLimitingTextInputFormatter(RateCaptain.maxComment)],
          ),
          const SizedBox(height: Space.x5),
          Text(l10n.tipTitle, style: t.h3),
          const SizedBox(height: Space.x2),
          AppChoiceChips<int>(
            options: [
              (0, l10n.tipNone),
              for (final amount in tips) (amount, formatMoney(l10n, amount)),
              (_other, l10n.tipOther),
            ],
            selected: other,
            onSelected: (value) => value == _other
                ? controller.setTip(TipCaptain.minTip, custom: true)
                : controller.setTip(value),
          ),
          if (other == _other) ...[
            const SizedBox(height: Space.x3),
            AppTextField(
              hint: l10n.tipOtherHint,
              keyboardType: TextInputType.number,
              fieldDirection: TextDirection.ltr,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              onChanged: (text) => controller.setTip(int.tryParse(text) ?? 0, custom: true),
            ),
          ],
          const SizedBox(height: Space.x2),
          Text(l10n.tipNote, style: t.caption),
          if (balance != null) Text(l10n.tipBalance(formatMoney(l10n, balance)), style: t.caption),
          if (problem != null) ...[
            const SizedBox(height: Space.x3),
            StatusBanner(tone: Tone.danger, message: problem),
          ],
        ],
      ),
    );
  }
}
