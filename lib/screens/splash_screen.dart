import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region_item.dart';
import '../theme/tokens.dart';
import '../widgets/big_button.dart';
import 'home_screen.dart';
import 'location_intro_screen.dart';

/// Screen 1. Shows for at least one second while the feed loads, then goes to
/// the location intro (first run) or straight home. Progress is a 20dp bar,
/// not a thin spinner.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final deps = AppDeps.of(context);
    final List<Object?> results;
    try {
      results = await Future.wait<Object?>([
        deps.items.fetchItems(deps.settings.regionCode.value),
        Future<void>.delayed(const Duration(seconds: 1)),
      ]);
    } on Object {
      // Network failed and no cache: stay here and offer a retry button.
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    final feed = results.first as RegionFeed;
    final next = deps.settings.onboarded.value
        ? HomeScreen(initialFeed: feed)
        : const LocationIntroScreen();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
  }

  void _retry() {
    setState(() => _failed = false);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppWordmark(),
              const SizedBox(height: Tokens.gap * 2),
              if (_failed) ...[
                Text(
                  '일자리를 불러오지 못했어요.\n인터넷 연결을 확인해 주세요.',
                  style: text.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Tokens.gap * 2),
                BigButton(label: '다시 시도', onPressed: _retry),
              ] else ...[
                Text(
                  '일자리를 불러오는 중입니다',
                  style: text.bodyLarge!.copyWith(fontSize: Tokens.body + 2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Tokens.gap * 2),
                Semantics(
                  label: '불러오는 중',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      minHeight: Tokens.progressBar,
                    ),
                  ),
                ),
                const SizedBox(height: Tokens.gap * 2),
                Text(
                  '잠시만 기다려 주세요',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "오늘도청춘" at 64sp with the small "STILL YOUNG DAYS" rule underneath.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('오늘도청춘', style: text.displayLarge, textAlign: TextAlign.center),
        const SizedBox(height: Tokens.gapSmall),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 22, child: Divider(color: Tokens.hairline)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'STILL YOUNG DAYS',
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: text.bodySmall!.copyWith(
                    fontSize: Tokens.caption - 3,
                    letterSpacing: (Tokens.caption - 3) * 0.24,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const SizedBox(width: 22, child: Divider(color: Tokens.hairline)),
            ],
          ),
        ),
      ],
    );
  }
}
