import '../models/region_item.dart';

/// The single boundary that P2 swaps for a RemoteItemRepository.
abstract interface class ItemRepository {
  Future<RegionFeed> fetchItems(String regionCode);
}
