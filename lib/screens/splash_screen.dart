import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region_item.dart';
import '../theme/tokens.dart';
import 'home_screen.dart';
import 'location_intro_screen.dart';

/// Screen 1. Shows for at least one second while the feed loads, then goes to
/// the location intro (first run) or straight home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final deps = AppDeps.of(context);
    final results = await Future.wait<Object?>([
      deps.items.fetchItems(deps.settings.regionCode.value),
      Future<void>.delayed(const Duration(seconds: 1)),
    ]);
    if (!mounted) return;
    final feed = results.first as RegionFeed;
    final next = deps.settings.onboarded.value
        ? HomeScreen(initialFeed: feed)
        : const LocationIntroScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Tokens.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('오늘도청춘', style: text.displayLarge, textAlign: TextAlign.center),
                const SizedBox(height: Tokens.gap * 2),
                Text(
                  '일자리를 불러오는 중입니다',
                  style: text.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Tokens.gap * 2),
                const SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(strokeWidth: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
