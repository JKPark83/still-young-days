import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Reads `assets/geo/neighbors.json` once: 시군구 code → adjacent codes.
/// Used only for the empty-list "옆 동네 보기" button (경계 거주자 대응).
class NeighborRepository {
  NeighborRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Map<String, List<String>>? _cache;

  Future<Map<String, List<String>>> _load() async {
    final cache = _cache;
    if (cache != null) return cache;
    final raw = await _bundle.loadString('assets/geo/neighbors.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final loaded = json.map(
      (code, neighbors) =>
          MapEntry(code, (neighbors as List<dynamic>).cast<String>()),
    );
    _cache = loaded;
    return loaded;
  }

  /// First neighboring 시군구 code of [code], or null when unknown or it has
  /// no recorded neighbors.
  Future<String?> firstNeighborOf(String code) async {
    final neighbors = (await _load())[code];
    if (neighbors == null || neighbors.isEmpty) return null;
    return neighbors.first;
  }
}
