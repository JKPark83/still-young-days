import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/widgets/item_card.dart';
import 'package:still_young_days/screens/call_confirm_screen.dart';
import 'package:still_young_days/screens/detail_screen.dart';
import 'package:still_young_days/screens/home_screen.dart';
import 'package:still_young_days/widgets/big_button.dart';

import '../helpers.dart';

void main() {
  testWidgets('다음 ▶ advances the counter to 2 / 8', (tester) async {
    usePhoneView(tester);
    await pumpApp(tester, home: const HomeScreen(), prefs: {'onboarded': true});
    await tester.pumpAndSettle();
    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.text('김포시'), findsOneWidget);

    await tester.tap(find.widgetWithText(BigButton, '다음 ▶'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다음 on the last card keeps 8 / 8 and shows a notice', (
    tester,
  ) async {
    usePhoneView(tester);
    await pumpApp(tester, home: const HomeScreen(), prefs: {'onboarded': true});
    await tester.pumpAndSettle();
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.widgetWithText(BigButton, '다음 ▶'));
      await tester.pumpAndSettle();
    }
    expect(find.text('8 / 8'), findsOneWidget);
    await tester.tap(find.widgetWithText(BigButton, '다음 ▶'));
    await tester.pumpAndSettle();
    expect(find.text('8 / 8'), findsOneWidget);
    expect(find.text('마지막 일자리예요.'), findsOneWidget);

    // Notice is persistent: still there after a frame, gone only on 닫기.
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('마지막 일자리예요.'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('마지막 일자리예요.'), findsNothing);
  });

  testWidgets('◀ 이전 on the first card shows the first-card notice', (
    tester,
  ) async {
    usePhoneView(tester);
    await pumpApp(tester, home: const HomeScreen(), prefs: {'onboarded': true});
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '◀ 이전'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.text('첫 번째 일자리예요.'), findsOneWidget);
  });

  testWidgets('0 items → empty state with 다른 동네 보기', (tester) async {
    usePhoneView(tester);
    await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true, 'regionCode': '41110'},
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('모집 중인 일자리가 없어요'), findsOneWidget);
    expect(find.widgetWithText(BigButton, '다른 동네 보기'), findsOneWidget);
    expect(find.text('다음 ▶'), findsNothing);
  });

  testWidgets('0 items with a neighbor → 옆 동네 보기 switches region', (
    tester,
  ) async {
    usePhoneView(tester);
    final deps = await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true, 'regionCode': '11110'},
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(BigButton, '옆 동네(중구) 보기'), findsOneWidget);

    await tester.tap(find.widgetWithText(BigButton, '옆 동네(중구) 보기'));
    await tester.pumpAndSettle();
    expect(deps.settings.regionCode.value, '11140');
  });

  testWidgets('home → detail → back keeps the same card number', (
    tester,
  ) async {
    usePhoneView(tester);
    await pumpApp(tester, home: const HomeScreen(), prefs: {'onboarded': true});
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '다음 ▶'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 8'), findsOneWidget);

    await tester.tap(find.text(ItemCard.hint).first);
    await tester.pumpAndSettle();
    expect(find.byType(DetailScreen), findsOneWidget);

    await tester.tap(find.text('◀ 뒤로'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('2 / 8'), findsOneWidget);
  });

  testWidgets('phone button on the card launches tel:', (tester) async {
    usePhoneView(tester);
    final deps = await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true},
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '📞 전화하기'));
    await tester.pumpAndSettle();
    expect(find.byType(CallConfirmScreen), findsOneWidget);
    await tester.tap(find.widgetWithText(BigButton, '📞 전화 걸기'));
    await tester.pumpAndSettle();
    expect(deps.phone.calls, ['031-000-0001']);
  });
}
