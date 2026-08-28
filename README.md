# 오늘도청춘 (Still Young Days) — P1 UI 목 데이터 앱

70대 어르신용 동네 일자리 앱. P1은 **목 JSON만으로 7화면을 완성**하는 단계다 (네트워크·GPS·푸시 없음).
기획: `~/myworkspace/still-young/docs/plan/still-young-days-p1-ui-mock-plan-v0.1.md`

## 실행
```bash
export PATH="$HOME/development/flutter/bin:$PATH"   # Flutter 3.47.2 (~/.zshrc에도 추가됨)
flutter pub get
flutter analyze
flutter test                       # 38건
flutter run -d <device>            # 또는 flutter build apk --debug
```
Android 패키지: `dev.jinkonpark.stillyoungdays`, minSdk 24.

## 구조
- `lib/theme/` 토큰(글자 20/24/16sp, 버튼 64/72dp, 간격 16, 대비 ≥7:1)·테마
- `lib/widgets/` BigButton, BackBar, PersistentNotice, ItemCard, InfoRow, RegionName
- `lib/data/` `ItemRepository` 인터페이스 + `MockItemRepository`(assets/mock) · `RegionRepository` · `SettingsStore`
- `lib/screens/` splash, location_intro, home, detail, settings(+text size), region_picker, howto
- `assets/mock/jobs_41570.json` 김포 8건(전화 없음 1, 나이 없음 1, 긴 제목 1), `jobs_41570_empty.json`, `regions.json`
- `test/` 토큰·위젯·데이터·화면·플로우 테스트. `test/helpers.dart`의 `pumpApp`이 360×780 뷰, 가짜 전화 런처, `rootBundle.clear()`를 준비한다.

P1 목 JSON 스키마(schemaVersion 1)는 P2 실데이터 계약과 동일하다. P2에서는 `MockItemRepository`만 교체한다.

## 가정·메모
- `regions.json`: 시/도 16개(전남·광주 통합 반영, 코드 `12xxx`는 가정값). 경기도 31개 시군구는 실제 법정동 코드, 나머지 시/도는 2~4개 샘플만.
- 글자 크기 = OS 배율 × 앱 배율(1.0/1.3/1.6), 최종 1.0~2.0 클램프. 높이는 전부 dp 상수.
- 전화: `tel:` `launchUrl`. 실패 시 번호를 안내 배너에 표시. `debugPrint('metric:call_tap')`이 P3 지표 자리.
- 사용법 화면은 와이어프레임 썸네일 대신 인라인 도식 위젯을 쓴다.
- 날짜 헬퍼 예시: 2026-08-30은 **일요일**이다(계획서의 "(토)" 예시는 오기).
- 에뮬레이터: 이 Mac에서 Android 에뮬레이터(API 29/34, arm64)가 어떤 앱을 띄워도 VM이 멈춰 육안 검수를 하지 못했다. 실기기 또는 다른 호스트에서 `flutter run`으로 확인 필요.
