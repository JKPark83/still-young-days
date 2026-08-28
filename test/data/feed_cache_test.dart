import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/data/feed_cache.dart';

void main() {
  late Directory dir;
  late FeedCache cache;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('feed_cache_test');
    cache = FeedCache(Directory('${dir.path}/nested'));
  });

  tearDown(() => dir.delete(recursive: true));

  test('empty cache returns null', () async {
    expect(await cache.read('41570'), isNull);
    expect(await cache.etag('41570'), isNull);
  });

  test('write then read body and etag (creates missing dir)', () async {
    await cache.write('41570', '{"a":1}', 'W/"abc"');
    expect(await cache.read('41570'), '{"a":1}');
    expect(await cache.etag('41570'), 'W/"abc"');
  });

  test('write without etag removes stale etag', () async {
    await cache.write('41570', 'x', 'e1');
    await cache.write('41570', 'y', null);
    expect(await cache.read('41570'), 'y');
    expect(await cache.etag('41570'), isNull);
  });

  test('regions are independent', () async {
    await cache.write('41570', 'gimpo', null);
    expect(await cache.read('41111'), isNull);
  });
}
