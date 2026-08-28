import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Label + value row for the detail screen.
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
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelLarge!.copyWith(color: Tokens.primary),
          ),
          const SizedBox(height: Tokens.gap / 4),
          Text(
            value,
            style: text.bodyLarge,
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: Tokens.gap / 2),
          const Divider(thickness: 1, height: 1),
        ],
      ),
    );
  }
}
