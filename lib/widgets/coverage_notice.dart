import 'package:flutter/material.dart';

import '../models/region_item.dart';
import 'persistent_notice.dart';

/// Honest 복지관 커버리지 line above the 행사 list:
/// "지금 김포시 복지관 2곳 중 1곳 정보를 보여드려요".
/// Callers handle the 0곳/모름 case themselves (empty state) — this widget
/// only renders when at least one 복지관 is covered.
class CoverageNotice extends StatelessWidget {
  const CoverageNotice({
    super.key,
    required this.regionName,
    required this.coverage,
  });

  final String regionName;
  final RegionCoverage coverage;

  @override
  Widget build(BuildContext context) {
    return PersistentNotice(
      text:
          '지금 $regionName 복지관 ${coverage.centersTotal}곳 중 '
          '${coverage.centersCovered}곳 정보를 보여드려요.',
    );
  }
}
