import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/models/region_item.dart';
import 'package:still_young_days/theme/app_theme.dart';
import 'package:still_young_days/widgets/big_button.dart';
import 'package:still_young_days/widgets/item_card.dart';

import '../helpers.dart';

RegionItem eventItem({
  String title = '가을 나들이 참가자 모집',
  String? place = '김포시노인종합복지관',
  String? phone = '031-997-9300',
  String? eventDate = '2026-09-07',
}) => RegionItem(
  type: ItemType.event,
  id: 'center:test:1',
  title: title,
  place: place,
  address: '경기도 김포시 사우중로 62',
  phone: phone,
  org: '김포시노인종합복지관',
  description: '함께 나들이를 갑니다.',
  age: null,
  applyStart: null,
  applyEnd: null,
  eventDate: eventDate,
  source: 'crawl',
  sourceUrl: 'https://example.test/bbs/1',
);

void main() {
  Widget wrap(Widget card) => MaterialApp(
    theme: buildAppTheme(),
    home: Scaffold(body: SizedBox(width: 360, height: 520, child: card)),
  );

  testWidgets('행사 card shows 날짜 · 복지관 line instead of 장소 block', (
    tester,
  ) async {
    usePhoneView(tester);
    await tester.pumpWidget(
      wrap(ItemCard(item: eventItem(), onOpen: () {}, onCall: () {})),
    );
    expect(find.text('9월 7일 (월) · 김포시노인종합복지관'), findsOneWidget);
    expect(find.text('장소'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('undated 행사 shows the 복지관 name only', (tester) async {
    usePhoneView(tester);
    await tester.pumpWidget(
      wrap(
        ItemCard(
          item: eventItem(title: '복지관 이용 안내', eventDate: null),
          onOpen: () {},
          onCall: () {},
        ),
      ),
    );
    expect(find.text('김포시노인종합복지관'), findsOneWidget);
    expect(find.textContaining(' · '), findsNothing);
  });

  testWidgets('행사 without phone falls back to 자세히 보기; semantics say 행사 카드', (
    tester,
  ) async {
    usePhoneView(tester);
    var opened = 0;
    await tester.pumpWidget(
      wrap(
        ItemCard(
          item: eventItem(phone: null),
          onOpen: () => opened++,
          onCall: () {},
        ),
      ),
    );
    await tester.tap(find.widgetWithText(BigButton, '전화번호가 없어요 · 자세히 보기'));
    expect(opened, 1);
    expect(
      find.bySemanticsLabel(RegExp('행사 카드.*가을 나들이 참가자 모집.*')),
      findsOneWidget,
    );
  });
}
