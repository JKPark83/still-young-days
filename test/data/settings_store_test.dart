import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still_young_days/data/settings_store.dart';

void main() {
  test('defaults: 41570 / 1.0 / notify on / not onboarded', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsStore.load();
    expect(s.regionCode.value, '41570');
    expect(s.textScale.value, 1.0);
    expect(s.notifyOn.value, isTrue);
    expect(s.onboarded.value, isFalse);
  });

  test('regionFromGps: GPS로 정하면 true, 직접 고르면 다시 false', () async {
    SharedPreferences.setMockInitialValues({});
    final a = await SettingsStore.load();
    expect(a.regionFromGps.value, isFalse);

    await a.setRegionCode('41570', fromGps: true);
    expect(a.regionFromGps.value, isTrue);

    final b = await SettingsStore.load();
    expect(b.regionFromGps.value, isTrue);

    await b.setRegionCode('41110');
    expect(b.regionFromGps.value, isFalse);
  });

  test('values survive re-creation', () async {
    SharedPreferences.setMockInitialValues({});
    final a = await SettingsStore.load();
    await a.setRegionCode('41110');
    await a.setTextScale(1.6);
    await a.setNotifyOn(false);
    await a.setOnboarded(true);

    final b = await SettingsStore.load();
    expect(b.regionCode.value, '41110');
    expect(b.textScale.value, 1.6);
    expect(b.notifyOn.value, isFalse);
    expect(b.onboarded.value, isTrue);
  });
}
