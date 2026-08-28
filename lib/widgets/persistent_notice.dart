import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A banner that never disappears on its own (SnackBar/Toast replacement).
/// Give [onClose] to show a "닫기" button; omit it for a permanent notice.
class PersistentNotice extends StatelessWidget {
  const PersistentNotice({super.key, required this.text, this.onClose});

  final String text;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Tokens.noticeBg,
          border: Border.all(color: Tokens.fg, width: Tokens.borderWidth),
          borderRadius: BorderRadius.circular(Tokens.radius),
        ),
        padding: const EdgeInsets.all(Tokens.gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
            if (onClose != null) ...[
              const SizedBox(height: Tokens.gap / 2),
              Semantics(
                button: true,
                label: '안내 닫기',
                child: OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Tokens.fg,
                    backgroundColor: Tokens.bg,
                    minimumSize: const Size(double.infinity, Tokens.buttonMin),
                    side: const BorderSide(
                      color: Tokens.fg,
                      width: Tokens.borderWidth,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Tokens.radius),
                    ),
                  ),
                  child: Text(
                    '닫기',
                    style: Theme.of(context).textTheme.labelLarge,
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
