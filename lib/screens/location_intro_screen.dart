import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../theme/tokens.dart';
import '../widgets/big_button.dart';
import '../widgets/persistent_notice.dart';
import 'home_screen.dart';
import 'region_picker_screen.dart';

/// Screen 2. "내 위치로 찾기" asks for GPS permission and judges the 시군구 from
/// the coordinate; "직접 고를게요" opens the region picker over home. Either
/// way the app never gets stuck: a denied/failed/해외 result still lands on
/// the region picker instead of an error.
class LocationIntroScreen extends StatefulWidget {
  const LocationIntroScreen({super.key});

  @override
  State<LocationIntroScreen> createState() => _LocationIntroScreenState();
}

class _LocationIntroScreenState extends State<LocationIntroScreen> {
  bool _locating = false;

  Future<void> _findByLocation() async {
    setState(() => _locating = true);
    final deps = AppDeps.of(context);
    final navigator = Navigator.of(context);
    final position = await deps.location.current();
    String? code;
    if (position != null) {
      await deps.regionLocator.ensureLoaded();
      code = deps.regionLocator.locate(position.latitude, position.longitude);
    }
    if (!mounted) return;
    if (code != null) await deps.settings.setRegionCode(code);
    await deps.settings.setOnboarded(true);
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
    if (code == null) {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const RegionPickerScreen()),
      );
    }
  }

  Future<void> _pickManually() async {
    final deps = AppDeps.of(context);
    final navigator = Navigator.of(context);
    await deps.settings.setOnboarded(true);
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const RegionPickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.pagePadding + 4,
            28,
            Tokens.pagePadding + 4,
            Tokens.pagePadding + 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      '어느 동네에\n사시나요?',
                      style: text.headlineMedium!.copyWith(fontSize: 36),
                    ),
                    const SizedBox(height: Tokens.gap + 4),
                    Text(
                      '가까운 일자리를 보여드리려고 해요',
                      style: text.bodyLarge!.copyWith(
                        fontSize: Tokens.body + 2,
                      ),
                    ),
                    const SizedBox(height: Tokens.gap + 12),
                    BigButton(
                      label: _locating ? '위치를 찾는 중이에요' : '내 위치로 찾기',
                      critical: true,
                      onPressed: _locating ? null : _findByLocation,
                    ),
                    const SizedBox(height: Tokens.gap),
                    BigButton(
                      label: '직접 고를게요',
                      mid: true,
                      variant: ButtonVariant.neutral,
                      onPressed: _locating ? null : _pickManually,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Tokens.gap),
              const PersistentNotice(
                title: '위치를 안 켜도 괜찮아요',
                text: '동네를 직접 고르면 그대로 쓸 수 있어요.\n자녀분이 대신 골라 주셔도 됩니다.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
