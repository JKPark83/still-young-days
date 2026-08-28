import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Fixed top bar: a big "◀ 뒤로" button plus the screen title.
/// Used as [Scaffold.appBar] so it never scrolls away.
class BackBar extends StatelessWidget implements PreferredSizeWidget {
  const BackBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  static const double height = Tokens.buttonMin + Tokens.gap;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Tokens.bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.pagePadding,
              vertical: Tokens.gap / 2,
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: '뒤로 가기',
                  child: OutlinedButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Tokens.primary,
                      backgroundColor: Tokens.bg,
                      minimumSize: const Size(Tokens.buttonMin, Tokens.buttonMin),
                      padding: const EdgeInsets.symmetric(horizontal: Tokens.gap),
                      side: const BorderSide(
                        color: Tokens.primary,
                        width: Tokens.borderWidth,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Tokens.radius),
                      ),
                    ),
                    child: Text(
                      '◀ 뒤로',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .copyWith(color: Tokens.primary),
                    ),
                  ),
                ),
                const SizedBox(width: Tokens.gap),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
