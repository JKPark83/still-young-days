import '../models/region_item.dart';

/// The single boundary that P2 swaps for a RemoteItemRepository.
abstract interface class ItemRepository {
  /// [kind] picks the feed: 일자리 (default) or 복지관 행사.
  Future<RegionFeed> fetchItems(String regionCode, {ItemType kind});
}
