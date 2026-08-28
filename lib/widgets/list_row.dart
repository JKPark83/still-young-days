import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 82dp tappable row inside a [SurfaceCard]: title · optional value · trailing.
/// Rows are separated by a hairline; the last row passes [last] to drop it.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    required this.onTap,
    this.value,
    this.trailing,
    this.chip,
    this.last = false,
    this.semanticsLabel,
  });

  final String title;
  final String? value;
  final VoidCallback onTap;

  /// Widget before the ▶ arrow (switch).
  final Widget? trailing;

  /// Ink chip text such as "✔ 지금 여기".
  final String? chip;
  final bool last;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final titleStyle = text.labelLarge!.copyWith(
      fontSize: Tokens.body + 2,
      height: 1.4,
    );
    return Semantics(
      button: true,
      label:
          semanticsLabel ??
          (value == null || value!.isEmpty ? title : '$title, 현재 $value'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: Tokens.listRow),
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.gap + 2,
              vertical: Tokens.gap,
            ),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(
                      bottom: BorderSide(
                        color: Tokens.divider,
                        width: Tokens.borderWidth,
                      ),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                ),
                if (value != null && value!.isNotEmpty) ...[
                  const SizedBox(width: Tokens.gapSmall),
                  Flexible(
                    child: Text(
                      value!,
                      style: text.bodyLarge!.copyWith(
                        color: Tokens.muted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
                if (chip != null) ...[
                  const SizedBox(width: Tokens.gapSmall),
                  InkChip(chip!),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: Tokens.gapSmall),
                  trailing!,
                ] else ...[
                  const SizedBox(width: Tokens.gapSmall),
                  Text('▶', style: titleStyle),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small ink pill with white text ("✔ 지금 이것").
class InkChip extends StatelessWidget {
  const InkChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Tokens.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!
            .copyWith(color: Tokens.onInk, letterSpacing: 0, height: 1.3),
      ),
    );
  }
}
