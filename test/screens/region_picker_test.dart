import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/screens/home_screen.dart';
import 'package:still_young_days/screens/region_picker_screen.dart';
import 'package:still_young_days/screens/settings_screen.dart';
import 'package:still_young_days/widgets/big_button.dart';

import '../helpers.dart';

void main() {
  testWidgets('내 위치로 다시 찾기 stores the located region and closes', (
    tester,
  ) async {
    usePhoneView(tester);
    final deps = await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true, 'regionCode': '11110'},
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '동네 바꾸기'));
    await tester.pumpAndSettle();
    expect(find.byType(RegionPickerScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(BigButton, '내 위치로 다시 찾기'));
    await tester.pumpAndSettle();

    expect(deps.settings.regionCode.value, '41570');
    expect(deps.settings.regionFromGps.value, isTrue);
    expect(find.byType(RegionPickerScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('내 위치로 다시 찾기 shows a notice when GPS fails', (tester) async {
    usePhoneView(tester);
    final deps = await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true, 'regionCode': '11110'},
      location: FakeLocationService(latitude: null, longitude: null),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '동네 바꾸기'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(BigButton, '내 위치로 다시 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('내 동네를 찾지 못했어요. 목록에서 골라 주세요.'), findsOneWidget);
    expect(deps.settings.regionCode.value, '11110');
    expect(find.byType(RegionPickerScreen), findsOneWidget);
  });

  testWidgets('시/도 buttons are >= 72dp and 경기도 → 김포시 stores 41570', (
    tester,
  ) async {
    usePhoneView(tester);
    final deps = await pumpApp(
      tester,
      home: const RegionPickerScreen(),
      prefs: {'regionCode': '41110'},
    );
    await tester.pumpAndSettle();

    final gyeonggi = find.widgetWithText(BigButton, '경기도');
    expect(tester.getSize(gyeonggi).height, greaterThanOrEqualTo(72));
    expect(find.byType(TextField), findsNothing); // no search box

    await tester.tap(gyeonggi);
    await tester.pumpAndSettle();
    final gimpo = find.text('김포시');
    // ListView builds lazily: scroll until built, then bring fully on screen.
    await tester.scrollUntilVisible(
      gimpo,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(gimpo);
    await tester.pumpAndSettle();
    await tester.tap(gimpo);
    await tester.pumpAndSettle();
    expect(deps.settings.regionCode.value, '41570');
  });

  testWidgets('설정: 위치로 정한 동네엔 (내 위치)가 붙고 직접 고르면 사라진다', (tester) async {
    usePhoneView(tester);
    final deps = await pumpApp(
      tester,
      home: const SettingsScreen(),
      prefs: {'onboarded': true, 'regionCode': '41570', 'regionFromGps': true},
    );
    await tester.pumpAndSettle();
    expect(find.text('김포시 (내 위치)'), findsOneWidget);

    await tester.tap(find.textContaining('내 동네 바꾸기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '경기도'));
    await tester.pumpAndSettle();
    final suwon = find.text('수원시');
    await tester.scrollUntilVisible(
      suwon,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(suwon);
    await tester.pumpAndSettle();
    await tester.tap(suwon);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(deps.settings.regionCode.value, '41110');
    expect(deps.settings.regionFromGps.value, isFalse);
    expect(find.text('수원시'), findsOneWidget);
    expect(find.textContaining('(내 위치)'), findsNothing);
  });

  testWidgets('changing region from home refreshes the feed', (tester) async {
    usePhoneView(tester);
    await pumpApp(tester, home: const HomeScreen(), prefs: {'onboarded': true});
    await tester.pumpAndSettle();
    expect(find.text('1 / 8'), findsOneWidget);

    await tester.tap(find.widgetWithText(BigButton, '설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('내 동네 바꾸기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '경기도'));
    await tester.pumpAndSettle();
    final suwon = find.text('수원시');
    await tester.scrollUntilVisible(
      suwon,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(suwon);
    await tester.pumpAndSettle();
    await tester.tap(suwon);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('수원시'), findsOneWidget);
    expect(find.textContaining('모집 중인 일자리가 없어요'), findsOneWidget);
  });
}
