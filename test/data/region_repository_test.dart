import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/data/region_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('경기도는 일반구를 접어 31곳, 수원시는 모시 코드 41110', () async {
    final sido = await RegionRepository().fetchSido();
    final gyeonggi = sido.firstWhere((s) => s.name == '경기도');
    expect(gyeonggi.sigungu.length, 31);
    // 일반구(예: 수원시 장안구)는 목록에 나오지 않는다.
    expect(gyeonggi.sigungu.where((s) => s.name.endsWith('구')), isEmpty);
    final suwon = gyeonggi.sigungu.firstWhere((s) => s.name == '수원시');
    expect(suwon.code, '41110');
  });
}
