import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/region_item.dart';
import 'feed_cache.dart';
import 'item_repository.dart';

/// Thrown when the network failed and nothing usable is in the cache.
class FeedException implements Exception {
  const FeedException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'FeedException($statusCode): $message';
}

/// Fetches `{baseUrl}/jobs/{code}.json` (or `events/{code}.json` for the
/// 복지관 행사 kind) produced by the data pipeline.
///
/// - 200 → parse, store body + ETag in [cache]
/// - 304 → serve the cached body
/// - any other status, timeout or socket error → cached body if present
///   (marked [RegionFeed.fromCache]), otherwise [FeedException]
///
/// Event feeds also carry the region's 복지관 커버리지 from the pipeline's
/// coverage.json; its failure never fails the feed (coverage is just null).
class RemoteItemRepository implements ItemRepository {
  RemoteItemRepository({
    required this.baseUrl,
    required this.cache,
    http.Client? client,
    this.readToken,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  final Uri baseUrl;
  final FeedCache cache;
  final String? readToken;
  final Duration timeout;
  final http.Client _client;

  Uri uriFor(String code, [ItemType kind = ItemType.job]) => baseUrl.resolve(
    kind == ItemType.event ? 'events/$code.json' : 'jobs/$code.json',
  );

  /// Jobs keep the bare region code so pre-P4 cache files stay valid;
  /// events get their own key (and therefore their own cache file).
  static String _cacheKey(String code, ItemType kind) =>
      kind == ItemType.event ? 'events_$code' : code;

  static const String _coverageKey = 'coverage';

  @override
  Future<RegionFeed> fetchItems(
    String regionCode, {
    ItemType kind = ItemType.job,
  }) async {
    final feed = await _fetchFeed(regionCode, kind);
    if (kind != ItemType.event) return feed;
    return feed.copyWith(coverage: await _fetchCoverage(regionCode));
  }

  Future<RegionFeed> _fetchFeed(String regionCode, ItemType kind) async {
    final key = _cacheKey(regionCode, kind);
    final res = await _get(uriFor(regionCode, kind), await cache.etag(key));
    if (res == null) return _fallback(key, 'network error');

    if (res.statusCode == 304) {
      final cached = await cache.read(key);
      if (cached != null) return _parse(cached);
      // ETag without body should not happen; recover by refetching plainly.
      await cache.write(key, '', null);
      return _fetchFeed(regionCode, kind);
    }
    if (res.statusCode == 200) {
      // Never res.body: it guesses latin-1 when charset is missing.
      final body = utf8.decode(res.bodyBytes);
      final feed = _parse(body);
      await cache.write(key, body, res.headers['etag']);
      return feed;
    }
    return _fallback(key, 'HTTP ${res.statusCode}', statusCode: res.statusCode);
  }

  /// Region's entry in coverage.json, cached like a feed. Any failure —
  /// network, missing file, missing region — degrades to null.
  Future<RegionCoverage?> _fetchCoverage(String regionCode) async {
    String? body;
    final res = await _get(
      baseUrl.resolve('coverage.json'),
      await cache.etag(_coverageKey),
    );
    if (res != null && res.statusCode == 200) {
      body = utf8.decode(res.bodyBytes);
      await cache.write(_coverageKey, body, res.headers['etag']);
    } else {
      body = await cache.read(_coverageKey);
    }
    if (body == null || body.isEmpty) return null;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final region =
          (json['regions'] as Map<String, dynamic>?)?[regionCode]
              as Map<String, dynamic>?;
      return region == null ? null : RegionCoverage.fromJson(region);
    } on Object {
      return null;
    }
  }

  /// GET with the shared headers; null on timeout/socket/client errors.
  Future<http.Response?> _get(Uri uri, String? etag) async {
    try {
      return await _client
          .get(
            uri,
            headers: {
              'If-None-Match': ?etag,
              if (readToken != null) 'Authorization': 'token $readToken',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    }
  }

  Future<RegionFeed> _fallback(
    String cacheKey,
    String reason, {
    int? statusCode,
  }) async {
    final cached = await cache.read(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return _parse(cached).copyWith(fromCache: true);
    }
    throw FeedException(reason, statusCode: statusCode);
  }

  RegionFeed _parse(String body) =>
      RegionFeed.fromJson(jsonDecode(body) as Map<String, dynamic>);
}
