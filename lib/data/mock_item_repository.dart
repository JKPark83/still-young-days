import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/region_item.dart';
import 'item_repository.dart';

/// Reads `assets/mock/jobs_<regionCode>.json`. Unknown region → empty feed
/// (so the empty state can be exercised by picking any other region).
class MockItemRepository implements ItemRepository {
  MockItemRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String _dir = 'assets/mock';
  static const String _emptyAsset = '$_dir/jobs_41570_empty.json';

  @override
  Future<RegionFeed> fetchItems(String regionCode) async {
    String raw;
    try {
      raw = await _bundle.loadString('$_dir/jobs_$regionCode.json');
    } on Object {
      raw = await _bundle.loadString(_emptyAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Keep the requested code so the UI shows the right region.
      json['regionCode'] = regionCode;
      return RegionFeed.fromJson(json);
    }
    return RegionFeed.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
