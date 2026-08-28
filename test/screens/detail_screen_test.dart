import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/screens/detail_screen.dart';
import 'package:still_young_days/widgets/big_button.dart';

import '../helpers.dart';

void main() {
  testWidgets('age == null → no 모집 나이 row; other rows present', (tester) async {
    usePhoneView(tester);
    await pumpApp(tester, home: DetailScreen(item: sampleItem(age: null)));
    await tester.pumpAndSettle();
    expect(find.text('모집 나이'), findsNothing);
    expect(find.text('하는 일'), findsOneWidget);
    expect(find.text('장소'), findsOneWidget);
    expect(find.text('신청 기간'), findsOneWidget);
    expect(find.text('8월 25일 (화) ~ 9월 7일 (월)'), findsOneWidget);
    expect(find.text('기관'), findsOneWidget);
    expect(find.text('받는 돈'), findsNothing);
    expect(find.text('일하는 때'), findsNothing);
  });

  testWidgets('call button >= 72dp and stays visible after scrolling',
      (tester) async {
    usePhoneView(tester);
    final longText = List.filled(30, '이 문장은 스크롤을 만들기 위한 긴 설명이에요.').join(' ');
    final deps = await pumpApp(
      tester,
      home: DetailScreen(item: sampleItem(description: longText)),
    );
    await tester.pumpAndSettle();
    final btn = find.widgetWithText(BigButton, '📞 전화하기');
    expect(tester.getSize(btn).height, greaterThanOrEqualTo(72));

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(btn, findsOneWidget);
    expect(tester.getRect(btn).bottom, lessThanOrEqualTo(780));

    await tester.tap(btn);
    await tester.pumpAndSettle();
    expect(deps.phone.calls, ['031-000-0001']);
  });

  testWidgets('phone null → permanent notice instead of button', (tester) async {
    usePhoneView(tester);
    await pumpApp(tester, home: DetailScreen(item: sampleItem(phone: null)));
    await tester.pumpAndSettle();
    expect(find.text('📞 전화하기'), findsNothing);
    expect(find.text('이 일자리는 전화번호가 없어요.'), findsOneWidget);
  });

  testWidgets('failed launch shows the number in a persistent notice',
      (tester) async {
    usePhoneView(tester);
    final deps = await pumpApp(tester, home: DetailScreen(item: sampleItem()));
    deps.phone.succeed = false;
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(BigButton, '📞 전화하기'));
    await tester.pumpAndSettle();
    expect(find.text('전화를 걸 수 없어요. 번호: 031-000-0001'), findsOneWidget);
  });
}
