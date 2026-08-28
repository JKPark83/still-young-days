/// "2026-08-30" → "8월 30일 (토)". No intl dependency.
const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

String formatKoreanDate(String isoDate) {
  final d = DateTime.parse(isoDate);
  return formatKoreanDateTime(d);
}

String formatKoreanDateTime(DateTime d) {
  final wd = _weekdays[d.weekday - DateTime.monday];
  return '${d.month}월 ${d.day}일 ($wd)';
}

/// "2026-08-25", "2026-09-07" → "8월 25일 (화) ~ 9월 7일 (월)".
/// Either side may be null.
String? formatKoreanDateRange(String? start, String? end) {
  if (start == null && end == null) return null;
  if (start != null && end != null) {
    return '${formatKoreanDate(start)} ~ ${formatKoreanDate(end)}';
  }
  if (start != null) return '${formatKoreanDate(start)}부터';
  return '${formatKoreanDate(end!)}까지';
}
