import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still_young_days/data/settings_store.dart';
import 'package:still_young_days/metrics/metrics.dart';
import 'package:still_young_days/push/push_service.dart';
import 'package:still_young_days/screens/home_screen.dart';
import 'package:still_young_days/screens/settings_screen.dart';

import '../helpers.dart';

/// Records calls instead of touching `firebase_messaging`'s platform
/// channel, so [FcmPushService]'s topic-subscription logic can be tested
/// without a real Firebase project.
class FakeFcmAdapter implements FcmAdapter {
  final List<String> subscribed = [];
  final List<String> unsubscribed = [];
  int permissionRequests = 0;
  bool hasInitialMessage = false;

  final StreamController<void> _taps = StreamController<void>.broadcast();

  @override
  Future<void> requestPermission() async {
    permissionRequests++;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    subscribed.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    unsubscribed.add(topic);
  }

  @override
  Stream<void> get onMessageOpenedApp => _taps.stream;

  @override
  Future<bool> consumeInitialMessage() async => hasInitialMessage;

  void tap() => _taps.add(null);

  void close() => _taps.close();
}

/// Lets pending microtasks scheduled by fire-and-forget calls inside
/// [FcmPushService] finish before assertions run.
Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('isPlaceholderFirebaseOptions', () {
    test(
      'true for the placeholder file committed before flutterfire configure',
      () {
        const options = FirebaseOptions(
          apiKey: 'PLACEHOLDER',
          appId: 'PLACEHOLDER',
          messagingSenderId: 'PLACEHOLDER',
          projectId: 'PLACEHOLDER',
        );
        expect(isPlaceholderFirebaseOptions(options), isTrue);
      },
    );

    test('false once flutterfire configure filled in a real key', () {
      const options = FirebaseOptions(
        apiKey: 'AIzaSyReal-Key-1234567890',
        appId: '1:123:android:abc',
        messagingSenderId: '123',
        projectId: 'still-young-days',
      );
      expect(isPlaceholderFirebaseOptions(options), isFalse);
    });
  });

  group('DisabledPushService', () {
    test('attach and dispose are no-ops', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await SettingsStore.load();
      const service = DisabledPushService();
      service.attach(settings);
      service.dispose();
      // Nothing to assert beyond "didn't throw" — this is the safety net
      // used before Firebase is configured.
    });
  });

  group('FcmPushService topic subscriptions', () {
    late FakeFcmAdapter adapter;
    late Metrics metrics;
    late FcmPushService service;

    setUp(() async {
      adapter = FakeFcmAdapter();
      SharedPreferences.setMockInitialValues({});
      metrics = await Metrics.load();
      service = FcmPushService(adapter: adapter, metrics: metrics);
    });

    tearDown(() {
      service.dispose();
      adapter.close();
    });

    test('(a) 알림을 켜면 권한을 요청하고 지역 토픽을 구독한다', () async {
      final settings = await freshSettings(
        initial: {'notifyOn': false, 'regionCode': '41570'},
      );
      service.attach(settings);
      await flush();
      expect(adapter.permissionRequests, 0);
      expect(adapter.subscribed, isEmpty);

      await settings.setNotifyOn(true);
      await flush();

      expect(adapter.permissionRequests, 1);
      expect(adapter.subscribed, ['region_41570']);
    });

    test('(b) 알림을 끄면 지역 토픽 구독을 해제한다', () async {
      final settings = await freshSettings(
        initial: {'notifyOn': true, 'regionCode': '41570'},
      );
      service.attach(settings);
      await flush();
      expect(adapter.subscribed, ['region_41570']);

      await settings.setNotifyOn(false);
      await flush();

      expect(adapter.unsubscribed, ['region_41570']);
    });

    test('(c) 알림이 켜진 채 동네가 바뀌면 이전 토픽을 해제하고 새 토픽을 구독한다', () async {
      final settings = await freshSettings(
        initial: {'notifyOn': true, 'regionCode': '41570'},
      );
      service.attach(settings);
      await flush();
      expect(adapter.subscribed, ['region_41570']);

      await settings.setRegionCode('11110');
      await flush();

      expect(adapter.unsubscribed, ['region_41570']);
      expect(adapter.subscribed, ['region_41570', 'region_11110']);
      // No repeat permission prompt just for a region change.
      expect(adapter.permissionRequests, 1);
    });

    test('(d) 알림이 꺼진 채 동네가 바뀌면 아무 일도 일어나지 않는다', () async {
      final settings = await freshSettings(
        initial: {'notifyOn': false, 'regionCode': '41570'},
      );
      service.attach(settings);
      await flush();

      await settings.setRegionCode('11110');
      await flush();

      expect(adapter.subscribed, isEmpty);
      expect(adapter.unsubscribed, isEmpty);
      expect(adapter.permissionRequests, 0);
    });

    test('(e) 시작 시 알림이 이미 켜져 있으면 현재 동네 구독을 보장한다', () async {
      final settings = await freshSettings(
        initial: {'notifyOn': true, 'regionCode': '41570'},
      );

      service.attach(settings);
      await flush();

      expect(adapter.permissionRequests, 1);
      expect(adapter.subscribed, ['region_41570']);
    });

    test('알림 탭: onMessageOpenedApp 이벤트마다 눌러 들어온 횟수를 늘린다', () async {
      final settings = await freshSettings();
      service.attach(settings);
      await flush();
      expect(metrics.pushOpenCount, 0);

      adapter.tap();
      await flush();

      expect(metrics.pushOpenCount, 1);
    });

    test('콜드 스타트: 대기 중인 알림이 있었으면 눌러 들어온 횟수를 늘린다', () async {
      adapter.hasInitialMessage = true;
      final settings = await freshSettings();

      service.attach(settings);
      await flush();

      expect(metrics.pushOpenCount, 1);
    });
  });

  testWidgets('알림 탭: 어느 화면에 있었든 홈으로 이동한다', (tester) async {
    final adapter = FakeFcmAdapter();
    addTearDown(adapter.close);
    final metrics = await Metrics.load();
    final navigatorKey = GlobalKey<NavigatorState>();
    final service = FcmPushService(
      adapter: adapter,
      metrics: metrics,
      navigatorKey: navigatorKey,
    );

    await pumpApp(
      tester,
      home: const SettingsScreen(),
      push: service,
      navigatorKey: navigatorKey,
    );
    expect(find.byType(SettingsScreen), findsOneWidget);

    adapter.tap();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });
}
