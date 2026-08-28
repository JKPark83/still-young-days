import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:still_young_days/data/feed_cache.dart';
import 'package:still_young_days/data/remote_item_repository.dart';

const String _feedJson = '''
{"schemaVersion":1,"regionCode":"41570","regionName":"김포시",
 "generatedAt":"2026-08-28T03:00:00Z",
 "items":[{"type":"job","id":"senuri:1","title":"공원 환경정비","place":null,
  "address":null,"phone":"031-000-0001","org":null,"description":null,
  "age":null,"applyStart":null,"applyEnd":null,"source":"senuri","sourceUrl":null}]}
''';

void main() {
  late Directory dir;
  late FeedCache cache;
  final base = Uri.parse('https://example.test/data/');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('remote_repo_test');
    cache = FeedCache(dir);
  });
  tearDown(() => dir.delete(recursive: true));

  RemoteItemRepository repo(MockClient client, {String? token}) =>
      RemoteItemRepository(
        baseUrl: base,
        cache: cache,
        client: client,
        readToken: token,
        timeout: const Duration(milliseconds: 200),
      );

  test('200 → parses UTF-8 body and stores body + ETag', () async {
    http.Request? seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response.bytes(
        utf8.encode(_feedJson),
        200,
        headers: {'etag': '"v1"'},
      );
    });
    final feed = await repo(client, token: 'tok').fetchItems('41570');
    expect(seen!.url.toString(), 'https://example.test/data/jobs/41570.json');
    expect(seen!.headers['Authorization'], 'token tok');
    expect(seen!.headers.containsKey('If-None-Match'), isFalse);
    expect(feed.regionName, '김포시');
    expect(feed.items.single.phone, '031-000-0001');
    expect(feed.fromCache, isFalse);
    expect(await cache.etag('41570'), '"v1"');
    expect(await cache.read('41570'), _feedJson);
  });

  test('304 → sends If-None-Match and serves cached body', () async {
    await cache.write('41570', _feedJson, '"v1"');
    final client = MockClient((req) async {
      expect(req.headers['If-None-Match'], '"v1"');
      return http.Response('', 304);
    });
    final feed = await repo(client).fetchItems('41570');
    expect(feed.items, hasLength(1));
    expect(feed.fromCache, isFalse);
  });

  test('500 with cache → cached feed marked fromCache', () async {
    await cache.write('41570', _feedJson, null);
    final client = MockClient((_) async => http.Response('boom', 500));
    final feed = await repo(client).fetchItems('41570');
    expect(feed.fromCache, isTrue);
    expect(feed.items, hasLength(1));
  });

  test('500 without cache → FeedException with status', () async {
    final client = MockClient((_) async => http.Response('boom', 500));
    expect(
      () => repo(client).fetchItems('41570'),
      throwsA(
        isA<FeedException>().having((e) => e.statusCode, 'statusCode', 500),
      ),
    );
  });

  test('socket error without cache → FeedException', () async {
    final client = MockClient((_) async => throw const SocketException('down'));
    expect(
      () => repo(client).fetchItems('41570'),
      throwsA(isA<FeedException>()),
    );
  });

  test('timeout with cache → cached feed', () async {
    await cache.write('41570', _feedJson, null);
    final client = MockClient((_) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return http.Response(_feedJson, 200);
    });
    final feed = await repo(client).fetchItems('41570');
    expect(feed.fromCache, isTrue);
  });

  test('404 (region file missing) without cache → FeedException 404', () async {
    final client = MockClient((_) async => http.Response('', 404));
    expect(
      () => repo(client).fetchItems('99999'),
      throwsA(
        isA<FeedException>().having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });
}
