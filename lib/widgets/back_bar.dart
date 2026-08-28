import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Fixed top bar holding only the big "◀ 뒤로" button (neutral, 64dp).
/// Used as [Scaffold.appBar] so it never scrolls away. Screen headings are
/// rendered in the body with [ScreenTitle].
class BackBar extends StatelessWidget implements PreferredSizeWidget {
  const BackBar({super.key, this.onBack, this.divider = false});

  final VoidCallback? onBack;

  /// Hairline under the bar (detail screen).
  final bool divider;

  static const double height = Tokens.buttonMin + Tokens.gapSmall * 2;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Tokens.bg,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: height,
          decoration: divider
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Tokens.divider,
                      width: Tokens.borderWidth,
                    ),
                  ),
                )
              : null,
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.pagePadding,
            vertical: Tokens.gapSmall,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: BackButtonBig(onBack: onBack),
          ),
        ),
      ),
    );
  }
}

/// The "◀ 뒤로" button on its own (home top row uses it inline).
class BackButtonBig extends StatelessWidget {
  const BackButtonBig({super.key, this.onBack, this.expand = false});

  final VoidCallback? onBack;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: '뒤로 가기',
      child: FilledButton(
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        style: FilledButton.styleFrom(
          foregroundColor: Tokens.fg,
          backgroundColor: Tokens.neutralBg,
          minimumSize: const Size(Tokens.buttonMin, Tokens.buttonMin),
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.gap + 6,
            vertical: Tokens.gapSmall,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusSmall),
          ),
        ),
        child: Text(
          '◀ 뒤로',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(height: 1.4),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
