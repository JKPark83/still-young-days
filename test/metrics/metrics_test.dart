import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still_young_days/metrics/metrics.dart';

void main() {
  test('defaults: all counters start at 0', () async {
    SharedPreferences.setMockInitialValues({});
    final m = await Metrics.load();
    expect(m.openCount, 0);
    expect(m.callTapCount, 0);
    expect(m.pushOpenCount, 0);
  });

  test('increment methods count independently', () async {
    SharedPreferences.setMockInitialValues({});
    final m = await Metrics.load();

    await m.incrementOpenCount();
    await m.incrementOpenCount();
    await m.incrementCallTapCount();
    await m.incrementPushOpenCount();
    await m.incrementPushOpenCount();
    await m.incrementPushOpenCount();

    expect(m.openCount, 2);
    expect(m.callTapCount, 1);
    expect(m.pushOpenCount, 3);
  });

  test('counts survive re-creation', () async {
    SharedPreferences.setMockInitialValues({});
    final a = await Metrics.load();
    await a.incrementOpenCount();
    await a.incrementCallTapCount();

    final b = await Metrics.load();
    expect(b.openCount, 1);
    expect(b.callTapCount, 1);
    expect(b.pushOpenCount, 0);
  });
}
