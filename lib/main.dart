import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/feed_cache.dart';
import 'data/item_repository.dart';
import 'data/mock_item_repository.dart';
import 'data/region_repository.dart';
import 'data/remote_item_repository.dart';
import 'data/settings_store.dart';

/// Base URL of the published `data/` folder, e.g.
/// `https://<owner>.github.io/still-young-days-data/data/`.
/// Empty (the default) keeps the bundled mock feed so the app still runs
/// before the pipeline exists:
///   flutter run --dart-define=FEED_BASE_URL=https://.../data/
const String feedBaseUrl = String.fromEnvironment('FEED_BASE_URL');

/// Optional read token for a private raw URL (open issue P2 #2). Prefer a
/// public Pages deployment so this stays empty.
const String feedReadToken = String.fromEnvironment('FEED_READ_TOKEN');

Future<ItemRepository> buildItemRepository() async {
  if (feedBaseUrl.isEmpty) return MockItemRepository();
  final dir = await getApplicationDocumentsDirectory();
  return RemoteItemRepository(
    baseUrl: Uri.parse(
      feedBaseUrl.endsWith('/') ? feedBaseUrl : '$feedBaseUrl/',
    ),
    cache: FeedCache(dir),
    readToken: feedReadToken.isEmpty ? null : feedReadToken,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  final items = await buildItemRepository();
  runApp(
    StillYoungApp(
      items: items,
      regions: RegionRepository(),
      settings: settings,
    ),
  );
}
