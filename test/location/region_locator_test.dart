import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/location/region_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionLocator locator;

  setUpAll(() async {
    locator = RegionLocator();
    await locator.ensureLoaded();
  });

  test('parses the boundary asset in under 1,000ms', () async {
    final fresh = RegionLocator();
    final stopwatch = Stopwatch()..start();
    await fresh.ensureLoaded();
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });

  test('김포시청 (37.6153, 126.7156) → 41570', () {
    expect(locator.locate(37.6153, 126.7156), '41570');
  });

  test('세종시청 (36.4800, 127.2890) → 36110', () {
    expect(locator.locate(36.4800, 127.2890), '36110');
  });

  test('서귀포시청 (33.2541, 126.5600) → 50130', () {
    expect(locator.locate(33.2541, 126.5600), '50130');
  });

  test('수원 영통구청 (37.2596, 127.0466) → 41117', () {
    expect(locator.locate(37.2596, 127.0466), '41117');
  });

  test('광주(전남) 동구청 (35.1460, 126.9232) → 12210', () {
    expect(locator.locate(35.1460, 126.9232), '12210');
  });

  test('도쿄 (35.68, 139.69) → null (해외)', () {
    expect(locator.locate(35.68, 139.69), isNull);
  });

  test('김포·고양 경계 좌표에서도 예외 없이 값을 돌려준다', () {
    expect(() => locator.locate(37.65, 126.75), returnsNormally);
  });
}
