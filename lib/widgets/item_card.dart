import 'package:flutter/material.dart';

import '../models/region_item.dart';
import '../theme/tokens.dart';
import 'big_button.dart';

/// Home card: title (wraps, never ellipsised) · place · phone button.
/// Tapping the card body opens the detail screen.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onCall,
  });

  final RegionItem item;
  final VoidCallback onOpen;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '일자리 카드. ${item.title}. ${item.place ?? ''}. 누르면 자세히 봅니다.',
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.cardBg,
          border: Border.all(color: Tokens.cardBorder, width: Tokens.borderWidth),
          borderRadius: BorderRadius.circular(Tokens.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpen,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Tokens.radius),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(Tokens.pagePadding),
                  children: [
                    Text(
                      item.title,
                      style: text.titleLarge,
                      maxLines: null,
                      overflow: TextOverflow.visible,
                    ),
                    if (item.place != null) ...[
                      const SizedBox(height: Tokens.gap),
                      Text(
                        item.place!,
                        style: text.bodyLarge,
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                    const SizedBox(height: Tokens.gap),
                    Text(
                      '자세히 보려면 여기를 누르세요',
                      style: text.bodySmall!.copyWith(color: Tokens.primary),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Tokens.gap),
              child: item.hasPhone
                  ? BigButton(
                      label: '📞 전화하기',
                      semanticsLabel: '전화하기 ${item.phone}',
                      onPressed: onCall,
                    )
                  : BigButton(
                      label: '전화번호가 없어요 · 자세히 보기',
                      secondary: true,
                      onPressed: onOpen,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
