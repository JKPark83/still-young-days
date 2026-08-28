import 'package:flutter/material.dart';

import 'app_deps.dart';
import 'data/item_repository.dart';
import 'data/region_repository.dart';
import 'data/settings_store.dart';
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
    this.launchPhone = launchPhoneCall,
    this.home,
  });

  final ItemRepository items;
  final RegionRepository regions;
  final SettingsStore settings;
  final PhoneLauncher launchPhone;

  /// Test hook: start on any screen instead of the splash.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return AppDeps(
      items: items,
      regions: regions,
      settings: settings,
      launchPhone: launchPhone,
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
