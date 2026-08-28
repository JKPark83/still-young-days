import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/screens/home_screen.dart';
import 'package:still_young_days/screens/region_picker_screen.dart';
import 'package:still_young_days/widgets/big_button.dart';

import '../helpers.dart';

void main() {
  testWidgets('시/도 buttons are >= 72dp and 경기도 → 김포시 stores 41570',
      (tester) async {
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
    final gimpo = find.widgetWithText(BigButton, '김포시');
    // ListView builds lazily: scroll until built, then bring fully on screen.
    await tester.scrollUntilVisible(gimpo, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(gimpo);
    await tester.pumpAndSettle();
    await tester.tap(gimpo);
    await tester.pumpAndSettle();
    expect(deps.settings.regionCode.value, '41570');
  });

  testWidgets('changing region from home refreshes the feed', (tester) async {
    usePhoneView(tester);
    await pumpApp(tester, home: const HomeScreen(), prefs: {'onboarded': true});
    await tester.pumpAndSettle();
    expect(find.text('1 / 8'), findsOneWidget);

    await tester.tap(find.widgetWithText(BigButton, '⚙ 설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('내 동네 바꾸기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '경기도'));
    await tester.pumpAndSettle();
    final suwon = find.widgetWithText(BigButton, '수원시');
    await tester.scrollUntilVisible(suwon, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(suwon);
    await tester.pumpAndSettle();
    await tester.tap(suwon);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('수원시'), findsOneWidget);
    expect(find.textContaining('모집 중인 일자리가 없어요'), findsOneWidget);
  });
}
