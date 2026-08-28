import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../theme/tokens.dart';
import '../widgets/big_button.dart';
import '../widgets/persistent_notice.dart';
import 'home_screen.dart';
import 'region_picker_screen.dart';

/// Screen 2. P1 shell: no permission request. "내 위치로 찾기" shows a notice and
/// continues with the default region; "직접 고를게요" opens the region picker.
class LocationIntroScreen extends StatefulWidget {
  const LocationIntroScreen({super.key});

  @override
  State<LocationIntroScreen> createState() => _LocationIntroScreenState();
}

class _LocationIntroScreenState extends State<LocationIntroScreen> {
  String? _notice;

  Future<void> _finish({required bool pickManually}) async {
    final deps = AppDeps.of(context);
    final navigator = Navigator.of(context);
    await deps.settings.setOnboarded(true);
    if (!mounted) return;
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
          padding: const EdgeInsets.all(Tokens.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: Tokens.gap * 2),
                    Text('어느 동네에 사시나요?', style: text.headlineMedium),
                    const SizedBox(height: Tokens.gap),
                    Text('가까운 일자리를 보여드리려고 해요.', style: text.bodyLarge),
                    const SizedBox(height: Tokens.gap),
                    Text(
                      '위치를 알려주지 않아도 동네를 직접 골라서 쓸 수 있어요.',
                      style: text.bodyLarge,
                    ),
                    if (_notice != null) ...[
                      const SizedBox(height: Tokens.gap),
                      PersistentNotice(
                        text: _notice!,
                        onClose: () => setState(() => _notice = null),
                      ),
                    ],
                  ],
                ),
              ),
              BigButton(
                label: '내 위치로 찾기',
                critical: true,
                onPressed: () {
                  setState(() {
                    _notice = '위치로 찾기는 다음 단계에서 준비돼요. 지금은 김포시로 보여드릴게요.';
                  });
                  _finish(pickManually: false);
                },
              ),
              const SizedBox(height: Tokens.gap),
              BigButton(
                label: '직접 고를게요',
                secondary: true,
                onPressed: () => _finish(pickManually: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
