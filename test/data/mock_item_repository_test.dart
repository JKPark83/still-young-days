import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/data/mock_item_repository.dart';
import 'package:still_young_days/models/region_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repo = MockItemRepository();
  setUp(rootBundle.clear);

  test('loads 8 items for 41570', () async {
    final feed = await repo.fetchItems('41570');
    expect(feed.regionCode, '41570');
    expect(feed.items.length, 8);
    expect(feed.items.every((i) => i.type == ItemType.job), isTrue);
  });

  test('exactly one item has no phone and one has no age', () async {
    final feed = await repo.fetchItems('41570');
    expect(feed.items.where((i) => !i.hasPhone).length, 1);
    expect(feed.items.where((i) => i.age == null).length, 1);
  });

  test('unknown region → 0 items, requested code kept', () async {
    final feed = await repo.fetchItems('41110');
    expect(feed.items, isEmpty);
    expect(feed.regionCode, '41110');
  });

  test('unknown item type throws', () {
    expect(() => ItemType.parse('news'), throwsFormatException);
  });
}
