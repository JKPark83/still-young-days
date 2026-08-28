import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// White rounded surface with hairline border and the design's soft shadow.
/// Used for the home card, settings rows and the 시군구 list.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.strong = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// 2dp ink border, no shadow (앱 사용법 step cards).
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      strong ? Tokens.radiusSmall : Tokens.radiusLarge,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Tokens.cardBg,
        borderRadius: radius,
        border: Border.all(
          color: strong ? Tokens.fg : Tokens.divider,
          width: strong ? Tokens.borderWidthStrong : Tokens.borderWidth,
        ),
        boxShadow: strong ? null : Tokens.cardShadow,
      ),
      padding: padding,
      child: child,
    );
  }
}
