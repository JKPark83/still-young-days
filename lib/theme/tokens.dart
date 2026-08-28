import 'package:flutter/material.dart';

/// Design tokens imported from the Claude Design project
/// "오늘도청춘 — 화면 7개" (StillYoungDays.dc.html), 2026-08-28.
///
/// Contrast ratios (WCAG relative luminance, verified by
/// `test/theme/tokens_test.dart`):
///   fg #17191A on bg #F4F4F2            = 16.0 : 1  (>= 7.0 AAA)
///   muted #474C4F on bg #F4F4F2         =  7.9 : 1
///   onPrimary #FFFFFF on primary #0B5C41 =  8.0 : 1
///   onInk #FFFFFF on ink #17191A         = 17.6 : 1
///   noticeFg #5C4200 on noticeBg #FBF0D9 =  8.3 : 1
abstract final class Tokens {
  // Font sizes (sp). Never use these for padding or heights.
  static const double caption = 17;
  static const double body = 20;
  static const double bodyLarge = 23; // detail values, card place
  static const double title = 24; // section titles, button labels
  static const double buttonCritical = 28; // 88dp button labels
  static const double screenTitle = 32;
  static const double cardTitle = 34; // job title on the home card
  static const double appName = 64; // splash

  // Touch targets (dp).
  static const double buttonMin = 64;
  static const double buttonMid =
      72; // secondary actions next to a critical one
  static const double buttonCriticalHeight = 88; // 전화하기 · 알겠어요
  static const double listRow = 82; // settings / 시군구 rows
  static const double gridCell = 84; // 시·도 grid cells
  static const double gap = 16; // 14~16 range, upper bound adopted
  static const double gapSmall = 12;
  static const double pagePadding = 16;
  static const double cardPadding = 24;
  static const double borderWidth = 1;
  static const double borderWidthStrong = 2;
  static const double radius = 16;
  static const double radiusSmall = 14;
  static const double radiusLarge = 20;
  static const double progressBar = 20; // splash bar height
  static const double positionBar = 6; // home position bar height

  static const double lineHeight = 1.5;
  static const double letterSpacingTight = -0.02; // em, headings
  static const double letterSpacingLabel = 0.05; // em, small labels

  static const String fontFamily = 'Pretendard';

  // Palette. Colors live here only.
  static const Color bg = Color(0xFFF4F4F2);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color fg = Color(0xFF17191A);
  static const Color muted = Color(0xFF474C4F);
  static const Color primary = Color(0xFF0B5C41); // green: 전화하기 · 알겠어요
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF17191A); // 이전 · 다음
  static const Color onInk = Color(0xFFFFFFFF);
  static const Color neutralBg = Color(0xFFE8E9E6); // 뒤로 · 설정 · 직접 고를게요
  static const Color divider = Color(0xFFE2E3DF);
  static const Color cardBorder = Color(0xFFDCDEDA);
  static const Color track = Color(0xFFE2E3DF);
  static const Color noticeBg = Color(0xFFFBF0D9);
  static const Color noticeBorder = Color(0xFFEBDCB4);
  static const Color noticeFg = Color(0xFF5C4200);
  static const Color hairline = Color(0xFFC7CAC6);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0D17191A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x5917191A),
      offset: Offset(0, 18),
      blurRadius: 36,
      spreadRadius: -22,
    ),
  ];
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(color: Color(0x0D17191A), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: Color(0x990B5C41),
      offset: Offset(0, 12),
      blurRadius: 26,
      spreadRadius: -14,
    ),
  ];

  // Text scale steps chosen in settings: 보통 100% · 크게 140% · 아주 크게 200%.
  static const double scaleNormal = 1.0;
  static const double scaleLarge = 1.4;
  static const double scaleXLarge = 2.0;
  static const double clampMin = 1.0;
  static const double clampMax = 2.0;
}
