import 'package:flutter/material.dart';

import '../models/region_item.dart';
import '../theme/tokens.dart';
import '../utils/korean_date.dart';
import 'big_button.dart';
import 'surface_card.dart';

/// Home card: title (wraps, never ellipsised) · 장소 · phone button.
/// 행사 cards swap the 장소 block for one line of "날짜 · 복지관"
/// (복지관 only when the post has no date). Tapping the card body opens
/// the detail screen.
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

  static const String hint = '카드를 누르면 자세히 볼 수 있어요';

  bool get _isEvent => item.type == ItemType.event;

  /// "9월 7일 (월) · 김포시노인종합복지관"; 복지관 only when the post has
  /// no date, null when neither is known.
  String? get eventLine {
    final name = item.place ?? item.org;
    final date = item.eventDate == null
        ? null
        : formatKoreanDate(item.eventDate!);
    if (date == null) return name;
    return name == null ? date : '$date · $name';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label:
          '${_isEvent ? '행사' : '일자리'} 카드. ${item.title}. '
          '${(_isEvent ? eventLine : item.place) ?? ''}. 누르면 자세히 봅니다.',
      // The whole card scrolls when large text makes it taller than the
      // viewport; at normal sizes it fills the available height.
      child: SurfaceCard(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: _body(text)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.cardPadding - 2,
                Tokens.cardPadding,
                Tokens.cardPadding - 2,
                Tokens.gap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.title,
                    style: text.displaySmall,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                  if (_isEvent && eventLine != null) ...[
                    const SizedBox(height: Tokens.gap),
                    Container(
                      padding: const EdgeInsets.only(top: Tokens.gap),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Tokens.divider,
                            width: Tokens.borderWidth,
                          ),
                        ),
                      ),
                      child: Text(
                        eventLine!,
                        style: text.bodyLarge!.copyWith(
                          fontSize: Tokens.bodyLarge,
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ] else if (!_isEvent && item.place != null) ...[
                    const SizedBox(height: Tokens.gap),
                    Container(
                      padding: const EdgeInsets.only(top: Tokens.gap),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Tokens.divider,
                            width: Tokens.borderWidth,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('장소', style: text.labelMedium),
                          const SizedBox(height: 6),
                          Text(
                            item.place!,
                            style: text.bodyLarge!.copyWith(
                              fontSize: Tokens.bodyLarge,
                            ),
                            maxLines: null,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.cardPadding - 2,
            0,
            Tokens.cardPadding - 2,
            Tokens.cardPadding - 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onOpen,
                child: Text(hint, style: text.bodySmall),
              ),
              const SizedBox(height: Tokens.gapSmall),
              item.hasPhone
                  ? BigButton(
                      label: '📞 전화하기',
                      semanticsLabel: '전화하기 ${item.phone}',
                      onPressed: onCall,
                    )
                  : BigButton(
                      label: '전화번호가 없어요 · 자세히 보기',
                      variant: ButtonVariant.neutral,
                      onPressed: onOpen,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
