import 'package:flutter/material.dart';

import 'tokens.dart';

/// Assembles [ThemeData] from [Tokens]. No color or size literal outside this
/// file and tokens.dart.
ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: Tokens.primary,
    onPrimary: Tokens.onPrimary,
    secondary: Tokens.ink,
    onSecondary: Tokens.onInk,
    surface: Tokens.bg,
    onSurface: Tokens.fg,
    error: Color(0xFF9B1C1C),
    onError: Tokens.onPrimary,
  );

  TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = Tokens.fg,
    double spacingEm = 0,
    double height = Tokens.lineHeight,
  }) => TextStyle(
    fontFamily: Tokens.fontFamily,
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: size * spacingEm,
    color: color,
  );

  final textTheme = TextTheme(
    // App name on the splash.
    displayLarge: style(
      Tokens.appName,
      weight: FontWeight.w500,
      spacingEm: Tokens.letterSpacingTight,
      height: 1.2,
    ),
    // Job title on the home card.
    displaySmall: style(
      Tokens.cardTitle,
      weight: FontWeight.w500,
      spacingEm: Tokens.letterSpacingTight,
      height: 1.4,
    ),
    // Screen headings (설정 · 글자 크기 · 앱 사용법 · 어느 동네에 사시나요?).
    headlineMedium: style(
      Tokens.screenTitle,
      weight: FontWeight.w500,
      spacingEm: Tokens.letterSpacingTight,
      height: 1.4,
    ),
    // Section titles, region name, detail title.
    titleLarge: style(
      Tokens.title,
      weight: FontWeight.w500,
      spacingEm: Tokens.letterSpacingTight,
    ),
    titleMedium: style(Tokens.title, weight: FontWeight.w500),
    bodyLarge: style(Tokens.body),
    bodyMedium: style(Tokens.body),
    bodySmall: style(Tokens.caption, color: Tokens.muted),
    // Button labels.
    labelLarge: style(Tokens.title, weight: FontWeight.w500),
    // Small field labels (장소 · 하는 일 …).
    labelMedium: style(
      Tokens.caption,
      weight: FontWeight.w500,
      color: Tokens.muted,
      spacingEm: Tokens.letterSpacingLabel,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: Tokens.fontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.bg,
    textTheme: textTheme,
    dividerColor: Tokens.divider,
    dividerTheme: const DividerThemeData(
      color: Tokens.divider,
      thickness: Tokens.borderWidth,
      space: Tokens.borderWidth,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Tokens.bg,
      foregroundColor: Tokens.fg,
      elevation: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Tokens.primary,
      linearTrackColor: Tokens.track,
    ),
  );
}
