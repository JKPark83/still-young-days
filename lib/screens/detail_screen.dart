import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  bool get _isEvent => item.type == ItemType.event;

  /// "9월 7일 (월)" or "9월 15일 (화) ~ 12월 8일 (화)"; null when undated.
  String? get _eventWhen {
    final start = item.eventDate;
    final end = item.eventEnd;
    if (start == null) return null;
    if (end == null) return formatKoreanDate(start);
    return '${formatKoreanDate(start)} ~ ${formatKoreanDate(end)}';
  }

  Future<void> _openSource() async {
    final url = item.sourceUrl;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object {
      // The 복지관 page failing to open must never crash the app.
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows =
        (_isEvent
                ? <InfoRow?>[
                    InfoRow.maybe('언제', _eventWhen),
                    InfoRow.maybe('어디서', item.address ?? item.place),
                    InfoRow.maybe('내용', item.description),
                    InfoRow.maybe('기관', item.org),
                  ]
                : <InfoRow?>[
                    InfoRow.maybe('하는 일', item.description),
                    InfoRow.maybe('장소', item.address),
                    InfoRow.maybe('모집 나이', item.age),
                    InfoRow.maybe(
                      '신청 기간',
                      formatKoreanDateRange(item.applyStart, item.applyEnd),
                    ),
                    InfoRow.maybe('기관', item.org),
                  ])
            .whereType<InfoRow>()
            .toList(growable: false);

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
          if (_isEvent && item.sourceUrl != null) ...[
            const SizedBox(height: Tokens.gap),
            BigButton(
              label: '원문 보기',
              variant: ButtonVariant.neutral,
              mid: true,
              semanticsLabel: '복지관 홈페이지에서 원문 보기',
              onPressed: _openSource,
            ),
          ],
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
