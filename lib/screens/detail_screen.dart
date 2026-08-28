import 'package:flutter/material.dart';

import '../models/region_item.dart';
import '../theme/tokens.dart';
import '../utils/korean_date.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';
import '../widgets/info_row.dart';
import '../widgets/persistent_notice.dart';
import 'call_confirm_screen.dart';

/// Screen 4. Info rows for present fields only; the 88dp call button is pinned
/// to the bottom so it stays visible while scrolling. Tapping it opens the
/// number-confirmation screen.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.item});

  final RegionItem item;

  void _openCall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CallConfirmScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = <InfoRow?>[
      InfoRow.maybe('하는 일', item.description),
      InfoRow.maybe('장소', item.address),
      InfoRow.maybe('모집 나이', item.age),
      InfoRow.maybe(
        '신청 기간',
        formatKoreanDateRange(item.applyStart, item.applyEnd),
      ),
      InfoRow.maybe('기관', item.org),
    ].whereType<InfoRow>().toList(growable: false);

    return Scaffold(
      appBar: const BackBar(divider: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Tokens.pagePadding,
          Tokens.pagePadding + 4,
          Tokens.pagePadding,
          Tokens.cardPadding,
        ),
        children: [
          Text(
            item.title,
            style: text.titleLarge!.copyWith(fontSize: 30, height: 1.45),
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: Tokens.gap - 2),
          const Divider(),
          const SizedBox(height: Tokens.gap + 6),
          ...rows,
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Tokens.bg,
          border: Border(
            top: BorderSide(color: Tokens.divider, width: Tokens.borderWidth),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.pagePadding,
              Tokens.gap - 2,
              Tokens.pagePadding,
              Tokens.pagePadding,
            ),
            child: item.hasPhone
                ? BigButton(
                    label: '📞 전화하기',
                    semanticsLabel: '전화하기 ${item.phone}',
                    critical: true,
                    onPressed: () => _openCall(context),
                  )
                : PersistentNotice(
                    title: '전화번호가 없어요',
                    text: '${item.org ?? '모집 기관'}에 직접 방문해서 물어보세요.',
                    minHeight: Tokens.buttonCriticalHeight,
                  ),
          ),
        ),
      ),
    );
  }
}
