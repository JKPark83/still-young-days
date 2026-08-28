import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/data/item_repository.dart';
import 'package:still_young_days/data/mock_item_repository.dart';
import 'package:still_young_days/data/remote_item_repository.dart';
import 'package:still_young_days/models/region_item.dart';
import 'package:still_young_days/screens/home_screen.dart';
import 'package:still_young_days/screens/splash_screen.dart';
import 'package:still_young_days/widgets/big_button.dart';
import 'package:still_young_days/widgets/persistent_notice.dart';

import '../helpers.dart';

/// Wraps the mock feed to simulate network outcomes.
class _ScriptedRepository implements ItemRepository {
  _ScriptedRepository({this.failuresBeforeSuccess = 0, this.fromCache = false});

  final MockItemRepository _mock = MockItemRepository();
  int failuresBeforeSuccess;
  final bool fromCache;

  @override
  Future<RegionFeed> fetchItems(
    String regionCode, {
    ItemType kind = ItemType.job,
  }) async {
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw const FeedException('offline');
    }
    final feed = await _mock.fetchItems(regionCode, kind: kind);
    return feed.copyWith(fromCache: fromCache);
  }
}

void main() {
  testWidgets('splash: fetch fails with no cache → 다시 시도 → home', (
    tester,
  ) async {
    usePhoneView(tester);
    await pumpApp(
      tester,
      prefs: {'onboarded': true},
      items: _ScriptedRepository(failuresBeforeSuccess: 1),
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.textContaining('불러오지 못했어요'), findsOneWidget);

    await tester.tap(find.widgetWithText(BigButton, '다시 시도'));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('1 / 8'), findsOneWidget);
  });

  testWidgets('home: cached feed shows the "새 정보를 못 받았어요" banner', (
    tester,
  ) async {
    usePhoneView(tester);
    await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true},
      items: _ScriptedRepository(fromCache: true),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PersistentNotice), findsOneWidget);
    expect(find.textContaining('새 정보를 못 받았어요'), findsOneWidget);
    expect(find.textContaining('8월 28일'), findsWidgets);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(PersistentNotice), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home: feed older than 48h shows the stale banner', (
    tester,
  ) async {
    usePhoneView(tester);
    await pumpApp(
      tester,
      home: const HomeScreen(),
      prefs: {'onboarded': true},
      now: DateTime.utc(2026, 9, 1),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('정보가 오래됐어요'), findsOneWidget);
  });

  testWidgets('home: fresh feed shows no data banner', (tester) async {
    usePhoneView(tester);
    await pumpApp(tester, home: const HomeScreen(), prefs: {'onboarded': true});
    await tester.pumpAndSettle();
    expect(find.byType(PersistentNotice), findsNothing);
  });
}
