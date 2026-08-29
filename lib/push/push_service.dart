import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../metrics/metrics.dart';
import '../screens/home_screen.dart';

/// True until `flutterfire configure` overwrites `lib/firebase_options.dart`
/// with real project credentials. `main.dart` checks this before calling
/// `Firebase.initializeApp` so the app runs push-free until then.
bool isPlaceholderFirebaseOptions(FirebaseOptions options) =>
    options.apiKey.startsWith('PLACEHOLDER');

/// Thin wrapper over `firebase_messaging`'s static API so [FcmPushService]'s
/// topic-subscription logic can be unit-tested with a fake, without ever
/// touching a platform channel.
abstract interface class FcmAdapter {
  /// Requests notification permission (Android 13+'s POST_NOTIFICATIONS,
  /// iOS alert/sound/badge). Safe to call more than once.
  Future<void> requestPermission();

  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  /// Fires when the user taps a notification while the app process is
  /// already running (foreground or background).
  Stream<void> get onMessageOpenedApp;

  /// True when the app was cold-started by tapping a notification. Meant to
  /// be checked once, right after [attach].
  Future<bool> consumeInitialMessage();
}

/// Real implementation backed by `package:firebase_messaging`.
class FirebaseFcmAdapter implements FcmAdapter {
  const FirebaseFcmAdapter();

  @override
  Future<void> requestPermission() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  @override
  Future<void> subscribeToTopic(String topic) =>
      FirebaseMessaging.instance.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      FirebaseMessaging.instance.unsubscribeFromTopic(topic);

  @override
  Stream<void> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map((_) {});

  @override
  Future<bool> consumeInitialMessage() async =>
      await FirebaseMessaging.instance.getInitialMessage() != null;
}

/// Keeps the device's push-notification subscription in sync with app
/// settings. [DisabledPushService] is the default while Firebase isn't
/// configured (or failed to start); [FcmPushService] does the real work.
abstract interface class PushService {
  /// Starts reconciling notification topic subscriptions with [settings].
  /// Call once, right after the settings store has loaded.
  void attach(SettingsStore settings);

  /// Removes listeners added by [attach]. Safe to call even if [attach] was
  /// never called.
  void dispose();
}

/// No-op push service used before Firebase is configured (placeholder
/// options) or when initialising it failed. The app behaves exactly as
/// before — alerts only show up when the user opens the app themselves.
class DisabledPushService implements PushService {
  const DisabledPushService();

  @override
  void attach(SettingsStore settings) {}

  @override
  void dispose() {}
}

/// Reconciles FCM topic subscriptions with [SettingsStore.notifyOn] /
/// [SettingsStore.regionCode], and records + routes notification taps.
///
/// Rules (이슈 #10):
/// - 알림 켜짐 → 권한 요청 + `region_{code}` 구독.
/// - 알림 꺼짐 → 구독 해제.
/// - 알림이 켜진 채로 동네가 바뀜 → 이전 지역 구독 해제 + 새 지역 구독.
/// - 시작 시 이미 켜져 있으면 현재 동네 구독을 다시 보장한다
///   (subscribeToTopic은 멱등이라 반복 호출해도 안전).
class FcmPushService implements PushService {
  FcmPushService({
    required this.adapter,
    required this.metrics,
    this.navigatorKey,
  });

  final FcmAdapter adapter;
  final Metrics metrics;

  /// Lets a notification tap leave whatever screen the user was on and land
  /// on the home screen. Null where navigation isn't needed (most tests).
  final GlobalKey<NavigatorState>? navigatorKey;

  SettingsStore? _settings;
  String? _subscribedTopic;
  StreamSubscription<void>? _tapSubscription;

  static String _topicFor(String regionCode) => 'region_$regionCode';

  @override
  void attach(SettingsStore settings) {
    _settings = settings;
    settings.notifyOn.addListener(_onNotifyChanged);
    settings.regionCode.addListener(_onRegionChanged);
    _tapSubscription = adapter.onMessageOpenedApp.listen((_) => _onTap());
    if (settings.notifyOn.value) {
      unawaited(_turnOn(settings.regionCode.value));
    }
    unawaited(_checkInitialMessage());
  }

  @override
  void dispose() {
    _settings?.notifyOn.removeListener(_onNotifyChanged);
    _settings?.regionCode.removeListener(_onRegionChanged);
    _settings = null;
    unawaited(_tapSubscription?.cancel());
    _tapSubscription = null;
  }

  void _onNotifyChanged() {
    final settings = _settings;
    if (settings == null) return;
    if (settings.notifyOn.value) {
      unawaited(_turnOn(settings.regionCode.value));
    } else {
      unawaited(_unsubscribeCurrent());
    }
  }

  void _onRegionChanged() {
    final settings = _settings;
    if (settings == null || !settings.notifyOn.value) return;
    unawaited(_subscribe(settings.regionCode.value));
  }

  Future<void> _turnOn(String regionCode) async {
    await adapter.requestPermission();
    await _subscribe(regionCode);
  }

  Future<void> _subscribe(String regionCode) async {
    final topic = _topicFor(regionCode);
    if (_subscribedTopic == topic) return;
    final previous = _subscribedTopic;
    if (previous != null) await adapter.unsubscribeFromTopic(previous);
    await adapter.subscribeToTopic(topic);
    _subscribedTopic = topic;
  }

  Future<void> _unsubscribeCurrent() async {
    final previous = _subscribedTopic;
    if (previous == null) return;
    await adapter.unsubscribeFromTopic(previous);
    _subscribedTopic = null;
  }

  void _onTap() {
    unawaited(metrics.incrementPushOpenCount());
    navigatorKey?.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// Cold start: the app already flows splash → home on its own, so this
  /// only needs to record the tap, not force a navigation.
  Future<void> _checkInitialMessage() async {
    if (await adapter.consumeInitialMessage()) {
      await metrics.incrementPushOpenCount();
    }
  }
}
