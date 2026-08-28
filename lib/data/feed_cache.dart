import 'dart:io';

/// Stores the last successfully fetched feed body and its ETag per region.
/// Backed by plain files in [dir] (the app documents folder in production,
/// a temp folder in tests) so no plugin is needed to unit-test it.
class FeedCache {
  FeedCache(this.dir);

  final Directory dir;

  File _bodyFile(String code) => File('${dir.path}/jobs_$code.json');
  File _etagFile(String code) => File('${dir.path}/etag_$code');

  Future<String?> etag(String code) async {
    final f = _etagFile(code);
    if (!await f.exists()) return null;
    final v = (await f.readAsString()).trim();
    return v.isEmpty ? null : v;
  }

  Future<String?> read(String code) async {
    final f = _bodyFile(code);
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  Future<void> write(String code, String body, String? etag) async {
    await dir.create(recursive: true);
    await _bodyFile(code).writeAsString(body, flush: true);
    final e = _etagFile(code);
    if (etag == null) {
      if (await e.exists()) await e.delete();
    } else {
      await e.writeAsString(etag, flush: true);
    }
  }
}
