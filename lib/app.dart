import 'package:flutter/material.dart';

import 'app_deps.dart';
import 'data/item_repository.dart';
import 'data/neighbor_repository.dart';
import 'data/region_repository.dart';
import 'data/settings_store.dart';
import 'location/location_service.dart';
import 'location/region_locator.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'utils/phone_call.dart';

/// Root widget. Multiplies the OS text scale by the in-app scale, then clamps
/// the product to [Tokens.clampMin]..[Tokens.clampMax].
class StillYoungApp extends StatelessWidget {
  const StillYoungApp({
    super.key,
    required this.items,
    required this.regions,
    required this.settings,
    required this.location,
    required this.regionLocator,
    required this.neighbors,
    this.launchPhone = launchPhoneCall,
    this.clock = DateTime.now,
    this.home,
  });

  final ItemRepository items;
  final RegionRepository regions;
  final SettingsStore settings;
  final LocationService location;
  final RegionLocator regionLocator;
  final NeighborRepository neighbors;
  final PhoneLauncher launchPhone;
  final DateTime Function() clock;

  /// Test hook: start on any screen instead of the splash.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return AppDeps(
      items: items,
      regions: regions,
      settings: settings,
      location: location,
      regionLocator: regionLocator,
      neighbors: neighbors,
      launchPhone: launchPhone,
      clock: clock,
      child: MaterialApp(
        title: '오늘도청춘',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        builder: (context, child) => ValueListenableBuilder<double>(
          valueListenable: settings.textScale,
          builder: (context, appScale, _) {
            final mq = MediaQuery.of(context);
            final osScale = mq.textScaler.scale(1.0);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(osScale * appScale),
              ),
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: Tokens.clampMin,
                maxScaleFactor: Tokens.clampMax,
                child: child!,
              ),
            );
          },
        ),
        home: home ?? const SplashScreen(),
      ),
    );
  }
}
