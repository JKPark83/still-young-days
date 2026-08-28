import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/region_item.dart';
import 'item_repository.dart';

/// Reads `assets/mock/jobs_<regionCode>.json` (or `events_…` for the 행사
/// kind). Unknown region → empty feed (so the empty state can be exercised
/// by picking any other region).
class MockItemRepository implements ItemRepository {
  MockItemRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String _dir = 'assets/mock';
  static const String _emptyAsset = '$_dir/jobs_41570_empty.json';

  @override
  Future<RegionFeed> fetchItems(
    String regionCode, {
    ItemType kind = ItemType.job,
  }) async {
    final prefix = kind == ItemType.event ? 'events' : 'jobs';
    RegionFeed feed;
    try {
      final raw = await _bundle.loadString('$_dir/${prefix}_$regionCode.json');
      feed = RegionFeed.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      final raw = await _bundle.loadString(_emptyAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Keep the requested code so the UI shows the right region.
      json['regionCode'] = regionCode;
      feed = RegionFeed.fromJson(json);
    }
    if (kind != ItemType.event) return feed;
    return feed.copyWith(coverage: await _coverageOf(regionCode));
  }

  /// Region's entry in the mock coverage.json; null when absent.
  Future<RegionCoverage?> _coverageOf(String regionCode) async {
    try {
      final raw = await _bundle.loadString('$_dir/coverage.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final region =
          (json['regions'] as Map<String, dynamic>?)?[regionCode]
              as Map<String, dynamic>?;
      return region == null ? null : RegionCoverage.fromJson(region);
    } on Object {
      return null;
    }
  }
}
