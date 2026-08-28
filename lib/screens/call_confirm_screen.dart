import 'package:flutter/material.dart';

import '../app_deps.dart';
import '../models/region_item.dart';
import '../theme/tokens.dart';
import '../widgets/back_bar.dart';
import '../widgets/big_button.dart';
import '../widgets/persistent_notice.dart';

/// Screen 4b. Shows the number large before dialling so an accidental tap on
/// 전화하기 never places a call by itself.
class CallConfirmScreen extends StatefulWidget {
  /// [item] must have a phone number.
  const CallConfirmScreen({super.key, required this.item});

  final RegionItem item;

  @override
  State<CallConfirmScreen> createState() => _CallConfirmScreenState();
}

class _CallConfirmScreenState extends State<CallConfirmScreen> {
  String? _notice;

  Future<void> _dial() async {
    final phone = widget.item.phone!;
    final navigator = Navigator.of(context);
    final deps = AppDeps.of(context);
    await deps.metrics.incrementCallTapCount();
    final ok = await deps.launchPhone(phone);
    if (!mounted) return;
    if (ok) {
      navigator.maybePop();
    } else {
      setState(() => _notice = '전화를 걸 수 없어요. 번호: $phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const BackBar(),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Tokens.pagePadding + 4,
                  vertical: Tokens.gapSmall,
                ),
                children: [
                  if (item.org != null)
                    Text(
                      item.org!,
                      style: text.bodyLarge!.copyWith(
                        fontSize: Tokens.body + 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: Tokens.gapSmall),
                  Text(
                    item.title,
                    style: text.bodyLarge!.copyWith(
                      color: Tokens.muted,
                      fontSize: Tokens.body + 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Tokens.gap + 4),
                  Text(
                    item.phone!,
                    style: text.displaySmall!.copyWith(
                      fontSize: 46,
                      letterSpacing: 46 * 0.02,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    semanticsLabel: '전화번호 ${item.phone!.split('').join(' ')}',
                  ),
                  if (_notice != null) ...[
                    const SizedBox(height: Tokens.gap),
                    PersistentNotice(
                      text: _notice!,
                      onClose: () => setState(() => _notice = null),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Tokens.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BigButton(
                    label: '📞 전화 걸기',
                    semanticsLabel: '전화 걸기 ${item.phone}',
                    critical: true,
                    onPressed: _dial,
                  ),
                  const SizedBox(height: Tokens.gap),
                  BigButton(
                    label: '안 걸래요',
                    mid: true,
                    variant: ButtonVariant.neutral,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
