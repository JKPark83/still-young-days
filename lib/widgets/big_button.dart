import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The only button in the app. Always has a text label; height is a dp
/// constant (never derived from sp) so Android 14 non-linear font scaling
/// cannot shrink the touch target.
class BigButton extends StatelessWidget {
  BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.critical = false,
    this.secondary = false,
    this.semanticsLabel,
  }) : assert(label.trim().isNotEmpty, 'BigButton requires a text label');

  final String label;
  final VoidCallback? onPressed;

  /// Irreversible / key actions (phone call) get the 72dp height.
  final bool critical;

  /// Outlined variant: bg background, primary text, thick primary border.
  final bool secondary;
  final String? semanticsLabel;

  double get minHeight => critical ? Tokens.buttonCritical : Tokens.buttonMin;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
          fontSize: critical ? Tokens.title : Tokens.body,
          color: secondary ? Tokens.primary : Tokens.onPrimary,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Tokens.radius),
      side: secondary
          ? const BorderSide(color: Tokens.primary, width: Tokens.borderWidth)
          : BorderSide.none,
    );
    final child = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.gap,
        vertical: Tokens.gap / 2,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: textStyle,
        maxLines: null,
        overflow: TextOverflow.visible,
      ),
    );
    final button = secondary
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: Tokens.bg,
              foregroundColor: Tokens.primary,
              minimumSize: Size(double.infinity, minHeight),
              padding: EdgeInsets.zero,
              shape: shape,
              side: shape.side,
            ),
            child: child,
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Tokens.primary,
              foregroundColor: Tokens.onPrimary,
              minimumSize: Size(double.infinity, minHeight),
              padding: EdgeInsets.zero,
              shape: shape,
            ),
            child: child,
          );
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: button,
      ),
    );
  }
}
