import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region.dart';
import '../theme/tokens.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';
import '../widgets/persistent_notice.dart';
import '../widgets/region_name.dart';

/// Screen 6. Step 1: 시/도 grid (2 columns, ≥72dp). Step 2: 시군구 list.
/// No search box. Back on step 2 returns to step 1.
class RegionPickerScreen extends StatefulWidget {
  const RegionPickerScreen({super.key});

  @override
  State<RegionPickerScreen> createState() => _RegionPickerScreenState();
}

class _RegionPickerScreenState extends State<RegionPickerScreen> {
  Sido? _sido;
  String? _notice;

  Future<void> _pick(Sigungu sgg) async {
    final navigator = Navigator.of(context);
    await AppDeps.of(context).settings.setRegionCode(sgg.code);
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppDeps.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: BackBar(
        title: _sido == null ? '내 동네 고르기' : _sido!.name,
        onBack: _sido == null
            ? null
            : () => setState(() {
                  _sido = null;
                }),
      ),
      body: FutureBuilder<List<Sido>>(
        future: deps.regions.fetchSido(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 8));
          }
          final sidoList = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(Tokens.pagePadding),
            children: [
              ValueListenableBuilder<String>(
                valueListenable: deps.settings.regionCode,
                builder: (context, code, _) => RegionName(
                  code: code,
                  builder: (context, name) => Text(
                    '지금 동네: $name',
                    style: text.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: Tokens.gap),
              BigButton(
                label: '📍 내 위치로 다시 찾기',
                secondary: true,
                onPressed: () => setState(() {
                  _notice = '내 위치로 찾기는 다음 단계에서 준비돼요.';
                }),
              ),
              if (_notice != null) ...[
                const SizedBox(height: Tokens.gap),
                PersistentNotice(
                  text: _notice!,
                  onClose: () => setState(() => _notice = null),
                ),
              ],
              const SizedBox(height: Tokens.gap),
              if (_sido == null) ...[
                Text('시/도를 고르세요', style: text.bodyLarge),
                const SizedBox(height: Tokens.gap / 2),
                _SidoGrid(
                  sidoList: sidoList,
                  onPick: (s) => setState(() => _sido = s),
                ),
              ] else ...[
                Text('시/군/구를 고르세요', style: text.bodyLarge),
                const SizedBox(height: Tokens.gap / 2),
                for (final sgg in _sido!.sigungu)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Tokens.gap),
                    child: BigButton(
                      label: sgg.name,
                      secondary: true,
                      onPressed: () => _pick(sgg),
                    ),
                  ),
              ],
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
    final rows = <Widget>[];
    for (var i = 0; i < sidoList.length; i += 2) {
      final left = sidoList[i];
      final right = i + 1 < sidoList.length ? sidoList[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: Tokens.gap),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: BigButton(
                    label: left.name,
                    critical: true,
                    secondary: true,
                    onPressed: () => onPick(left),
                  ),
                ),
                const SizedBox(width: Tokens.gap),
                Expanded(
                  child: right == null
                      ? const SizedBox.shrink()
                      : BigButton(
                          label: right.name,
                          critical: true,
                          secondary: true,
                          onPressed: () => onPick(right),
                        ),
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
