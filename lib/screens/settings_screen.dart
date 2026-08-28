import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../theme/tokens.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';
import '../widgets/list_row.dart';
import '../widgets/region_name.dart';
import '../widgets/screen_title.dart';
import '../widgets/surface_card.dart';
import 'howto_screen.dart';
import 'region_picker_screen.dart';

/// Screen 5. Four 82dp rows in one white card; the switch shows 켜짐/꺼짐 text.
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
    void push(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));
    return Scaffold(
      appBar: const BackBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Tokens.pagePadding,
          0,
          Tokens.pagePadding,
          Tokens.cardPadding,
        ),
        children: [
          const ScreenTitle('설정'),
          const SizedBox(height: 2),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: settings.regionCode,
                  builder: (context, code, _) => RegionName(
                    code: code,
                    builder: (context, name) => ValueListenableBuilder<bool>(
                      valueListenable: settings.regionFromGps,
                      builder: (context, fromGps, _) => ListRow(
                        title: '내 동네 바꾸기',
                        value: fromGps ? '$name (내 위치)' : name,
                        onTap: () => push(const RegionPickerScreen()),
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: settings.textScale,
                  builder: (context, scale, _) => ListRow(
                    title: '글자 크기',
                    value: scaleLabel(scale),
                    onTap: () => push(const TextSizeScreen()),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: settings.notifyOn,
                  builder: (context, on, _) => ListRow(
                    title: '알림 받기',
                    value: on ? '켜짐' : '꺼짐',
                    trailing: BigSwitch(value: on),
                    onTap: () => settings.setNotifyOn(!on),
                  ),
                ),
                ListRow(
                  title: '앱 사용법',
                  last: true,
                  onTap: () => push(const HowToScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 78×44 ink-outlined toggle. Purely visual; the enclosing row handles taps
/// and announces 켜짐/꺼짐 in its semantics label.
class BigSwitch extends StatelessWidget {
  const BigSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 78,
        height: 44,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? Tokens.ink : Tokens.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Tokens.ink,
            width: Tokens.borderWidthStrong,
          ),
        ),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: value ? Tokens.onInk : Tokens.ink,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Sub-screen of settings: three text-size choices, each label previewed at
/// the size it would set.
class TextSizeScreen extends StatelessWidget {
  const TextSizeScreen({super.key});

  static const _options = [
    ('보통', Tokens.scaleNormal, 20.0),
    ('크게', Tokens.scaleLarge, 26.0),
    ('아주 크게', Tokens.scaleXLarge, 34.0),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = AppDeps.of(context).settings;
    return Scaffold(
      appBar: const BackBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Tokens.pagePadding,
          0,
          Tokens.pagePadding,
          Tokens.pagePadding + 4,
        ),
        children: [
          const ScreenTitle('글자 크기'),
          for (final (label, scale, size) in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.gap),
              child: ValueListenableBuilder<double>(
                valueListenable: settings.textScale,
                builder: (context, current, _) {
                  final selected = SettingsScreen.scaleLabel(current) == label;
                  return BigButton(
                    label: label,
                    semanticsLabel: selected ? '$label, 지금 이것' : label,
                    variant: ButtonVariant.card,
                    minHeightOverride: 76,
                    alignStart: true,
                    fontSize: size,
                    trailing: selected ? const InkChip('✔ 지금 이것') : null,
                    onPressed: () async {
                      await settings.setTextScale(scale);
                      if (context.mounted) Navigator.of(context).maybePop();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
