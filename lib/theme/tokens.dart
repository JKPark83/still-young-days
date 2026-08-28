import 'package:flutter/material.dart';

/// Design tokens copied verbatim from the spec's "노안 대응 UI/UX 설계 기준".
///
/// Contrast ratios (WCAG relative-luminance formula, verified by
/// `test/theme/tokens_test.dart`):
///   fg #1A1A1A on bg #FFFFFF          = 17.4 : 1  (>= 7.0 AAA)
///   onPrimary #FFFFFF on primary #0B5394 = 7.8 : 1 (>= 7.0 AAA)
abstract final class Tokens {
  // Font sizes (sp). Never use these for padding or heights.
  static const double body = 20; // 18~20 range, upper bound adopted
  static const double title = 24;
  static const double headline = 36; // splash app name
  static const double caption = 16;

  // Touch targets (dp).
  static const double buttonMin = 64;
  static const double buttonCritical = 72;
  static const double gap = 16; // 12~16 range, upper bound adopted
  static const double pagePadding = 20;
  static const double borderWidth = 3;
  static const double radius = 16;

  static const double lineHeight = 1.5;
  static const double letterSpacingRatio = 0.12;

  // Palette. Colors live here only.
  static const Color bg = Color(0xFFFFFFFF);
  static const Color fg = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFF0B5394);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFF1A1A1A);
  static const Color noticeBg = Color(0xFFFFF4CC); // light yellow, fg on it = 15.6:1
  static const Color divider = Color(0xFF1A1A1A);

  // Text scale steps chosen in settings (assumption, open issue #4).
  static const double scaleNormal = 1.0;
  static const double scaleLarge = 1.3;
  static const double scaleXLarge = 1.6;
  static const double clampMin = 1.0;
  static const double clampMax = 2.0;
}
