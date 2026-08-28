import 'package:shared_preferences/shared_preferences.dart';

/// Local usage counters shown on the "사용 기록" screen so a family member
/// can check whether the app is being used. No server upload; everything
/// stays on the device (SharedPreferences), same storage as [SettingsStore].
class Metrics {
  Metrics._(this._prefs);

  static const String keyOpenCount = 'open_count';
  static const String keyCallTapCount = 'call_tap_count';
  static const String keyPushOpenCount = 'push_open_count';

  final SharedPreferences _prefs;

  static Future<Metrics> load() async =>
      Metrics._(await SharedPreferences.getInstance());

  /// How many times the app was launched.
  int get openCount => _prefs.getInt(keyOpenCount) ?? 0;

  /// How many times the 전화 걸기 button was tapped.
  int get callTapCount => _prefs.getInt(keyCallTapCount) ?? 0;

  /// How many times a push notification was tapped to open the app.
  /// Incremented once P3-M4 wires the notification tap handler; defined
  /// here now so the "사용 기록" screen already has a place to show it.
  int get pushOpenCount => _prefs.getInt(keyPushOpenCount) ?? 0;

  Future<void> incrementOpenCount() => _increment(keyOpenCount);

  Future<void> incrementCallTapCount() => _increment(keyCallTapCount);

  Future<void> incrementPushOpenCount() => _increment(keyPushOpenCount);

  Future<void> _increment(String key) =>
      _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
}
