import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/map/app_map.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';
import 'package:rider_app/features/booking/presentation/choose_ride/choose_ride_screen.dart';
import 'package:rider_app/features/booking/presentation/schedule/schedule_sheet.dart';
import 'package:rider_app/features/booking/presentation/schedule/scheduled_screen.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

final _draft = TripDraft(pickup: spotNamed('Gulan'), destination: spotNamed('Family Mall'));

/// The sheet as it shows on a phone (it scrolls when it must), at 9:00.
Widget _sheet() => SingleChildScrollView(child: ScheduleSheet(now: () => DateTime(2026, 10, 11, 9, 0)));

Future<void> _openChoose(WidgetTester tester, FakeSchedules schedules) async {
  usePhoneScreen(tester);
  await pumpApp(
    tester,
    ChooseRideScreen(draft: _draft),
    inScaffold: false,
    overrides: bookingFakes(schedules: schedules),
  );
}

Future<void> _bookFirstTime(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.byTooltip(l10n.scheduleTitle));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(l10n.scheduleConfirm));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.scheduleConfirm));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AppMap.usePlaceholder = true);
  tearDown(() => AppMap.usePlaceholder = false);

  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('the sheet offers today first, from half an hour ahead, digits Western',
      (tester) async {
    usePhoneScreen(tester);
    await pumpApp(tester, _sheet());

    expect(find.text(l10n.today), findsOneWidget);
    expect(find.text(l10n.tomorrow), findsOneWidget);
    expect(find.textContaining('09:35'), findsWidgets);
    expect(find.textContaining('٠'), findsNothing);
  });

  testWidgets('booking for later shows the booking; cancelling it asks first',
      (tester) async {
    final schedules = FakeSchedules();
    await _openChoose(tester, schedules);

    await _bookFirstTime(tester, l10n);

    expect(schedules.booked, hasLength(1));
    expect(find.byType(ScheduledScreen), findsOneWidget);
    expect(find.text(l10n.bookedTitle), findsOneWidget);
    expect(find.text(l10n.bookedConfirmed), findsOneWidget);

    await tester.tap(find.text(l10n.bookingCancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.searchingCancelYes));
    await tester.pumpAndSettle();

    expect(schedules.cancelled, ['b1']);
    expect(find.text(l10n.bookingCancelled), findsOneWidget);
  });

  testWidgets('too many bookings is said in words, and nothing opens', (tester) async {
    final schedules = FakeSchedules(bookFailure: const PreconditionFailure());
    await _openChoose(tester, schedules);

    await _bookFirstTime(tester, l10n);

    expect(find.byType(ScheduledScreen), findsNothing);
    expect(find.text(l10n.scheduleTooMany), findsOneWidget);
  });

  for (final locale in AppLocales.all) {
    testWidgets('the sheet and the booking fit a phone: ${locale.languageCode}', (tester) async {
      usePhoneScreen(tester);
      // Both pumps share one scope, so both carry the same overrides.
      await pumpApp(tester, _sheet(), locale: locale, overrides: bookingFakes());
      expect(tester.takeException(), isNull);

      await pumpApp(
        tester,
        ScheduledScreen(booking: bookingOf(), estimate: 3000),
        locale: locale,
        inScaffold: false,
        overrides: bookingFakes(),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
