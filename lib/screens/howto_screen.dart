import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';

/// Screen 7. Three numbered steps with a small illustration each.
class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackBar(title: '앱 사용법'),
      body: ListView(
        padding: const EdgeInsets.all(Tokens.pagePadding),
        children: const [
          _Step(
            number: '①',
            text: '화면에 일자리가 한 개씩 나와요.',
            illustration: _CardIllustration(),
          ),
          _Step(
            number: '②',
            text: '"다음 ▶" 버튼을 누르면 다른 일자리를 봐요.',
            illustration: _ButtonIllustration(label: '다음 ▶'),
          ),
          _Step(
            number: '③',
            text: '마음에 들면 "📞 전화하기"를 누르세요.',
            illustration: _ButtonIllustration(label: '📞 전화하기'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.pagePadding),
          child: BigButton(
            label: '알겠어요',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.text,
    required this.illustration,
  });

  final String number;
  final String text;
  final Widget illustration;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gap * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(number, style: t.headlineMedium!.copyWith(color: Tokens.primary)),
              const SizedBox(width: Tokens.gap),
              Expanded(child: Text(text, style: t.bodyLarge)),
            ],
          ),
          const SizedBox(height: Tokens.gap),
          ExcludeSemantics(child: illustration),
        ],
      ),
    );
  }
}

/// Miniature of the home card so the step is recognisable at a glance.
class _CardIllustration extends StatelessWidget {
  const _CardIllustration();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Tokens.gap),
      decoration: BoxDecoration(
        border: Border.all(color: Tokens.fg, width: Tokens.borderWidth),
        borderRadius: BorderRadius.circular(Tokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('공원 환경정비', style: t.titleLarge),
          Text('김포시 사우동', style: t.bodyLarge),
          const SizedBox(height: Tokens.gap / 2),
          const _ButtonIllustration(label: '📞 전화하기'),
        ],
      ),
    );
  }
}

class _ButtonIllustration extends StatelessWidget {
  const _ButtonIllustration({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Tokens.buttonMin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Tokens.primary,
        borderRadius: BorderRadius.circular(Tokens.radius),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(color: Tokens.onPrimary),
      ),
    );
  }
}
