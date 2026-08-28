import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/theme/tokens.dart';

double _channel(int c) {
  final s = c / 255;
  return s <= 0.03928
      ? s / 12.92
      : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) =>
    0.2126 * _channel((c.r * 255).round()) +
    0.7152 * _channel((c.g * 255).round()) +
    0.0722 * _channel((c.b * 255).round());

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('Tokens match the spec', () {
    test('body font >= 18sp, caption >= 16sp, title >= 24sp', () {
      expect(Tokens.body, greaterThanOrEqualTo(18));
      expect(Tokens.caption, greaterThanOrEqualTo(16));
      expect(Tokens.title, greaterThanOrEqualTo(24));
    });

    test('buttons >= 64dp, critical >= 72dp, gap 12..16dp', () {
      expect(Tokens.buttonMin, greaterThanOrEqualTo(64));
      expect(Tokens.buttonCriticalHeight, greaterThanOrEqualTo(72));
      expect(Tokens.gap, inInclusiveRange(12, 16));
    });

    test('line height >= 1.5', () {
      expect(Tokens.lineHeight, greaterThanOrEqualTo(1.5));
    });

    test('contrast fg/bg and onPrimary/primary >= 7:1 (AAA)', () {
      final fgBg = contrast(Tokens.fg, Tokens.bg);
      final btn = contrast(Tokens.onPrimary, Tokens.primary);
      final notice = contrast(Tokens.noticeFg, Tokens.noticeBg);
      // Values are recorded in tokens.dart; keep them in sync.
      expect(fgBg, greaterThanOrEqualTo(7.0), reason: 'fg/bg = $fgBg');
      expect(
        btn,
        greaterThanOrEqualTo(7.0),
        reason: 'onPrimary/primary = $btn',
      );
      expect(
        notice,
        greaterThanOrEqualTo(7.0),
        reason: 'noticeFg/noticeBg = $notice',
      );
      expect(contrast(Tokens.primary, Tokens.bg), greaterThanOrEqualTo(7.0));
    });
  });
}
