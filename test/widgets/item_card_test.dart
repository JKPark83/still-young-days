import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/theme/app_theme.dart';
import 'package:still_young_days/widgets/big_button.dart';
import 'package:still_young_days/widgets/item_card.dart';

import '../helpers.dart';

void main() {
  const longTitle = '초등학교 등하굣길 교통안전 도우미 및 학교 주변 순찰 활동 지원';

  Widget wrap(Widget card) => MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SizedBox(width: 360, height: 520, child: card),
        ),
      );

  testWidgets('40-char title renders on multiple lines with no ellipsis',
      (tester) async {
    usePhoneView(tester);
    await tester.pumpWidget(
      wrap(ItemCard(item: sampleItem(title: longTitle), onOpen: () {}, onCall: () {})),
    );
    final text = tester.widget<Text>(find.text(longTitle));
    expect(text.overflow, TextOverflow.visible);
    expect(text.maxLines, isNull);
    final size = tester.getSize(find.text(longTitle));
    // Single line at 24sp * 1.5 = 36; two lines or more is >= 72.
    expect(size.height, greaterThanOrEqualTo(72));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone button height >= 64 and tap calls onCall', (tester) async {
    usePhoneView(tester);
    var called = 0;
    await tester.pumpWidget(
      wrap(ItemCard(item: sampleItem(), onOpen: () {}, onCall: () => called++)),
    );
    final btn = find.widgetWithText(BigButton, '📞 전화하기');
    expect(tester.getSize(btn).height, greaterThanOrEqualTo(64));
    await tester.tap(btn);
    expect(called, 1);
  });

  testWidgets('no phone → fallback button opens detail', (tester) async {
    usePhoneView(tester);
    var opened = 0;
    await tester.pumpWidget(
      wrap(ItemCard(item: sampleItem(phone: null), onOpen: () => opened++, onCall: () {})),
    );
    expect(find.text('📞 전화하기'), findsNothing);
    await tester.tap(find.widgetWithText(BigButton, '전화번호가 없어요 · 자세히 보기'));
    expect(opened, 1);
  });
}
