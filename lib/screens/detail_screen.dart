import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region_item.dart';
import '../theme/tokens.dart';
import '../utils/korean_date.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';
import '../widgets/info_row.dart';
import '../widgets/persistent_notice.dart';

/// Screen 4. Info rows for present fields only; the 72dp call button is pinned
/// to the bottom so it stays visible while scrolling.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item});

  final RegionItem item;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String? _notice;

  Future<void> _call() async {
    final phone = widget.item.phone!;
    final ok = await AppDeps.of(context).launchPhone(phone);
    if (!ok && mounted) {
      setState(() => _notice = '전화를 걸 수 없어요. 번호: $phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final text = Theme.of(context).textTheme;
    final rows = <InfoRow?>[
      InfoRow.maybe('하는 일', item.description),
      InfoRow.maybe('장소', item.address),
      InfoRow.maybe('모집 나이', item.age),
      InfoRow.maybe('신청 기간', formatKoreanDateRange(item.applyStart, item.applyEnd)),
      InfoRow.maybe('기관', item.org),
    ].whereType<InfoRow>().toList(growable: false);

    return Scaffold(
      appBar: const BackBar(title: '자세히 보기'),
      body: ListView(
        padding: const EdgeInsets.all(Tokens.pagePadding),
        children: [
          Text(
            item.title,
            style: text.titleLarge,
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: Tokens.gap),
          if (_notice != null) ...[
            PersistentNotice(
              text: _notice!,
              onClose: () => setState(() => _notice = null),
            ),
            const SizedBox(height: Tokens.gap),
          ],
          ...rows,
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.pagePadding),
          child: item.hasPhone
              ? BigButton(
                  label: '📞 전화하기',
                  semanticsLabel: '전화하기 ${item.phone}',
                  critical: true,
                  onPressed: _call,
                )
              : const PersistentNotice(text: '이 일자리는 전화번호가 없어요.'),
        ),
      ),
    );
  }
}
