import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region_item.dart';
import '../theme/tokens.dart';
import '../utils/korean_date.dart';
import '../widgets/big_button.dart';
import '../widgets/item_card.dart';
import '../widgets/persistent_notice.dart';
import '../widgets/surface_card.dart';
import 'call_confirm_screen.dart';
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
  String? _dataNotice;
  bool _dataNoticeShown = false;
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
      _dataNotice = null;
      _dataNoticeShown = false;
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

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<RegionFeed>(
          future: _feedFuture,
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(Tokens.pagePadding),
                child: _Message(
                  text: '일자리를 불러오지 못했어요.',
                  buttonLabel: '다시 시도',
                  onPressed: () => setState(() {
                    _feedFuture = AppDeps.of(context).items
                        .fetchItems(_loadedRegion!);
                  }),
                ),
              );
            }
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Center(
                  child: LinearProgressIndicator(minHeight: Tokens.progressBar),
                ),
              );
            }
            return _buildLoaded(context, snap.data!);
          },
        ),
      ),
    );
  }

  /// Banner text for a stale or cached feed; null when the data is fresh.
  static String? dataNoticeFor(RegionFeed feed, DateTime now) {
    final date = formatKoreanDateTime(feed.generatedAt.toLocal());
    if (feed.fromCache) return '새 정보를 못 받았어요. $date 정보예요.';
    if (now.difference(feed.generatedAt) > staleAfter) {
      return '정보가 오래됐어요. $date 정보예요.';
    }
    return null;
  }

  static const Duration staleAfter = Duration(hours: 48);

  Widget _buildLoaded(BuildContext context, RegionFeed feed) {
    final text = Theme.of(context).textTheme;
    if (!_dataNoticeShown) {
      _dataNoticeShown = true;
      _dataNotice = dataNoticeFor(feed, AppDeps.of(context).clock());
    }
    final items = feed.items;
    final count = items.length;
    final regionName = FutureBuilder<String>(
      future: _regionNameFuture,
      initialData: feed.regionName,
      builder: (context, snap) => Text(
        snap.data ?? feed.regionName,
        style: text.headlineMedium!.copyWith(fontSize: 31),
        maxLines: 2,
        overflow: TextOverflow.visible,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: 동네 바꾸기 · 설정 (two neutral 64dp buttons).
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.pagePadding,
            Tokens.gapSmall,
            Tokens.pagePadding,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: BigButton(
                  label: '동네 바꾸기',
                  variant: ButtonVariant.neutral,
                  fontSize: Tokens.body + 1,
                  onPressed: () => _push(const RegionPickerScreen()),
                ),
              ),
              const SizedBox(width: Tokens.gapSmall),
              Expanded(
                child: BigButton(
                  label: '설정',
                  variant: ButtonVariant.neutral,
                  fontSize: Tokens.body + 1,
                  onPressed: () => _push(const SettingsScreen()),
                ),
              ),
            ],
          ),
        ),
        // Header: region · counter · position bar · date.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.pagePadding,
            Tokens.gap - 2,
            Tokens.pagePadding,
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: regionName),
                  if (count > 0) ...[
                    const SizedBox(width: Tokens.gapSmall),
                    Text(
                      '${_index + 1} / $count',
                      style: text.labelLarge!.copyWith(
                        fontSize: Tokens.body + 1,
                        color: Tokens.muted,
                      ),
                      semanticsLabel: '$count개 중 ${_index + 1}번째',
                    ),
                  ],
                ],
              ),
              if (count > 0) ...[
                const SizedBox(height: 10),
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Tokens.positionBar / 2),
                    child: LinearProgressIndicator(
                      minHeight: Tokens.positionBar,
                      value: (_index + 1) / count,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${formatKoreanDateTime(feed.generatedAt.toLocal())} 기준',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        if (_dataNotice != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.pagePadding,
              0,
              Tokens.pagePadding,
              10,
            ),
            child: PersistentNotice(
              text: _dataNotice!,
              onClose: () => setState(() => _dataNotice = null),
            ),
          ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.pagePadding,
              0,
              Tokens.pagePadding,
              10,
            ),
            child: PersistentNotice(
              text: _notice!,
              onClose: () => setState(() => _notice = null),
            ),
          ),
        Expanded(
          child: count == 0
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Tokens.pagePadding,
                    Tokens.gap,
                    Tokens.pagePadding,
                    Tokens.pagePadding,
                  ),
                  child: _Message(
                    text: '지금은 ${feed.regionName}에\n모집 중인 일자리가 없어요',
                    buttonLabel: '다른 동네 보기',
                    onPressed: () => _push(const RegionPickerScreen()),
                  ),
                )
              : PageView.builder(
                  controller: _pages,
                  itemCount: count,
                  onPageChanged: (i) => setState(() {
                    _index = i;
                    _notice = null;
                  }),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Tokens.pagePadding,
                      0,
                      Tokens.pagePadding,
                      Tokens.gap - 2,
                    ),
                    child: ItemCard(
                      item: items[i],
                      onOpen: () => _push(DetailScreen(item: items[i])),
                      onCall: () => _push(CallConfirmScreen(item: items[i])),
                    ),
                  ),
                ),
        ),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.pagePadding,
              8,
              Tokens.pagePadding,
              Tokens.pagePadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: BigButton(
                    label: '◀ 이전',
                    variant: ButtonVariant.ink,
                    onPressed: () => _go(-1, count),
                  ),
                ),
                const SizedBox(width: Tokens.gap),
                Expanded(
                  child: BigButton(
                    label: '다음 ▶',
                    variant: ButtonVariant.ink,
                    onPressed: () => _go(1, count),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Empty / error state: message card plus one green action.
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
        SurfaceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.gap + 4,
            vertical: 28,
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleLarge!
                .copyWith(fontSize: 27, height: 1.55),
          ),
        ),
        const SizedBox(height: Tokens.cardPadding),
        BigButton(label: buttonLabel, mid: true, onPressed: onPressed),
      ],
    );
  }
}
