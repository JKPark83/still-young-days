import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/screens/detail_screen.dart';
import 'package:still_young_days/screens/home_screen.dart';
import 'package:still_young_days/screens/settings_screen.dart';

import '../helpers.dart';

void main() {
  testWidgets('app 1.6 × OS 1.3 clamps to 2.0', (tester) async {
    usePhoneView(tester);
    await pumpApp(
      tester,
      home: const SettingsScreen(),
      osTextScale: 1.3,
      prefs: {'textScale': 1.6},
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(SettingsScreen));
    expect(MediaQuery.textScalerOf(ctx).scale(10), closeTo(20, 0.01));
    expect(find.text('아주 크게'), findsOneWidget);
  });

  testWidgets('home renders at 2.0 without RenderFlex overflow',
      (tester) async {
    usePhoneView(tester);
    await pumpApp(
      tester,
      home: const HomeScreen(),
      osTextScale: 2.0,
      prefs: {'onboarded': true},
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('1 / 8'), findsOneWidget);
    // Advance to the long-title card as well.
    await tester.tap(find.text('다음 ▶'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail renders at 2.0 without RenderFlex overflow',
      (tester) async {
    usePhoneView(tester);
    await pumpApp(
      tester,
      home: DetailScreen(
        item: sampleItem(title: '초등학교 등하굣길 교통안전 도우미 및 학교 주변 순찰 활동'),
      ),
      osTextScale: 2.0,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('📞 전화하기'), findsOneWidget);
  });

  testWidgets('choosing 크게 in settings changes the scale immediately',
      (tester) async {
    usePhoneView(tester);
    final deps = await pumpApp(tester, home: const SettingsScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('글자 크기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('크게'));
    await tester.pumpAndSettle();
    expect(deps.settings.textScale.value, 1.3);
    final ctx = tester.element(find.byType(SettingsScreen));
    expect(MediaQuery.textScalerOf(ctx).scale(10), closeTo(13, 0.01));
  });
}
