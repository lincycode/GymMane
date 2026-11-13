import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/liquid_notch.dart';

void main() {
  testWidgets('a reduced-motion rest banner stays below the safe area and can be dismissed', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.padding = const FakeViewPadding(top: 48);
    addTearDown(tester.view.reset);
    late BuildContext screen;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            screen = context;
            return const SizedBox.expand();
          },
        ),
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
      ),
    );

    const title = 'Rest over';
    const subtitle = 'Dumbbell Rear Lateral Raise · Set 2/3';
    final closed = showRestToast(screen, title, subtitle: subtitle, topOffset: 68);
    await tester.pump();

    final banner = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == '$title\n$subtitle',
    );
    expect(tester.getTopLeft(banner).dy, 116);
    expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value, 1);
    expect(find.byType(LiquidNotch), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(banner);
    await tester.pumpAndSettle();
    expect(banner, findsNothing);
    await closed;
  });
}
