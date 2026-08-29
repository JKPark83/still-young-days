import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show ByteData, CachingAssetBundle, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still_young_days/app.dart';
import 'package:still_young_days/data/item_repository.dart';
import 'package:still_young_days/data/mock_item_repository.dart';
import 'package:still_young_days/data/neighbor_repository.dart';
import 'package:still_young_days/data/region_repository.dart';
import 'package:still_young_days/data/settings_store.dart';
import 'package:still_young_days/location/location_service.dart';
import 'package:still_young_days/location/region_locator.dart';
import 'package:still_young_days/metrics/metrics.dart';
import 'package:still_young_days/models/region_item.dart';
import 'package:still_young_days/push/push_service.dart';

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

// One giant box covering all of South Korea, mapped to 김포시 (41570) — the
// real 1.45MB `assets/geo/sgg_boundaries.geojson` hangs forever when loaded
// through `rootBundle` inside a `testWidgets` body (a real, reproducible
// `flutter_tester` limitation with large platform-channel messages under the
// FakeAsync test zone); real-boundary accuracy is already covered by
// test/location/region_locator_test.dart, which loads it directly in a plain
// `test()` (no FakeAsync involved) and works fine.
const String _fakeGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "bbox": [124.0, 33.0, 132.0, 39.0],
      "properties": {"sgg": "41570", "sggnm": "김포시", "sidonm": "경기도"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[124.0, 33.0], [132.0, 33.0], [132.0, 39.0], [124.0, 39.0], [124.0, 33.0]]]
      }
    }
  ]
}
''';

/// Stands in for `assets/geo/sgg_boundaries.geojson` in tests; see
/// [_fakeGeoJson] for why the real file can't be used here.
class FakeGeoBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(_fakeGeoJson)));
}

/// Returns a fixed position (김포시청 by default) instead of calling the real
/// `geolocator` plugin. Pass null coordinates to simulate a denied/failed
/// GPS lookup.
class FakeLocationService implements LocationService {
  FakeLocationService({this.latitude = 37.6153, this.longitude = 126.7156});

  final double? latitude;
  final double? longitude;

  @override
  Future<Position?> current() async {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return null;
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.utc(2026, 8, 28),
      accuracy: 100,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

/// Builds the full app with mock repositories, starting on [home]
/// (or the splash when null).
Future<
  ({
    SettingsStore settings,
    FakePhone phone,
    MockItemRepository items,
    Metrics metrics,
    PushService push,
  })
>
pumpApp(
  WidgetTester tester, {
  Widget? home,
  double osTextScale = 1.0,
  Map<String, Object> prefs = const {},
  ItemRepository? items,
  DateTime? now,
  LocationService? location,
  PushService? push,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  // CachingAssetBundle keeps Futures bound to the previous test's FakeAsync
  // zone; a stale one never completes here and pumpAndSettle times out.
  rootBundle.clear();
  final settings = await freshSettings(initial: prefs);
  final metrics = await Metrics.load();
  final phone = FakePhone();
  final mockItems = MockItemRepository();
  final pushService = push ?? const DisabledPushService();
  pushService.attach(settings);
  addTearDown(pushService.dispose);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(osTextScale)),
      child: StillYoungApp(
        items: items ?? mockItems,
        regions: RegionRepository(),
        settings: settings,
        location: location ?? FakeLocationService(),
        regionLocator: RegionLocator(bundle: FakeGeoBundle()),
        neighbors: NeighborRepository(),
        launchPhone: phone.launch,
        metrics: metrics,
        pushService: pushService,
        navigatorKey: navigatorKey,
        // Fixed clock: the mock feed is dated 2026-08-28, keep it "fresh".
        clock: () => now ?? DateTime.utc(2026, 8, 28, 4),
        home: home,
      ),
    ),
  );
  return (
    settings: settings,
    phone: phone,
    items: mockItems,
    metrics: metrics,
    push: pushService,
  );
}

RegionItem sampleItem({
  String title = '공원 환경정비',
  String? phone = '031-000-0001',
  String? age = '60세 이상',
  String? description = '공원을 정리하는 일이에요.',
}) => RegionItem(
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
