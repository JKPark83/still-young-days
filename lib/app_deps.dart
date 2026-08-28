import 'package:flutter/widgets.dart';

import 'data/item_repository.dart';
import 'data/neighbor_repository.dart';
import 'data/region_repository.dart';
import 'data/settings_store.dart';
import 'location/location_service.dart';
import 'location/region_locator.dart';
import 'metrics/metrics.dart';
import 'utils/phone_call.dart';

/// Hands repositories and the settings store down the tree without a
/// state-management package.
class AppDeps extends InheritedWidget {
  const AppDeps({
    super.key,
    required this.items,
    required this.regions,
    required this.settings,
    required this.location,
    required this.regionLocator,
    required this.neighbors,
    required this.launchPhone,
    required this.metrics,
    this.clock = DateTime.now,
    required super.child,
  });

  final ItemRepository items;
  final RegionRepository regions;
  final SettingsStore settings;
  final LocationService location;
  final RegionLocator regionLocator;
  final NeighborRepository neighbors;
  final PhoneLauncher launchPhone;
  final Metrics metrics;

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
