import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../theme/tokens.dart';
import '../widgets/big_button.dart';
import '../widgets/persistent_notice.dart';
import 'home_screen.dart';
import 'region_picker_screen.dart';

/// Screen 2. P1 shell: no permission request. "내 위치로 찾기" continues with the
/// default region; "직접 고를게요" opens the region picker over home.
class LocationIntroScreen extends StatelessWidget {
  const LocationIntroScreen({super.key});

  Future<void> _finish(
    BuildContext context, {
    required bool pickManually,
  }) async {
    final deps = AppDeps.of(context);
    final navigator = Navigator.of(context);
    await deps.settings.setOnboarded(true);
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
    if (pickManually) {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const RegionPickerScreen()),
      );
    }
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
                      label: '내 위치로 찾기',
                      critical: true,
                      onPressed: () => _finish(context, pickManually: false),
                    ),
                    const SizedBox(height: Tokens.gap),
                    BigButton(
                      label: '직접 고를게요',
                      mid: true,
                      variant: ButtonVariant.neutral,
                      onPressed: () => _finish(context, pickManually: true),
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
