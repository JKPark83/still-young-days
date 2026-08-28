import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/region.dart';

/// Reads `assets/mock/regions.json` once and answers name lookups.
class RegionRepository {
  RegionRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<Sido>? _cache;

  Future<List<Sido>> fetchSido() async {
    if (_cache != null) return _cache!;
    final raw = await _bundle.loadString('assets/mock/regions.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['sido'] as List<dynamic>)
        .map((e) => Sido.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _cache!;
  }

  /// "41570" → "김포시". Falls back to the code itself when unknown.
  Future<String> nameOf(String sigunguCode) async {
    for (final sido in await fetchSido()) {
      for (final sgg in sido.sigungu) {
        if (sgg.code == sigunguCode) return sgg.name;
      }
    }
    return sigunguCode;
  }
}
