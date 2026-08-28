import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Label + value block for the detail screen, separated by a hairline above.
/// Callers must filter null/empty values out — this widget never renders
/// a "정보 없음" placeholder.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value})
    : assert(value != '', 'InfoRow must not be built with an empty value');

  final String label;
  final String value;

  /// Returns null when [value] is missing so the caller can drop the row.
  static InfoRow? maybe(String label, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return InfoRow(label: label, value: value);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.only(top: Tokens.gap, bottom: Tokens.gap + 2),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Tokens.divider, width: Tokens.borderWidth),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: text.bodyLarge!.copyWith(fontSize: Tokens.body + 1),
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}
