import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/models/region_item.dart';
import 'package:still_young_days/screens/home_screen.dart';

import '../helpers.dart';

void main() {
  testWidgets('복지관 행사 tab shows event cards, coverage notice and persists', (
    tester,
  ) async {
    usePhoneView(tester);
    final app = await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true},
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.text('✓ 일자리'), findsOneWidget);

    await tester.tap(find.text('복지관 행사'));
    await tester.pumpAndSettle();

    expect(find.text('✓ 복지관 행사'), findsOneWidget);
    expect(find.text('가을 나들이 참가자 모집'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.textContaining('복지관 2곳 중 1곳 정보를 보여드려요'), findsOneWidget);
    expect(app.settings.lastKind.value, ItemType.event);
  });

  testWidgets('saved lastKind=event starts on 행사; 일자리 switches back', (
    tester,
  ) async {
    usePhoneView(tester);
    final app = await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true, 'lastKind': 'event'},
    );
    await tester.pumpAndSettle();
    expect(find.text('✓ 복지관 행사'), findsOneWidget);
    expect(find.text('가을 나들이 참가자 모집'), findsOneWidget);

    await tester.tap(find.text('일자리'));
    await tester.pumpAndSettle();

    expect(find.text('✓ 일자리'), findsOneWidget);
    expect(find.text('1 / 8'), findsOneWidget);
    expect(app.settings.lastKind.value, ItemType.job);
  });

  testWidgets('행사 without coverage shows 준비 중 and 일자리 보기 returns', (
    tester,
  ) async {
    usePhoneView(tester);
    final app = await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true, 'lastKind': 'event', 'regionCode': '41110'},
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 준비 중이에요'), findsOneWidget);

    await tester.tap(find.text('일자리 보기'));
    await tester.pumpAndSettle();

    expect(app.settings.lastKind.value, ItemType.job);
    expect(find.textContaining('모집 중인 일자리가 없어요'), findsOneWidget);
  });
}
