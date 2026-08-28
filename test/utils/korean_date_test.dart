import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/utils/korean_date.dart';

void main() {
  test('2026-08-29 → 8월 29일 (토), 2026-08-30 → 8월 30일 (일)', () {
    // The plan's example "8월 30일 (토)" is from a different year;
    // in 2026 Aug 30 falls on a Sunday.
    expect(formatKoreanDate('2026-08-29'), '8월 29일 (토)');
    expect(formatKoreanDate('2026-08-30'), '8월 30일 (일)');
  });

  test('range and one-sided range', () {
    expect(
      formatKoreanDateRange('2026-08-25', '2026-09-07'),
      '8월 25일 (화) ~ 9월 7일 (월)',
    );
    expect(formatKoreanDateRange('2026-08-25', null), '8월 25일 (화)부터');
    expect(formatKoreanDateRange(null, '2026-09-07'), '9월 7일 (월)까지');
    expect(formatKoreanDateRange(null, null), isNull);
  });
}
