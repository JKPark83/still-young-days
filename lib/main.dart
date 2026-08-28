import 'package:flutter/material.dart';

import 'app.dart';
import 'data/mock_item_repository.dart';
import 'data/region_repository.dart';
import 'data/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  runApp(
    StillYoungApp(
      items: MockItemRepository(),
      regions: RegionRepository(),
      settings: settings,
    ),
  );
}
