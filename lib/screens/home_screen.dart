import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region_item.dart';
import '../theme/tokens.dart';
import '../utils/korean_date.dart';
import '../widgets/big_button.dart';
import '../widgets/coverage_notice.dart';
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
  late Future<({String code, String name})?> _neighborFuture;
  late final ValueNotifier<String> _regionCode;
  late final ValueNotifier<ItemType> _lastKind;
  ItemType _kind = ItemType.job;
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
    _lastKind = deps.settings.lastKind;
    _kind = _lastKind.value;
    _loadedRegion = _regionCode.value;
    final initial = widget.initialFeed;
    // The splash fetched with the same lastKind, so a code match is enough.
    _feedFuture = initial != null && initial.regionCode == _loadedRegion
        ? Future.value(initial)
        : deps.items.fetchItems(_loadedRegion!, kind: _kind);
    _regionNameFuture = deps.regions.nameOf(_loadedRegion!);
    _neighborFuture = _loadNeighbor(deps, _loadedRegion!);
    _regionCode.addListener(_onRegionChanged);
    _lastKind.addListener(_onKindChanged);
  }

  /// Name of the first neighboring 시군구, for the empty-list "옆 동네 보기"
  /// button; null when [code] has no recorded neighbor.
  static Future<({String code, String name})?> _loadNeighbor(
    AppDeps deps,
    String code,
  ) async {
    final neighborCode = await deps.neighbors.firstNeighborOf(code);
    if (neighborCode == null) return null;
    final name = await deps.regions.nameOf(neighborCode);
    return (code: neighborCode, name: name);
  }

  @override
  void dispose() {
    _regionCode.removeListener(_onRegionChanged);
    _lastKind.removeListener(_onKindChanged);
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
      _feedFuture = deps.items.fetchItems(code, kind: _kind);
      _regionNameFuture = deps.regions.nameOf(code);
      _neighborFuture = _loadNeighbor(deps, code);
      if (_pages.hasClients) _pages.jumpToPage(0);
    });
  }

  void _onKindChanged() {
    final deps = AppDeps.of(context);
    final kind = deps.settings.lastKind.value;
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _index = 0;
      _notice = null;
      _dataNotice = null;
      _dataNoticeShown = false;
      _feedFuture = deps.items.fetchItems(_loadedRegion!, kind: kind);
      if (_pages.hasClients) _pages.jumpToPage(0);
    });
  }

  /// "일자리" or "행사" for user-facing notices.
  String get _kindWord => _kind == ItemType.event ? '행사' : '일자리';

  /// Empty 행사 tab. 아직 커버하는 복지관이 없으면 준비 중임을 솔직히
  /// 알리고 일자리 탭으로 유도한다; 커버 중인데 글이 없을 뿐이면 다른
  /// 동네 보기를 권한다.
  Widget _emptyEvents(RegionFeed feed) {
    return FutureBuilder<String>(
      future: _regionNameFuture,
      initialData: feed.regionName.isEmpty ? null : feed.regionName,
      builder: (context, snap) {
        final name = snap.data ?? '우리 동네';
        final coverage = feed.coverage;
        final preparing = coverage == null || coverage.centersCovered == 0;
        return _Message(
          text: preparing
              ? '$name 복지관 행사 소식은\n아직 준비 중이에요'
              : '지금은 $name 복지관에\n올라온 행사가 없어요',
          buttonLabel: '일자리 보기',
          onPressed: () =>
              AppDeps.of(context).settings.setLastKind(ItemType.job),
          secondaryLabel: preparing ? null : '다른 동네 보기',
          onSecondaryPressed: preparing
              ? null
              : () => _push(const RegionPickerScreen()),
        );
      },
    );
  }

  /// One side of the 일자리 | 복지관 행사 segment.
  Widget _kindTab(ItemType kind, String label) {
    final selected = _kind == kind;
    return BigButton(
      label: selected ? '✓ $label' : label,
      variant: selected ? ButtonVariant.ink : ButtonVariant.neutral,
      fontSize: Tokens.body + 1,
      semanticsLabel: selected ? '$label 탭, 선택됨' : '$label 탭',
      onPressed: () => AppDeps.of(context).settings.setLastKind(kind),
    );
  }

  void _go(int delta, int count) {
    final next = _index + delta;
    if (next < 0) {
      setState(() => _notice = '첫 번째 $_kindWord예요.');
      return;
    }
    if (next >= count) {
      setState(() => _notice = '마지막 $_kindWord예요.');
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
                  text: '$_kindWord를 불러오지 못했어요.',
                  buttonLabel: '다시 시도',
                  onPressed: () => setState(() {
                    _feedFuture = AppDeps.of(context).items
                        .fetchItems(_loadedRegion!, kind: _kind);
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

    final chrome = <Widget>[
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
      // 일자리 | 복지관 행사 segment: the picked side gets the dark ink
      // background plus a ✓ so color is never the only cue.
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Tokens.pagePadding,
          Tokens.gapSmall,
          Tokens.pagePadding,
          0,
        ),
        child: Row(
          children: [
            Expanded(child: _kindTab(ItemType.job, '일자리')),
            const SizedBox(width: Tokens.gapSmall),
            Expanded(child: _kindTab(ItemType.event, '복지관 행사')),
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
      if (_kind == ItemType.event &&
          count > 0 &&
          feed.coverage != null &&
          feed.coverage!.centersCovered > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.pagePadding,
            0,
            Tokens.pagePadding,
            10,
          ),
          child: FutureBuilder<String>(
            future: _regionNameFuture,
            initialData: feed.regionName.isEmpty ? null : feed.regionName,
            builder: (context, snap) => CoverageNotice(
              regionName: snap.data ?? '우리 동네',
              coverage: feed.coverage!,
            ),
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
    ];
    final Widget cardArea = count == 0
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.pagePadding,
              Tokens.gap,
              Tokens.pagePadding,
              Tokens.pagePadding,
            ),
            child: _kind == ItemType.event
                ? _emptyEvents(feed)
                : FutureBuilder<({String code, String name})?>(
                    future: _neighborFuture,
                    builder: (context, snap) {
                      final neighbor = snap.data;
                      return _Message(
                        text: '지금은 ${feed.regionName}에\n모집 중인 일자리가 없어요',
                        buttonLabel: '다른 동네 보기',
                        onPressed: () => _push(const RegionPickerScreen()),
                        secondaryLabel: neighbor == null
                            ? null
                            : '옆 동네(${neighbor.name}) 보기',
                        onSecondaryPressed: neighbor == null
                            ? null
                            : () =>
                                  AppDeps.of(context).settings
                                      .setRegionCode(neighbor.code),
                      );
                    },
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
          );
    final Widget? nav = count == 0
        ? null
        : Padding(
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
          );

    // 아주 크게(1.4 초과) 배율에서는 위쪽 구역이 화면보다 커질 수 있어
    // 카드 위쪽을 스크롤로 전환한다. 이전/다음 줄은 항상 하단에 남긴다.
    return LayoutBuilder(
      builder: (context, box) {
        final scaled =
            MediaQuery.textScalerOf(context).scale(Tokens.body) / Tokens.body;
        if (scaled <= Tokens.scaleLarge) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...chrome,
              Expanded(child: cardArea),
              ?nav,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...chrome,
                    // 카드는 화면의 2/3 높이. 넘치는 내용은 카드 내부
                    // 스크롤이 처리한다.
                    SizedBox(height: box.maxHeight * 2 / 3, child: cardArea),
                  ],
                ),
              ),
            ),
            ?nav,
          ],
        );
      },
    );
  }
}

/// Empty / error state: message card plus one green action, plus an
/// optional neutral second action (옆 동네 보기).
class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

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
        if (secondaryLabel != null) ...[
          const SizedBox(height: Tokens.gapSmall),
          BigButton(
            label: secondaryLabel!,
            mid: true,
            variant: ButtonVariant.neutral,
            onPressed: onSecondaryPressed,
          ),
        ],
      ],
    );
  }
}
