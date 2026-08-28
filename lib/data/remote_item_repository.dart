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

/// Fetches `{baseUrl}/jobs/{code}.json` produced by the data pipeline.
///
/// - 200 → parse, store body + ETag in [cache]
/// - 304 → serve the cached body
/// - any other status, timeout or socket error → cached body if present
///   (marked [RegionFeed.fromCache]), otherwise [FeedException]
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

  Uri uriFor(String code) => baseUrl.resolve('jobs/$code.json');

  @override
  Future<RegionFeed> fetchItems(String regionCode) async {
    final etag = await cache.etag(regionCode);
    http.Response res;
    try {
      res = await _client.get(
        uriFor(regionCode),
        headers: {
          'If-None-Match': ?etag,
          if (readToken != null) 'Authorization': 'token $readToken',
        },
      ).timeout(timeout);
    } on TimeoutException {
      return _fallback(regionCode, 'timeout');
    } on SocketException catch (e) {
      return _fallback(regionCode, e.message);
    } on http.ClientException catch (e) {
      return _fallback(regionCode, e.message);
    }

    if (res.statusCode == 304) {
      final cached = await cache.read(regionCode);
      if (cached != null) return _parse(cached);
      // ETag without body should not happen; recover by refetching plainly.
      await cache.write(regionCode, '', null);
      return fetchItems(regionCode);
    }
    if (res.statusCode == 200) {
      // Never res.body: it guesses latin-1 when charset is missing.
      final body = utf8.decode(res.bodyBytes);
      final feed = _parse(body);
      await cache.write(regionCode, body, res.headers['etag']);
      return feed;
    }
    return _fallback(regionCode, 'HTTP ${res.statusCode}',
        statusCode: res.statusCode);
  }

  Future<RegionFeed> _fallback(String code, String reason,
      {int? statusCode}) async {
    final cached = await cache.read(code);
    if (cached != null && cached.isNotEmpty) {
      return _parse(cached).copyWith(fromCache: true);
    }
    throw FeedException(reason, statusCode: statusCode);
  }

  RegionFeed _parse(String body) =>
      RegionFeed.fromJson(jsonDecode(body) as Map<String, dynamic>);
}
