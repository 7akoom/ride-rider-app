import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../onboarding_navigation.dart';
import 'start_step_provider.dart';

/// 01: the mark and the name while the app decides where to open. Without a
/// connection it says so and offers to try again; the stored login is kept.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final t = context.typo;

    ref.listen(startStepProvider, (_, next) {
      final step = next.valueOrNull?.fold((step) => step, (_) => null);

      if (step != null) {
        openStep(context, step);
      }
    });

    final failure = ref.watch(startStepProvider).when(
          data: (result) => result.fold((_) => null, (failure) => failure),
          error: (_, __) => const UnexpectedFailure(),
          loading: () => null,
        );

    return AppScaffold(
      background: p.ink,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(),
              const SizedBox(height: Space.x6),
              Text(AppEnv.appName, style: t.display.copyWith(color: p.brand)),
              const SizedBox(height: Space.x2),
              Text(
                context.l10n.splashTagline,
                textAlign: TextAlign.center,
                style: t.body.copyWith(color: p.onInk.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: Space.x8),
              if (failure == null)
                LoadingDots(color: p.brand)
              else
                _StartFailed(
                  failure: failure,
                  onRetry: () => ref.invalidate(startStepProvider),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartFailed extends StatelessWidget {
  const _StartFailed({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(
            failure.message(context.l10n),
            textAlign: TextAlign.center,
            style: context.typo.body.copyWith(color: p.onInk),
          ),
          const SizedBox(height: Space.x4),
          AppButton(
            label: context.l10n.actionRetry,
            onPressed: onRetry,
            expand: false,
          ),
        ],
      ),
    );
  }
}
