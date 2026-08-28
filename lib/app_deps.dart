import 'package:flutter/widgets.dart';

import 'data/item_repository.dart';
import 'data/region_repository.dart';
import 'data/settings_store.dart';
import 'utils/phone_call.dart';

/// Hands repositories and the settings store down the tree without a
/// state-management package.
class AppDeps extends InheritedWidget {
  const AppDeps({
    super.key,
    required this.items,
    required this.regions,
    required this.settings,
    required this.launchPhone,
    this.clock = DateTime.now,
    required super.child,
  });

  final ItemRepository items;
  final RegionRepository regions;
  final SettingsStore settings;
  final PhoneLauncher launchPhone;

  /// Current time source; tests pass a fixed value for the stale-data banner.
  final DateTime Function() clock;

  static AppDeps of(BuildContext context) {
    final deps = context.dependOnInheritedWidgetOfExactType<AppDeps>();
    assert(deps != null, 'AppDeps missing above this widget');
    return deps!;
  }

  @override
  bool updateShouldNotify(AppDeps oldWidget) =>
      items != oldWidget.items ||
      regions != oldWidget.regions ||
      settings != oldWidget.settings;
}
