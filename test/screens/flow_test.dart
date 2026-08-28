import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/screens/detail_screen.dart';
import 'package:still_young_days/screens/home_screen.dart';
import 'package:still_young_days/screens/howto_screen.dart';
import 'package:still_young_days/screens/location_intro_screen.dart';
import 'package:still_young_days/screens/region_picker_screen.dart';
import 'package:still_young_days/screens/splash_screen.dart';
import 'package:still_young_days/widgets/big_button.dart';

import '../helpers.dart';

void main() {
  testWidgets('first run: splash → location intro → home → detail → call',
      (tester) async {
    usePhoneView(tester);
    final deps = await pumpApp(tester);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('오늘도청춘'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.byType(LocationIntroScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(BigButton, '내 위치로 찾기'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(deps.settings.onboarded.value, isTrue);

    await tester.tap(find.text('자세히 보려면 여기를 누르세요').first);
    await tester.pumpAndSettle();
    expect(find.byType(DetailScreen), findsOneWidget);
    await tester.tap(find.widgetWithText(BigButton, '📞 전화하기'));
    await tester.pumpAndSettle();
    expect(deps.phone.calls, ['031-000-0001']);
  });

  testWidgets('first run: 직접 고를게요 opens the region picker over home',
      (tester) async {
    usePhoneView(tester);
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '직접 고를게요'));
    await tester.pumpAndSettle();
    expect(find.byType(RegionPickerScreen), findsOneWidget);
    await tester.tap(find.text('◀ 뒤로'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('onboarded: splash goes straight home; settings → howto',
      (tester) async {
    usePhoneView(tester);
    await pumpApp(tester, prefs: {'onboarded': true});
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(BigButton, '⚙ 설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앱 사용법'));
    await tester.pumpAndSettle();
    expect(find.byType(HowToScreen), findsOneWidget);
    await tester.tap(find.widgetWithText(BigButton, '알겠어요'));
    await tester.pumpAndSettle();
    expect(find.byType(HowToScreen), findsNothing);
  });
}
