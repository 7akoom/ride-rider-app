import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/config/app_env.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/components/components.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the keypad keeps 1-2-3 from the left in Arabic', (tester) async {
    final typed = <String>[];
    var backspaces = 0;

    await pumpApp(
      tester,
      NumericKeypad(onDigit: typed.add, onBackspace: () => backspaces++),
    );

    expect(tester.getCenter(find.text('1')).dx, lessThan(tester.getCenter(find.text('3')).dx));

    await tester.tap(find.text('7'));
    await tester.tap(find.text('0'));
    await tester.tap(find.byIcon(Icons.backspace_outlined));

    expect(typed, ['7', '0']);
    expect(backspaces, 1);
  });

  testWidgets('OTP boxes report the complete code once all digits are in', (tester) async {
    String? completed;

    await pumpApp(tester, OtpBoxes(onCompleted: (code) => completed = code));
    await tester.enterText(find.byType(TextField), '12a3456');
    await tester.pump();

    expect(completed, '123456');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('the phone field shows the dial code and is left to right', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpApp(tester, PhoneField(controller: controller));

    expect(find.text(AppEnv.phoneDialCode), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(TextField))),
      TextDirection.ltr,
    );
  });

  testWidgets('the label follows the app language direction', (tester) async {
    late String label;

    await pumpApp(
      tester,
      Builder(builder: (context) {
        label = context.l10n.fieldName;
        return AppTextField(label: label, fieldDirection: TextDirection.ltr);
      }),
    );

    expect(Directionality.of(tester.element(find.text(label))), TextDirection.rtl);
  });
}
