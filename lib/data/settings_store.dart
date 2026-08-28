import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the four user settings. Each value is a [ValueNotifier] so the
/// app root (text scale) and the home screen (region) can rebuild on change.
class SettingsStore {
  SettingsStore._(this._prefs);

  static const String keyRegionCode = 'regionCode';
  static const String keyTextScale = 'textScale';
  static const String keyNotifyOn = 'notifyOn';
  static const String keyOnboarded = 'onboarded';

  static const String defaultRegionCode = '41570'; // 김포시 (P1 hard-coded)

  final SharedPreferences _prefs;

  late final ValueNotifier<String> regionCode =
      ValueNotifier(_prefs.getString(keyRegionCode) ?? defaultRegionCode);
  late final ValueNotifier<double> textScale =
      ValueNotifier(_prefs.getDouble(keyTextScale) ?? 1.0);
  late final ValueNotifier<bool> notifyOn =
      ValueNotifier(_prefs.getBool(keyNotifyOn) ?? true);
  late final ValueNotifier<bool> onboarded =
      ValueNotifier(_prefs.getBool(keyOnboarded) ?? false);

  static Future<SettingsStore> load() async =>
      SettingsStore._(await SharedPreferences.getInstance());

  Future<void> setRegionCode(String code) async {
    regionCode.value = code;
    await _prefs.setString(keyRegionCode, code);
  }

  Future<void> setTextScale(double scale) async {
    textScale.value = scale;
    await _prefs.setDouble(keyTextScale, scale);
  }

  Future<void> setNotifyOn(bool on) async {
    notifyOn.value = on;
    await _prefs.setBool(keyNotifyOn, on);
  }

  Future<void> setOnboarded(bool done) async {
    onboarded.value = done;
    await _prefs.setBool(keyOnboarded, done);
  }
}
