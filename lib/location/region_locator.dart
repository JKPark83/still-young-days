import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:turf/turf.dart';

/// One 시군구 polygon: its bbox (for a cheap pre-filter) and geometry (for the
/// exact point-in-polygon check).
class _SggRegion {
  _SggRegion({
    required this.code,
    required this.minLng,
    required this.minLat,
    required this.maxLng,
    required this.maxLat,
    required this.geometry,
  });

  factory _SggRegion.fromJson(Map<String, dynamic> json) {
    final bbox = (json['bbox'] as List<dynamic>).cast<num>();
    final properties = json['properties'] as Map<String, dynamic>;
    return _SggRegion(
      code: properties['sgg'] as String,
      minLng: bbox[0].toDouble(),
      minLat: bbox[1].toDouble(),
      maxLng: bbox[2].toDouble(),
      maxLat: bbox[3].toDouble(),
      geometry: GeometryObject.deserialize(
        json['geometry'] as Map<String, dynamic>,
      ),
    );
  }

  final String code;
  final double minLng;
  final double minLat;
  final double maxLng;
  final double maxLat;
  final GeometryObject geometry;

  bool containsBBox(double lat, double lng) =>
      lng >= minLng && lng <= maxLng && lat >= minLat && lat <= maxLat;
}

/// GPS coordinate → 시군구 code, using an offline polygon file bundled with
/// the app (`assets/geo/sgg_boundaries.geojson`). Parses once and keeps the
/// result in memory; call [ensureLoaded] before the first [locate].
class RegionLocator {
  RegionLocator({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String _assetPath = 'assets/geo/sgg_boundaries.geojson';

  final AssetBundle _bundle;
  List<_SggRegion>? _regions;
  Future<void>? _loading;

  /// Parses the boundary file the first time it's called; later calls reuse
  /// the same in-memory result. Safe to call from multiple places.
  Future<void> ensureLoaded() => _loading ??= _load();

  // Note: this deliberately parses on the main isolate rather than via
  // `compute()`. `Isolate.run` never resolves under the `flutter_tester`
  // engine used by widget tests (confirmed by hand: it hangs indefinitely),
  // and the parse itself is fast enough (<200ms, measured below) to run
  // during the "위치를 찾는 중이에요" loading state without user-visible jank.
  Future<void> _load() async {
    final raw = await _bundle.loadString(_assetPath);
    final stopwatch = Stopwatch()..start();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>;
    _regions = [
      for (final feature in features)
        _SggRegion.fromJson(feature as Map<String, dynamic>),
    ];
    stopwatch.stop();
    debugPrint(
      'RegionLocator: parsed ${_regions!.length} regions in '
      '${stopwatch.elapsedMilliseconds}ms',
    );
  }

  /// Returns the 시군구 code containing (lat, lng), or null when it falls
  /// outside every polygon (해외, 바다 등). Call [ensureLoaded] first.
  String? locate(double lat, double lng) {
    final regions = _regions;
    if (regions == null) return null;
    final point = Position(lng, lat); // turf: x = lng, y = lat.
    for (final region in regions) {
      if (!region.containsBBox(lat, lng)) continue;
      if (booleanPointInPolygon(point, region.geometry)) return region.code;
    }
    return null;
  }
}
