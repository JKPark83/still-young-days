# CLAUDE.md

## 프로젝트 개요

**오늘도청춘 (Still Young Days)** — 70대 어르신을 위한 내 동네 노인 일자리 알림 Flutter 앱.
P1(목 JSON 기반 7화면 UI) 완료, P2(실데이터 연결) 진행 중. 상세 계획은 `docs/plan/`, 아이디어 원문은 `ideas/`, P1 인수인계는 `docs/handoff/` 참고. 데이터 파이프라인은 별도 리포(`~/myworkspace/still-young-days-data`).

## 실행·검증 명령

```bash
# 주의(2026-08-28 기준): 이 Mac에는 README의 ~/development/flutter(3.47.2)가 없고
# homebrew Flutter 3.41.7(Dart 3.11.5)만 있어 pubspec 요구(^3.13.2)보다 낮다.
# 빌드/테스트 전에 Flutter 3.47.2+ 설치 또는 업그레이드가 필요하다.
flutter pub get
flutter analyze        # 경고 0 유지
flutter test           # 전체 테스트 통과 유지 (현재 53건)
flutter run -d <device>                                                    # 목 데이터(기본)
flutter run -d <device> --dart-define=FEED_BASE_URL=https://<host>/data/   # 실데이터
```

- `FEED_BASE_URL` 없으면 `MockItemRepository`, 있으면 `RemoteItemRepository`(+`FeedCache` 파일 캐시).
- 이 Mac의 Android 에뮬레이터는 VM이 멈추는 문제가 있어 육안 검수는 실기기로 한다.

## 아키텍처

상태관리 패키지 없이 **`AppDeps`(InheritedWidget)** 하나로 의존성을 내려보낸다 (`lib/app_deps.dart`). 새 의존성이 필요하면 Riverpod/Bloc을 도입하지 말고 AppDeps에 추가한다.

- `lib/theme/` — `tokens.dart`(디자인 토큰) + `app_theme.dart`. Claude Design 목업에서 옮긴 값: 글자 17~64sp, 버튼 64/72/88dp, 목록 행 82dp, 색 bg `#F4F4F2`·초록 `#0B5C41`·잉크 `#17191A`. 폰트 Pretendard.
- `lib/widgets/` — BigButton, BackBar, ScreenTitle, PersistentNotice, ItemCard, InfoRow, SurfaceCard, ListRow/InkChip, RegionName. 새 UI는 우선 이 위젯들을 재사용.
- `lib/data/` — `ItemRepository` 인터페이스 + Mock/Remote 구현, `FeedCache`, `RegionRepository`, `SettingsStore`.
- `lib/screens/` — splash → location_intro → home → detail → call_confirm, settings, region_picker(시·도→시군구 2단계), howto.
- `lib/utils/` — `korean_date.dart`, `phone_call.dart`.
- `assets/mock/` — 목 JSON(김포 8건, 엣지케이스 포함). 목 JSON 스키마(schemaVersion 1) = P2 실데이터 계약.

## 핵심 원칙 (어르신 접근성)

이 앱의 최우선 가치는 **70대 사용자의 접근성**이다:
- 글자·버튼 크기는 반드시 `lib/theme/tokens.dart`의 토큰을 사용한다. 하드코딩 금지.
- 글자 크기 = OS 배율 × 앱 배율(1.0/1.4/2.0), 최종 1.0~2.0 클램프. 높이는 전부 dp 상수.
- 색 대비 ≥ 7:1 유지.
- 화면당 정보·선택지를 최소로. 새 화면·버튼 추가는 신중히.

## 테스트 규칙

- 위젯/화면 테스트는 `test/helpers.dart`의 `pumpApp` 사용(360×780 뷰, 가짜 전화 런처, `rootBundle.clear()` 준비).
- 시간 의존 코드는 `AppDeps.clock` 주입 사용(테스트는 2026-08-28 고정). `DateTime.now()` 직접 호출 금지.
- 동작 변경 시 관련 테스트를 먼저/함께 수정하고 `flutter test` 통과를 확인한 뒤 완료로 본다.

## 코드 스타일

- `flutter_lints` + 추가 룰: `prefer_const_constructors`, `prefer_final_locals`, `avoid_print`(로그는 `debugPrint`).
- 커밋 메시지: conventional commits + 마일스톤 스코프 (예: `feat(p2-m5): ...`, `docs:`, `chore:`).
- 사용자 노출 문구는 전부 한국어, 어르신이 이해하기 쉬운 말로 쓴다.

## Flutter 일반 규칙 (Do NOT)

- `build()` 안에서 네트워크 호출·파일 I/O·무거운 계산·`.listen()` 구독 금지. build는 순수하게.
- `await` 뒤에서 `BuildContext`를 쓸 때는 반드시 `context.mounted` 확인.
- null 단언 `!` 남용 금지 — `?`와 흐름 분석, Dart 3 패턴 매칭 사용.
- 긴/동적 목록은 `ListView.builder` 사용 (정적 소수 항목은 예외).
- `AnimationController`·`Timer`·구독은 반드시 `dispose()`에서 정리.
- `WillPopScope`(deprecated) 대신 `PopScope` 사용.
- 색·크기 하드코딩 금지 — `lib/theme/tokens.dart`와 `Theme.of(context)` 사용.
- 상태관리 패키지(Riverpod/Bloc/GetX 등) 도입 금지 — `AppDeps` 유지.

## 네트워크 동작 (P2 M5)

`GET {FEED_BASE_URL}jobs/{code}.json` + `If-None-Match` ETag. 200→파싱·캐시 저장, 304→캐시 사용. 실패(5xx/404/8초 타임아웃/소켓 오류) 시 캐시 있으면 `fromCache=true`로 반환, 없으면 `FeedException`. 홈 배너: `fromCache`→"새 정보를 못 받았어요", `generatedAt` 48시간 초과→"정보가 오래됐어요".
