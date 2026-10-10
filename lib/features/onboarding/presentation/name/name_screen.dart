import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/values/display_name.dart';
import '../onboarding_navigation.dart';
import 'name_controller.dart';

/// 05: the new rider's name. First and family name are joined into the one name the
/// backend keeps; the family name is optional.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _first = TextEditingController();
  final _family = TextEditingController();

  /// Problems with the name show once the rider has tried to continue.
  bool _tried = false;

  String get _typed => '${_first.text} ${_family.text}';

  @override
  void dispose() {
    _first.dispose();
    _family.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _tried = true);

    final name = DisplayName.tryParse(_typed);
    if (name == null) {
      return;
    }

    final next = await ref.read(nameControllerProvider.notifier).save(name);

    if (next != null && mounted) {
      openStep(context, next);
    }
  }

  void _edited(String _) {
    setState(() {});
    ref.read(nameControllerProvider.notifier).clearFailure();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(nameControllerProvider);
    final failure = state.failure;
    final problem = _tried ? DisplayName.check(_typed) : null;

    return AppScaffold(
      bottomAction: AppButton(
        label: l10n.nameStart,
        loading: state.saving,
        onPressed: _first.text.trim().isEmpty ? null : _save,
      ),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsetsDirectional.only(top: Space.x8),
          children: [
            Text(l10n.nameTitle, style: context.typo.h1),
            const SizedBox(height: Space.x2),
            Text(
              l10n.nameSubtitle,
              style: context.typo.body.copyWith(color: context.palette.textSecondary),
            ),
            const SizedBox(height: Space.x6),
            AppTextField(
              controller: _first,
              label: l10n.fieldFirstName,
              autofocus: true,
              autofillHints: const [AutofillHints.givenName],
              textInputAction: TextInputAction.next,
              error: switch (problem) {
                DisplayNameProblem.tooShort => l10n.nameTooShort,
                DisplayNameProblem.tooLong => l10n.nameTooLong,
                null => null,
              },
              onChanged: _edited,
            ),
            const SizedBox(height: Space.x4),
            AppTextField(
              controller: _family,
              label: l10n.fieldFamilyName,
              autofillHints: const [AutofillHints.familyName],
              textInputAction: TextInputAction.done,
              onChanged: _edited,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: Space.x6),
            if (failure != null) ...[
              StatusBanner(tone: Tone.danger, message: failure.message(l10n)),
              const SizedBox(height: Space.x3),
            ],
            StatusBanner(tone: Tone.info, message: l10n.namePrivacy),
          ],
        ),
      ),
    );
  }
}
