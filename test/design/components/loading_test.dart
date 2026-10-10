import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/components/components.dart';

import '../../helpers/pump_app.dart';

/// Pretends the device asked for less motion.
Widget _stillMotion(Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child,
      ),
    );

void main() {
  testWidgets('a skeleton shines and is announced as loading', (tester) async {
    final l10n = lookupAppLocalizations(AppLocales.kurdish);

    await pumpApp(tester, const SkeletonList(rows: 2), locale: AppLocales.kurdish, settle: false);
    await tester.pump(SkeletonShimmer.period ~/ 2);

    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.loading), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a skeleton stays still when the device asks for less motion', (tester) async {
    await pumpApp(tester, _stillMotion(const SkeletonCard()));

    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(SkeletonBox), findsNWidgets(4));
  });

  testWidgets('the loading dots hop, or rest when motion is reduced', (tester) async {
    await pumpApp(tester, const LoadingDots(color: Color(0xFF000000)), settle: false);
    await tester.pump(LoadingDots.period ~/ 4);
    expect(tester.takeException(), isNull);

    await pumpApp(tester, _stillMotion(const LoadingDots(color: Color(0xFF000000))));
    expect(find.byType(LoadingDots), findsOneWidget);
  });
}
