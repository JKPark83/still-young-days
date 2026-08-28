import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A banner that never disappears on its own (SnackBar/Toast replacement).
/// Give [onClose] to show a "닫기" button; omit it for a permanent notice.
/// [title] renders a bold first line above [text].
class PersistentNotice extends StatelessWidget {
  const PersistentNotice({
    super.key,
    required this.text,
    this.title,
    this.onClose,
    this.minHeight,
  });

  final String text;
  final String? title;
  final VoidCallback? onClose;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge!
        .copyWith(color: Tokens.noticeFg);
    final strong = body.copyWith(fontWeight: FontWeight.w500);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: minHeight ?? 0),
        decoration: BoxDecoration(
          color: Tokens.noticeBg,
          border: Border.all(
            color: Tokens.noticeBorder,
            width: Tokens.borderWidth,
          ),
          borderRadius: BorderRadius.circular(Tokens.radius),
        ),
        padding: const EdgeInsets.all(Tokens.gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: strong,
                maxLines: null,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              text,
              style: title == null && onClose != null ? strong : body,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
            if (onClose != null) ...[
              const SizedBox(height: Tokens.gapSmall),
              Semantics(
                button: true,
                label: '안내 닫기',
                child: FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    foregroundColor: Tokens.onPrimary,
                    backgroundColor: Tokens.noticeFg,
                    minimumSize: const Size(double.infinity, Tokens.buttonMin),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                    ),
                  ),
                  child: Text(
                    '닫기',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Tokens.onPrimary,
                      fontSize: Tokens.body + 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
