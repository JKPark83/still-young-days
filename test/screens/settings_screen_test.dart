import 'package:flutter_test/flutter_test.dart';
import 'package:still_young_days/screens/call_confirm_screen.dart';
import 'package:still_young_days/screens/settings_screen.dart';

import '../helpers.dart';

void main() {
  testWidgets('사용 기록 row sits below 앱 사용법 and opens the usage screen', (
    tester,
  ) async {
    usePhoneView(tester);
    await pumpApp(
      tester,
      home: const SettingsScreen(),
      prefs: {'open_count': 3, 'call_tap_count': 2, 'push_open_count': 1},
    );

    expect(find.text('앱 사용법'), findsOneWidget);
    expect(find.text('사용 기록'), findsOneWidget);

    await tester.tap(find.text('사용 기록'));
    await tester.pumpAndSettle();

    expect(find.byType(UsageStatsScreen), findsOneWidget);
    expect(find.text('앱을 연 횟수'), findsOneWidget);
    expect(find.text('3번'), findsOneWidget);
    expect(find.text('전화 버튼을 누른 횟수'), findsOneWidget);
    expect(find.text('2번'), findsOneWidget);
    expect(find.text('알림을 눌러 들어온 횟수'), findsOneWidget);
    expect(find.text('1번'), findsOneWidget);
  });

  testWidgets('usage screen shows 0번 for a fresh install', (tester) async {
    usePhoneView(tester);
    await pumpApp(tester, home: const UsageStatsScreen());

    expect(find.text('0번'), findsNWidgets(3));
  });

  testWidgets('tapping 전화 걸기 increments the call-tap count', (tester) async {
    usePhoneView(tester);
    final deps = await pumpApp(
      tester,
      home: CallConfirmScreen(item: sampleItem()),
    );
    expect(deps.metrics.callTapCount, 0);

    await tester.tap(find.text('📞 전화 걸기'));
    await tester.pumpAndSettle();

    expect(deps.metrics.callTapCount, 1);
    expect(deps.phone.calls, ['031-000-0001']);
  });
}
