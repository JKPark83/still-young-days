import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region_item.dart';
import '../theme/tokens.dart';
import '../utils/korean_date.dart';
import '../widgets/big_button.dart';
import '../widgets/item_card.dart';
import '../widgets/persistent_notice.dart';
import 'detail_screen.dart';
import 'region_picker_screen.dart';
import 'settings_screen.dart';

/// Screen 3 ★. One card at a time; PageView swipe plus 이전/다음 buttons.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialFeed});

  /// Feed already loaded by the splash screen (skips a second fetch).
  final RegionFeed? initialFeed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<RegionFeed> _feedFuture;
  late Future<String> _regionNameFuture;
  late final ValueNotifier<String> _regionCode;
  late final PageController _pages = PageController();
  int _index = 0;
  String? _notice;
  String? _loadedRegion;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final deps = AppDeps.of(context);
    _regionCode = deps.settings.regionCode;
    _loadedRegion = _regionCode.value;
    final initial = widget.initialFeed;
    _feedFuture = initial != null && initial.regionCode == _loadedRegion
        ? Future.value(initial)
        : deps.items.fetchItems(_loadedRegion!);
    _regionNameFuture = deps.regions.nameOf(_loadedRegion!);
    _regionCode.addListener(_onRegionChanged);
  }

  @override
  void dispose() {
    _regionCode.removeListener(_onRegionChanged);
    _pages.dispose();
    super.dispose();
  }

  void _onRegionChanged() {
    final deps = AppDeps.of(context);
    final code = deps.settings.regionCode.value;
    if (code == _loadedRegion) return;
    setState(() {
      _loadedRegion = code;
      _index = 0;
      _notice = null;
      _feedFuture = deps.items.fetchItems(code);
      _regionNameFuture = deps.regions.nameOf(code);
      if (_pages.hasClients) _pages.jumpToPage(0);
    });
  }

  void _go(int delta, int count) {
    final next = _index + delta;
    if (next < 0) {
      setState(() => _notice = '첫 번째 일자리예요.');
      return;
    }
    if (next >= count) {
      setState(() => _notice = '마지막 일자리예요.');
      return;
    }
    setState(() => _notice = null);
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _call(RegionItem item) async {
    final ok = await AppDeps.of(context).launchPhone(item.phone!);
    if (!ok && mounted) {
      setState(() => _notice = '전화를 걸 수 없어요. 번호: ${item.phone}');
    }
  }

  void _openDetail(RegionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DetailScreen(item: item)),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  void _openRegionPicker() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegionPickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<RegionFeed>(
          future: _feedFuture,
          builder: (context, snap) {
            if (snap.hasError) {
              return _Message(
                text: '일자리를 불러오지 못했어요.',
                buttonLabel: '다시 시도',
                onPressed: () => setState(() {
                  _feedFuture =
                      AppDeps.of(context).items.fetchItems(_loadedRegion!);
                }),
              );
            }
            if (!snap.hasData) {
              return const Center(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(strokeWidth: 8),
                ),
              );
            }
            final feed = snap.data!;
            return _buildLoaded(context, feed);
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, RegionFeed feed) {
    final text = Theme.of(context).textTheme;
    final items = feed.items;
    final count = items.length;
    final regionName = FutureBuilder<String>(
      future: _regionNameFuture,
      initialData: feed.regionName,
      builder: (context, snap) => Text(
        snap.data ?? feed.regionName,
        style: text.titleLarge,
        maxLines: 2,
        overflow: TextOverflow.visible,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(Tokens.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    regionName,
                    if (count > 0)
                      Text(
                        '${_index + 1} / $count',
                        style: text.bodyLarge,
                        semanticsLabel: '$count개 중 ${_index + 1}번째',
                      ),
                    Text(
                      '${formatKoreanDateTime(feed.generatedAt.toLocal())} 기준',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Tokens.gap),
              SizedBox(
                width: 120,
                child: BigButton(
                  label: '⚙ 설정',
                  secondary: true,
                  onPressed: _openSettings,
                ),
              ),
            ],
          ),
          if (_notice != null) ...[
            const SizedBox(height: Tokens.gap),
            PersistentNotice(
              text: _notice!,
              onClose: () => setState(() => _notice = null),
            ),
          ],
          const SizedBox(height: Tokens.gap),
          Expanded(
            child: count == 0
                ? _Message(
                    text: '지금은 ${feed.regionName}에 모집 중인 일자리가 없어요.',
                    buttonLabel: '다른 동네 보기',
                    onPressed: _openRegionPicker,
                  )
                : PageView.builder(
                    controller: _pages,
                    itemCount: count,
                    onPageChanged: (i) => setState(() {
                      _index = i;
                      _notice = null;
                    }),
                    itemBuilder: (context, i) => ItemCard(
                      item: items[i],
                      onOpen: () => _openDetail(items[i]),
                      onCall: () => _call(items[i]),
                    ),
                  ),
          ),
          if (count > 0) ...[
            const SizedBox(height: Tokens.gap),
            Row(
              children: [
                Expanded(
                  child: BigButton(
                    label: '◀ 이전',
                    secondary: true,
                    onPressed: () => _go(-1, count),
                  ),
                ),
                const SizedBox(width: Tokens.gap),
                Expanded(
                  child: BigButton(
                    label: '다음 ▶',
                    onPressed: () => _go(1, count),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Tokens.gap * 2),
        BigButton(label: buttonLabel, onPressed: onPressed),
      ],
    );
  }
}
