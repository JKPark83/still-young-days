import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';
import '../widgets/screen_title.dart';
import '../widgets/surface_card.dart';

/// Screen 7. Four numbered steps, each with a small screen sketch on the right.
class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Tokens.pagePadding,
          0,
          Tokens.pagePadding,
          Tokens.pagePadding,
        ),
        children: const [
          ScreenTitle('앱 사용법'),
          _Step(number: '①', text: '화면에 일자리가 한 개씩 나와요', sketch: _CardSketch()),
          _Step(
            number: '②',
            text: '다음 버튼을 누르면 다른 일자리를 봐요',
            sketch: _NextSketch(),
          ),
          _Step(number: '③', text: '마음에 들면 전화하기를 누르세요', sketch: _CallSketch()),
          _Step(
            number: '④',
            text: '글자가 작으면 설정에서 크게 바꿔요',
            sketch: _SizeSketch(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.pagePadding,
            4,
            Tokens.pagePadding,
            Tokens.pagePadding,
          ),
          child: BigButton(
            label: '알겠어요',
            critical: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, required this.sketch});

  final String number;
  final String text;
  final Widget sketch;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gap),
      child: SurfaceCard(
        strong: true,
        padding: const EdgeInsets.all(Tokens.gap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: t.headlineMedium!.copyWith(
                      fontSize: 38,
                      height: 1,
                      color: Tokens.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: t.bodyLarge!.copyWith(fontSize: Tokens.body + 1),
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Tokens.gap - 2),
            ExcludeSemantics(child: _Phone(child: sketch)),
          ],
        ),
      ),
    );
  }
}

/// 88×104 phone outline holding a sketch.
class _Phone extends StatelessWidget {
  const _Phone({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 104,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Tokens.fg, width: Tokens.borderWidthStrong),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

BoxDecoration _box({Color? color, Color? border, double radius = 6}) =>
    BoxDecoration(
      color: color,
      border: border == null ? null : Border.all(color: border, width: 2),
      borderRadius: BorderRadius.circular(radius),
    );

class _CardSketch extends StatelessWidget {
  const _CardSketch();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FractionallySizedBox(
          widthFactor: 0.6,
          child: Container(
            height: 10,
            decoration: _box(color: Tokens.divider, radius: 3),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: _box(color: Tokens.noticeBg, border: Tokens.fg),
          ),
        ),
      ],
    );
  }
}

class _NextSketch extends StatelessWidget {
  const _NextSketch();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: _box(border: Tokens.divider),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 22,
                decoration: _box(border: Tokens.fg, radius: 5),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 22,
                decoration: _box(color: Tokens.ink, radius: 5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CallSketch extends StatelessWidget {
  const _CallSketch();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: _box(border: Tokens.divider),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 30,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: _box(color: Tokens.primary),
          child: const Text(
            '📞',
            style: TextStyle(fontSize: 14, color: Tokens.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _SizeSketch extends StatelessWidget {
  const _SizeSketch();

  @override
  Widget build(BuildContext context) {
    TextStyle style(double size) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: Tokens.fg,
      height: 1.1,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('가', style: style(12)),
        Text('가', style: style(20)),
        Text('가', style: style(30)),
      ],
    );
  }
}
