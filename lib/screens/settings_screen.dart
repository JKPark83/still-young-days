import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../theme/tokens.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';
import '../widgets/region_name.dart';
import 'howto_screen.dart';
import 'region_picker_screen.dart';

/// Screen 5. Four rows, each at least 64dp tall.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static String scaleLabel(double scale) {
    if (scale >= Tokens.scaleXLarge) return '아주 크게';
    if (scale >= Tokens.scaleLarge) return '크게';
    return '보통';
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppDeps.of(context).settings;
    return Scaffold(
      appBar: const BackBar(title: '설정'),
      body: ListView(
        padding: const EdgeInsets.all(Tokens.pagePadding),
        children: [
          ValueListenableBuilder<String>(
            valueListenable: settings.regionCode,
            builder: (context, code, _) => RegionName(
              code: code,
              builder: (context, name) => _SettingsRow(
                title: '내 동네 바꾸기',
                value: name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RegionPickerScreen(),
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: settings.textScale,
            builder: (context, scale, _) => _SettingsRow(
              title: '글자 크기',
              value: scaleLabel(scale),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TextSizeScreen()),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.notifyOn,
            builder: (context, on, _) => _SettingsRow(
              title: '알림 받기',
              value: on ? '켜짐' : '꺼짐',
              trailing: Switch(
                value: on,
                onChanged: (v) => settings.setNotifyOn(v),
              ),
              onTap: () => settings.setNotifyOn(!on),
            ),
          ),
          _SettingsRow(
            title: '앱 사용법',
            value: '',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HowToScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gap),
      child: Semantics(
        button: true,
        label: value.isEmpty ? title : '$title, 현재 $value',
        child: Material(
          color: Tokens.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radius),
            side: const BorderSide(color: Tokens.fg, width: Tokens.borderWidth),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Tokens.radius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Tokens.buttonMin),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Tokens.gap,
                  vertical: Tokens.gap / 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title, style: text.labelLarge),
                          if (value.isNotEmpty)
                            Text(
                              value,
                              style: text.bodyLarge!.copyWith(color: Tokens.primary),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      Transform.scale(scale: 1.4, child: trailing),
                      const SizedBox(width: Tokens.gap),
                    ],
                    Text('▶', style: text.labelLarge!.copyWith(color: Tokens.primary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sub-screen of settings: three text-size choices.
class TextSizeScreen extends StatelessWidget {
  const TextSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppDeps.of(context).settings;
    Widget choice(String label, double scale) => Padding(
          padding: const EdgeInsets.only(bottom: Tokens.gap),
          child: ValueListenableBuilder<double>(
            valueListenable: settings.textScale,
            builder: (context, current, _) {
              final selected = SettingsScreen.scaleLabel(current) == label;
              return BigButton(
                label: selected ? '✔ $label (지금)' : label,
                secondary: !selected,
                onPressed: () async {
                  await settings.setTextScale(scale);
                  if (context.mounted) Navigator.of(context).maybePop();
                },
              );
            },
          ),
        );
    return Scaffold(
      appBar: const BackBar(title: '글자 크기'),
      body: ListView(
        padding: const EdgeInsets.all(Tokens.pagePadding),
        children: [
          Text('글자 크기를 고르세요', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: Tokens.gap),
          choice('보통', Tokens.scaleNormal),
          choice('크게', Tokens.scaleLarge),
          choice('아주 크게', Tokens.scaleXLarge),
        ],
      ),
    );
  }
}
