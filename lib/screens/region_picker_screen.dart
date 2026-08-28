import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region.dart';
import '../theme/tokens.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';
import '../widgets/list_row.dart';
import '../widgets/persistent_notice.dart';
import '../widgets/region_name.dart';
import '../widgets/surface_card.dart';

/// Screen 6. Step 1: 시·도 grid (2 columns, 84dp cards). Step 2: 시군구 rows
/// in one white card. No search box. Back on step 2 returns to step 1.
class RegionPickerScreen extends StatefulWidget {
  const RegionPickerScreen({super.key});

  @override
  State<RegionPickerScreen> createState() => _RegionPickerScreenState();
}

class _RegionPickerScreenState extends State<RegionPickerScreen> {
  Sido? _sido;
  String? _notice;
  bool _locating = false;

  Future<void> _pick(Sigungu sgg) async {
    final navigator = Navigator.of(context);
    await AppDeps.of(context).settings.setRegionCode(sgg.code);
    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _findByLocation() async {
    setState(() {
      _locating = true;
      _notice = null;
    });
    final deps = AppDeps.of(context);
    final navigator = Navigator.of(context);
    final position = await deps.location.current();
    String? code;
    if (position != null) {
      await deps.regionLocator.ensureLoaded();
      code = deps.regionLocator.locate(position.latitude, position.longitude);
    }
    if (!mounted) return;
    if (code == null) {
      setState(() {
        _locating = false;
        _notice = '내 동네를 찾지 못했어요. 목록에서 골라 주세요.';
      });
      return;
    }
    await deps.settings.setRegionCode(code);
    if (!mounted) return;
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppDeps.of(context);
    final text = Theme.of(context).textTheme;
    final nameStyle = text.titleLarge!.copyWith(fontSize: 30, letterSpacing: 0);
    return Scaffold(
      appBar: BackBar(
        onBack: _sido == null ? null : () => setState(() => _sido = null),
      ),
      body: FutureBuilder<List<Sido>>(
        future: deps.regions.fetchSido(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: LinearProgressIndicator(minHeight: Tokens.progressBar),
              ),
            );
          }
          final sidoList = snap.data!;
          return ListView(
            padding: const EdgeInsets.only(bottom: Tokens.cardPadding),
            children: [
              // Header block with a hairline underneath.
              Container(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.pagePadding,
                  Tokens.gap,
                  Tokens.pagePadding,
                  Tokens.gapSmall,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Tokens.divider,
                      width: Tokens.borderWidth,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_sido == null) ...[
                      Text(
                        '지금 내 동네',
                        style: text.bodySmall!.copyWith(fontSize: 18),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: deps.settings.regionCode,
                        builder: (context, code, _) => RegionName(
                          code: code,
                          builder: (context, name) =>
                              Text(name, style: nameStyle),
                        ),
                      ),
                      const SizedBox(height: Tokens.gapSmall),
                      BigButton(
                        label: _locating ? '위치를 찾는 중이에요' : '내 위치로 다시 찾기',
                        variant: ButtonVariant.neutral,
                        fontSize: Tokens.body + 2,
                        onPressed: _locating ? null : _findByLocation,
                      ),
                      if (_notice != null) ...[
                        const SizedBox(height: Tokens.gapSmall),
                        PersistentNotice(
                          text: _notice!,
                          onClose: () => setState(() => _notice = null),
                        ),
                      ],
                    ] else ...[
                      Text(
                        '고른 시 · 도',
                        style: text.bodySmall!.copyWith(fontSize: 18),
                      ),
                      Text(_sido!.name, style: nameStyle),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.pagePadding,
                  Tokens.gap - 2,
                  Tokens.pagePadding,
                  6,
                ),
                child: Text(
                  _sido == null ? '시 · 도를 고르세요' : '동네를 고르세요',
                  style: text.titleLarge!.copyWith(letterSpacing: 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.pagePadding,
                  6,
                  Tokens.pagePadding,
                  0,
                ),
                child: _sido == null
                    ? _SidoGrid(
                        sidoList: sidoList,
                        onPick: (s) => setState(() => _sido = s),
                      )
                    : ValueListenableBuilder<String>(
                        valueListenable: deps.settings.regionCode,
                        builder: (context, current, _) => SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, sgg) in _sido!.sigungu.indexed)
                                ListRow(
                                  title: sgg.name,
                                  chip: sgg.code == current ? '✔ 지금 여기' : null,
                                  last: i == _sido!.sigungu.length - 1,
                                  semanticsLabel: sgg.code == current
                                      ? '${sgg.name}, 지금 여기'
                                      : sgg.name,
                                  onTap: () => _pick(sgg),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SidoGrid extends StatelessWidget {
  const _SidoGrid({required this.sidoList, required this.onPick});

  final List<Sido> sidoList;
  final ValueChanged<Sido> onPick;

  @override
  Widget build(BuildContext context) {
    Widget cell(Sido s) => BigButton(
      label: s.name,
      variant: ButtonVariant.card,
      minHeightOverride: Tokens.gridCell,
      fontSize: Tokens.body + 1,
      onPressed: () => onPick(s),
    );
    final rows = <Widget>[];
    for (var i = 0; i < sidoList.length; i += 2) {
      final left = sidoList[i];
      final right = i + 1 < sidoList.length ? sidoList[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: Tokens.gap - 2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cell(left)),
                const SizedBox(width: Tokens.gap - 2),
                Expanded(
                  child: right == null ? const SizedBox.shrink() : cell(right),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
