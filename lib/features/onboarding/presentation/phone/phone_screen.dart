import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/phone/phone_number.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/problems/sign_in_problems.dart';
import '../otp/otp_screen.dart';
import '../sign_in_messages.dart';
import 'phone_controller.dart';

/// 03: the mobile number the login code goes to. The button works only once the
/// number is a valid Iraqi mobile number.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _number = TextEditingController();

  PhoneNumber? get _phone => PhoneNumber.tryParse(_number.text);

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = _phone;
    if (phone == null) {
      return;
    }

    final challenge = await ref.read(phoneControllerProvider.notifier).send(phone);

    if (challenge != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => OtpScreen(challenge: challenge)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(phoneControllerProvider);
    final failure = state.failure;
    final aboutNumber = failure != null &&
        sendCodeProblemOf(failure) == SendCodeProblem.invalidNumber;

    return AppScaffold(
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.phoneTerms,
            textAlign: TextAlign.center,
            style: context.typo.micro.copyWith(color: context.palette.textTertiary),
          ),
          const SizedBox(height: Space.x3),
          AppButton(
            label: l10n.phoneSendCode,
            loading: state.sending,
            onPressed: _phone == null ? null : _send,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(top: Space.x8),
        children: [
          Text(l10n.phoneTitle, style: context.typo.h1),
          const SizedBox(height: Space.x2),
          Text(
            l10n.phoneSubtitle,
            style: context.typo.body.copyWith(color: context.palette.textSecondary),
          ),
          const SizedBox(height: Space.x6),
          PhoneField(
            controller: _number,
            label: l10n.fieldPhone,
            autofocus: true,
            error: aboutNumber ? l10n.phoneInvalid : null,
            onChanged: (_) {
              setState(() {});
              ref.read(phoneControllerProvider.notifier).clearFailure();
            },
            onSubmitted: (_) => _send(),
          ),
          if (failure != null && !aboutNumber) ...[
            const SizedBox(height: Space.x4),
            StatusBanner(tone: Tone.danger, message: sendCodeMessage(l10n, failure)),
          ],
        ],
      ),
    );
  }
}
