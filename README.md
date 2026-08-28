# 오늘도청춘 (Still Young Days) — 앱

70대 어르신용 동네 일자리 앱. P1(목 JSON 7화면) 완료, P2(실데이터 연결) 진행 중.
기획: `docs/plan/` (`*p1-ui-mock*`, `*p2-data-pipeline*`), 아이디어: `ideas/`
데이터 파이프라인: `~/myworkspace/still-young-days-data`

## 실행
```bash
export PATH="$HOME/development/flutter/bin:$PATH"   # Flutter 3.47.2 (~/.zshrc에도 추가됨)
flutter pub get
flutter analyze
flutter test                       # 53건
flutter run -d <device>            # 목 데이터로 실행 (기본)
flutter run -d <device> --dart-define=FEED_BASE_URL=https://<host>/data/   # 실데이터
```
`FEED_BASE_URL`이 비어 있으면 `MockItemRepository`, 있으면 `RemoteItemRepository`(+파일 캐시)를 쓴다.
`FEED_READ_TOKEN`은 private raw URL을 쓸 때만 필요하다(P2 오픈 이슈 #2 — public Pages 배포를 권장).
Android 패키지: `dev.jinkonpark.stillyoungdays`, minSdk 24.

## 구조
- `lib/theme/` 토큰(글자 20/24/16sp, 버튼 64/72dp, 간격 16, 대비 ≥7:1)·테마
- `lib/widgets/` BigButton, BackBar, PersistentNotice, ItemCard, InfoRow, RegionName
- `lib/data/` `ItemRepository` 인터페이스 + `MockItemRepository`(assets/mock) · `RemoteItemRepository`(http, ETag) · `FeedCache`(문서 폴더 파일 캐시) · `RegionRepository` · `SettingsStore`
- `lib/screens/` splash, location_intro, home, detail, settings(+text size), region_picker, howto
- `assets/mock/jobs_41570.json` 김포 8건(전화 없음 1, 나이 없음 1, 긴 제목 1), `jobs_41570_empty.json`, `regions.json`
- `test/` 토큰·위젯·데이터·화면·플로우 테스트. `test/helpers.dart`의 `pumpApp`이 360×780 뷰, 가짜 전화 런처, `rootBundle.clear()`를 준비한다.

P1 목 JSON 스키마(schemaVersion 1)는 P2 실데이터 계약과 동일하다.

## 네트워크 동작 (P2 M5)
- `GET {FEED_BASE_URL}jobs/{code}.json`, `If-None-Match` ETag. 200→파싱·캐시 저장, 304→캐시.
- 실패(5xx/404/타임아웃 8초/소켓 오류)→캐시가 있으면 캐시를 `fromCache=true`로 반환, 없으면 `FeedException`.
- 스플래시: 예외면 "불러오지 못했어요 + 다시 시도" 버튼. 홈: `fromCache`면 "새 정보를 못 받았어요", `generatedAt`이 48시간을 넘으면 "정보가 오래됐어요" 배너.
- 시간은 `AppDeps.clock`으로 주입한다(테스트는 2026-08-28 고정).

## 가정·메모
- `regions.json`: 시/도 16개(전남·광주 통합 반영, 코드 `12xxx`는 가정값). 경기도 31개 시군구는 실제 법정동 코드, 나머지 시/도는 2~4개 샘플만.
- 글자 크기 = OS 배율 × 앱 배율(1.0/1.3/1.6), 최종 1.0~2.0 클램프. 높이는 전부 dp 상수.
- 전화: `tel:` `launchUrl`. 실패 시 번호를 안내 배너에 표시. `debugPrint('metric:call_tap')`이 P3 지표 자리.
- 사용법 화면은 와이어프레임 썸네일 대신 인라인 도식 위젯을 쓴다.
- 날짜 헬퍼 예시: 2026-08-30은 **일요일**이다(계획서의 "(토)" 예시는 오기).
- 에뮬레이터: 이 Mac에서 Android 에뮬레이터(API 29/34, arm64)가 어떤 앱을 띄워도 VM이 멈춰 육안 검수를 하지 못했다. 실기기 또는 다른 호스트에서 `flutter run`으로 확인 필요.
