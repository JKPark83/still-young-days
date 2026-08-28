import 'package:flutter/material.dart';

import 'tokens.dart';

/// Assembles [ThemeData] from [Tokens]. No color or size literal outside this
/// file and tokens.dart.
ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: Tokens.primary,
    onPrimary: Tokens.onPrimary,
    secondary: Tokens.primary,
    onSecondary: Tokens.onPrimary,
    surface: Tokens.bg,
    onSurface: Tokens.fg,
    error: Color(0xFF9B1C1C),
    onError: Tokens.onPrimary,
  );

  TextStyle style(double size, {FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontSize: size,
        height: Tokens.lineHeight,
        fontWeight: weight,
        letterSpacing: size * Tokens.letterSpacingRatio / 4,
        color: Tokens.fg,
      );

  final textTheme = TextTheme(
    displayLarge: style(Tokens.headline, weight: FontWeight.w500),
    headlineMedium: style(Tokens.headline, weight: FontWeight.w500),
    titleLarge: style(Tokens.title, weight: FontWeight.w500),
    titleMedium: style(Tokens.title, weight: FontWeight.w500),
    bodyLarge: style(Tokens.body),
    bodyMedium: style(Tokens.body),
    bodySmall: style(Tokens.caption),
    labelLarge: style(Tokens.body, weight: FontWeight.w500),
    labelMedium: style(Tokens.caption, weight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.bg,
    textTheme: textTheme,
    dividerColor: Tokens.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: Tokens.bg,
      foregroundColor: Tokens.fg,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Tokens.onPrimary : Tokens.fg,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Tokens.primary : Tokens.bg,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Tokens.fg),
      trackOutlineWidth: const WidgetStatePropertyAll(Tokens.borderWidth),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Tokens.primary,
    ),
  );
}
