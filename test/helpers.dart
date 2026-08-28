import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still_young_days/app.dart';
import 'package:still_young_days/data/item_repository.dart';
import 'package:still_young_days/data/mock_item_repository.dart';
import 'package:still_young_days/data/region_repository.dart';
import 'package:still_young_days/data/settings_store.dart';
import 'package:still_young_days/models/region_item.dart';

/// Phone-sized logical viewport (360 x 780) for every widget test.
void usePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Records tel: launches instead of opening a dialer.
class FakePhone {
  final List<String> calls = [];
  bool succeed = true;

  Future<bool> launch(String phone) async {
    calls.add(phone);
    return succeed;
  }
}

Future<SettingsStore> freshSettings({Map<String, Object> initial = const {}}) {
  SharedPreferences.setMockInitialValues(initial);
  return SettingsStore.load();
}

/// Builds the full app with mock repositories, starting on [home]
/// (or the splash when null).
Future<
    ({
      SettingsStore settings,
      FakePhone phone,
      MockItemRepository items,
    })> pumpApp(
  WidgetTester tester, {
  Widget? home,
  double osTextScale = 1.0,
  Map<String, Object> prefs = const {},
  ItemRepository? items,
  DateTime? now,
}) async {
  // CachingAssetBundle keeps Futures bound to the previous test's FakeAsync
  // zone; a stale one never completes here and pumpAndSettle times out.
  rootBundle.clear();
  final settings = await freshSettings(initial: prefs);
  final phone = FakePhone();
  final mockItems = MockItemRepository();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(osTextScale)),
      child: StillYoungApp(
        items: items ?? mockItems,
        regions: RegionRepository(),
        settings: settings,
        launchPhone: phone.launch,
        // Fixed clock: the mock feed is dated 2026-08-28, keep it "fresh".
        clock: () => now ?? DateTime.utc(2026, 8, 28, 4),
        home: home,
      ),
    ),
  );
  return (settings: settings, phone: phone, items: mockItems);
}

RegionItem sampleItem({
  String title = '공원 환경정비',
  String? phone = '031-000-0001',
  String? age = '60세 이상',
  String? description = '공원을 정리하는 일이에요.',
}) =>
    RegionItem(
      type: ItemType.job,
      id: 'test:1',
      title: title,
      place: '김포시 사우동',
      address: '경기도 김포시 사우동 123',
      phone: phone,
      org: '김포시니어클럽',
      description: description,
      age: age,
      applyStart: '2026-08-25',
      applyEnd: '2026-09-07',
      source: 'test',
      sourceUrl: null,
    );

/// Tallest render box among widgets matching [finder].
double heightOf(WidgetTester tester, Finder finder) =>
    tester.getSize(finder.first).height;
