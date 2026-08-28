import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 32sp screen heading with a hairline underneath (설정 · 글자 크기 · 앱 사용법).
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: Tokens.gapSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.headlineMedium,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: Tokens.gap - 2),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
