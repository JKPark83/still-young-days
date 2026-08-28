import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Visual role of a [BigButton]. Colors follow the design's rule: green only
/// for the key action (전화하기 · 알겠어요), ink for 이전/다음, neutral for
/// navigation, card-white for pickable options.
enum ButtonVariant { primary, ink, neutral, card }

/// The only button in the app. Always has a text label; height is a dp
/// constant (never derived from sp) so Android 14 non-linear font scaling
/// cannot shrink the touch target.
class BigButton extends StatelessWidget {
  BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.critical = false,
    this.mid = false,
    bool secondary = false,
    ButtonVariant? variant,
    this.semanticsLabel,
    this.minHeightOverride,
    this.trailing,
    this.alignStart = false,
    this.fontSize,
  }) : assert(label.trim().isNotEmpty, 'BigButton requires a text label'),
       variant =
           variant ??
           (secondary ? ButtonVariant.neutral : ButtonVariant.primary);

  final String label;
  final VoidCallback? onPressed;

  /// Irreversible / key actions (phone call, 알겠어요) get the 88dp height
  /// and the larger label.
  final bool critical;

  /// Secondary action placed next to a critical one (72dp).
  final bool mid;

  final ButtonVariant variant;
  final String? semanticsLabel;

  /// Explicit min height for list rows / grid cells.
  final double? minHeightOverride;

  /// Optional widget after the label (chip, ▶).
  final Widget? trailing;

  /// Left-align the label (list rows). Default is centred.
  final bool alignStart;

  /// Label size override (text-size preview buttons).
  final double? fontSize;

  double get minHeight =>
      minHeightOverride ??
      (critical
          ? Tokens.buttonCriticalHeight
          : mid
          ? Tokens.buttonMid
          : Tokens.buttonMin);

  Color get _bg => switch (variant) {
    ButtonVariant.primary => Tokens.primary,
    ButtonVariant.ink => Tokens.ink,
    ButtonVariant.neutral => Tokens.neutralBg,
    ButtonVariant.card => Tokens.cardBg,
  };

  Color get _fg => switch (variant) {
    ButtonVariant.primary => Tokens.onPrimary,
    ButtonVariant.ink => Tokens.onInk,
    ButtonVariant.neutral || ButtonVariant.card => Tokens.fg,
  };

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
      fontSize: fontSize ?? (critical ? Tokens.buttonCritical : Tokens.title),
      color: _fg,
      height: 1.4,
    );
    final radius = critical ? Tokens.radiusLarge - 2 : Tokens.radius;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: variant == ButtonVariant.card
          ? const BorderSide(
              color: Tokens.cardBorder,
              width: Tokens.borderWidth,
            )
          : BorderSide.none,
    );
    final text = Text(
      label,
      textAlign: alignStart ? TextAlign.start : TextAlign.center,
      style: textStyle,
      maxLines: null,
      overflow: TextOverflow.visible,
    );
    final child = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.gap,
        vertical: Tokens.gapSmall,
      ),
      child: trailing == null && !alignStart
          ? text
          : Row(
              children: [
                Expanded(child: text),
                if (trailing != null) ...[
                  const SizedBox(width: Tokens.gapSmall),
                  trailing!,
                ],
              ],
            ),
    );
    final shadow = switch (variant) {
      ButtonVariant.primary => Tokens.primaryShadow,
      ButtonVariant.card => Tokens.buttonShadow,
      _ => const <BoxShadow>[],
    };
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _bg,
        foregroundColor: _fg,
        minimumSize: Size(double.infinity, minHeight),
        padding: EdgeInsets.zero,
        shape: shape,
        elevation: 0,
      ),
      child: child,
    );
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow.isEmpty ? null : shadow,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: button,
        ),
      ),
    );
  }
}
