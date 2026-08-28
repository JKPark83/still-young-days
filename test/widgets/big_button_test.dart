import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/theme/app_theme.dart';
import 'package:still_young_days/widgets/big_button.dart';

Widget _wrap(Widget child, {double scale = 1.0}) => MaterialApp(
  theme: buildAppTheme(),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('default height >= 64dp', (tester) async {
    await tester.pumpWidget(_wrap(BigButton(label: '다음 ▶', onPressed: () {})));
    expect(
      tester.getSize(find.byType(BigButton)).height,
      greaterThanOrEqualTo(64),
    );
  });

  testWidgets('critical height >= 72dp', (tester) async {
    await tester.pumpWidget(
      _wrap(BigButton(label: '📞 전화하기', critical: true, onPressed: () {})),
    );
    expect(
      tester.getSize(find.byType(BigButton)).height,
      greaterThanOrEqualTo(72),
    );
  });

  testWidgets('label wraps at 2.0 text scale without overflow', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 320,
          child: BigButton(
            label: '전화번호가 없어요 · 자세히 보기',
            secondary: true,
            onPressed: () {},
          ),
        ),
        scale: 2.0,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('전화번호가 없어요 · 자세히 보기'), findsOneWidget);
    expect(
      tester.getSize(find.byType(BigButton)).height,
      greaterThanOrEqualTo(64),
    );
  });

  test('empty label is rejected', () {
    expect(
      () => BigButton(label: '  ', onPressed: () {}),
      throwsAssertionError,
    );
  });
}
