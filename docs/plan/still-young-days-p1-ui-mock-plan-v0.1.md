# 오늘도청춘 (Still Young Days) — Phase 1 개발 계획서: 목 데이터로 화면 전체 세우기 (v0.1)

작성일: 2026-08-28 | 버전: v0.1 | 베이스 커밋: (신규 저장소 — 아직 커밋 없음)

**한 줄 요약:** 기획서의 와이어프레임 7종을 **목 데이터(JSON asset)만으로** Flutter에서 전부 동작시켜, 데이터·GPS·푸시를 붙이기 전에 노안 대응 UI의 큰 틀을 에뮬레이터와 위젯 테스트로 확정한다. 네트워크·위치·알림 코드는 이 Phase에 **한 줄도 넣지 않는다**.

관련 문서: [기획서 — 어르신 일자리 알림](../../ideas/senior-jobs-app-2026-08-28.md) · 다음 장: [Phase 2 데이터 파이프라인](still-young-days-p2-data-pipeline-plan-v0.1.md)

> **Phase 전체 구성** (4장)
> P1 목 데이터 UI 전체 (이 문서) → P2 데이터 파이프라인 + 실데이터 연결 → P3 GPS·설정·푸시·내부 테스트 배포 → P4 전국 복지관 행사 크롤링

## 목차

0. [레포 디렉터리 구조](#0-레포-디렉터리-구조)
1. [확정 결정 모음](#1-확정-결정-모음)
2. [아키텍처](#2-아키텍처)
3. [마일스톤 M0~M6](#3-마일스톤)
4. [의존성 그래프](#4-의존성-그래프--병렬화-지점)
5. [위험 요소](#5-위험-요소와-완화책)
6. [신규 파일 목록](#6-신규-파일-목록-전체)
7. [완료 체크리스트](#7-완료-체크리스트)
8. [오픈 이슈](#8-오픈-이슈)
9. [자체 점검](#9-자체-점검)

---

## 0. 레포 디렉터리 구조

앱 저장소 `still-young-days-app` (Phase 1 종료 시점 기준 전체 파일).

```
still-young-days-app/
├── pubspec.yaml
├── analysis_options.yaml
├── android/app/build.gradle.kts        # minSdk 24, targetSdk 35 (P3에서 확정)
├── assets/
│   └── mock/
│       ├── jobs_41570.json             # 김포시 목 일자리 8건 (공통 JSON 스키마)
│       ├── jobs_41570_empty.json       # 빈 상태 검증용 0건
│       └── regions.json                # 시/도 17 → 시군구 목록 (P1은 경기도만 실제, 나머지 3~4개씩 샘플)
├── docs/
│   └── wireframes/                     # Claude Design 결과물 PNG 7장 + 검수 결과
│       ├── 01-splash.png … 07-howto.png
│       └── CHECKLIST.md                # 기획서 검수 체크리스트 13항목 체크 결과
├── lib/
│   ├── main.dart                       # runApp + 텍스트 스케일 클램프 + 라우팅
│   ├── app.dart                        # MaterialApp, 테마 주입, 홈 = SplashScreen
│   ├── theme/
│   │   ├── tokens.dart                 # 글자 크기·버튼 높이·간격·색 상수 (기획서 정량 기준 그대로)
│   │   └── app_theme.dart              # ThemeData 조립 (대비 7:1 팔레트, 웨이트 400/500)
│   ├── models/
│   │   ├── region_item.dart            # type(job|event) 공통 항목 모델 — P4 대비
│   │   └── region.dart                 # 시도/시군구 모델
│   ├── data/
│   │   ├── item_repository.dart        # abstract: fetchItems(regionCode)
│   │   ├── mock_item_repository.dart   # assets/mock/*.json 읽기 (P2에서 Remote로 교체)
│   │   ├── region_repository.dart      # regions.json 읽기
│   │   └── settings_store.dart         # 지역·글자크기·알림 on/off (shared_preferences)
│   ├── widgets/
│   │   ├── big_button.dart             # 64dp/72dp 버튼, 라벨 필수
│   │   ├── back_bar.dart               # 상단 고정 "◀ 뒤로" + 제목
│   │   ├── item_card.dart              # 홈 카드 (직무명·장소·전화 버튼)
│   │   ├── info_row.dart               # 상세 라벨+값 행 (값 없으면 렌더 안 함)
│   │   └── persistent_notice.dart      # 자동으로 안 사라지는 안내 배너 (토스트 대체)
│   └── screens/
│       ├── splash_screen.dart          # 화면 1
│       ├── location_intro_screen.dart  # 화면 2 (P1은 버튼만 — 권한 요청 없음)
│       ├── home_screen.dart            # 화면 3 ★
│       ├── detail_screen.dart          # 화면 4
│       ├── settings_screen.dart        # 화면 5
│       ├── region_picker_screen.dart   # 화면 6
│       └── howto_screen.dart           # 화면 7
└── test/
    ├── theme/tokens_test.dart          # 상수 값이 기획서 기준과 같은지
    ├── widgets/big_button_test.dart    # 높이 ≥64/72, 라벨 없으면 assert
    ├── widgets/item_card_test.dart
    ├── data/mock_item_repository_test.dart
    ├── data/settings_store_test.dart
    ├── screens/home_screen_test.dart   # 이전/다음·카운터·빈 상태
    ├── screens/detail_screen_test.dart # 값 없는 행 미표시·전화 버튼 72dp
    ├── screens/region_picker_test.dart
    └── screens/text_scale_test.dart    # 200% 확대 시 오버플로 없음
```

---

## 1. 확정 결정 모음

| 항목 | 확정값 | 근거 |
|---|---|---|
| 앱 표시명 | **오늘도청춘** / 영문 **Still Young Days** | 사용자 답변 |
| Flutter 프로젝트명 | `still_young_days` | 표시명의 영문 스네이크 케이스 |
| Android 패키지명 | `dev.jinkonpark.stillyoungdays` 🔶 가정 | 사용자 미지정 — 오픈 이슈 #1 |
| 저장소 | 앱 `still-young-days-app` / 데이터 `still-young-days-data` (private) 2개로 분리 | 사용자 답변. 일일 데이터 커밋이 앱 히스토리에 섞이지 않도록 |
| Phase 순서 | P1 목 UI → P2 파이프라인+실데이터 → P3 GPS·푸시·배포 → P4 크롤링 | 사용자 답변 ("큰 프레임부터, 점점 상세") |
| 디자인 선행 | **Claude Design 와이어프레임 7종을 M0에서 먼저 확보**, 검수 체크리스트 13항목 통과 후 코딩 | 사용자 답변 · 기획서 첫 구현 단계 4번 |
| 검증 방법 | `flutter test` 위젯 테스트 + Android 에뮬레이터 수동 확인 | 사용자 답변 |
| Flutter / Dart | 3.47.2 / 3.13.2 | 기획서 §기술 접근 |
| 상태 관리 | 패키지 없음 — `FutureBuilder` + `setState` | 기획서 |
| 내비게이션 | `Navigator` 1.0 (`MaterialPageRoute`) 🔶 가정 | 화면 7개·딥링크 없음 → go_router 불필요. 오픈 이슈 #2 |
| 설정 저장 | `shared_preferences` (`flutter pub add`로 최신 안정 버전) 🔶 가정 | 기획서 의존성 목록엔 없지만 지역·글자크기·알림 3개 값만 저장하기에는 파일 I/O보다 간단하다. 오픈 이슈 #3 |
| 목 데이터 형식 | **P2 실데이터와 동일한 JSON 스키마**를 `assets/mock/`에 둔다 (§2) | 리포지토리만 갈아끼우면 P2로 넘어가도록 |
| 상세 화면 항목 | "받는 돈 / 일하는 때" 라벨 **삭제** → `description`(하는 일) 본문으로 통합 | 사용자 답변. Senuri 상세에 급여·근무시간 전용 필드가 없다 ([조사](#참고)) |
| 카드 넘기기 | `PageView` 스와이프 + "◀ 이전 / 다음 ▶" 64dp 버튼 병행, 카운터 "1 / 8" | 기획서 화면 3 |
| 글자 크기 3단계 | 보통 1.0 / 크게 1.3 / 아주 크게 1.6 배율, OS 배율과 곱한 뒤 `withClampedTextScaling(min 1.0, max 2.0)` 🔶 가정 | 배율 값은 기획서에 없음 — 오픈 이슈 #4 |
| 기본 팔레트 | 배경 `#FFFFFF`, 본문 `#1A1A1A`, 주 버튼 `#0B5394` 바탕 + 흰 글자 🔶 가정 | 계산상 7:1을 넘지만 **M1에서 대비 도구로 반드시 실측** — 오픈 이슈 #5 |
| 폰트 | 시스템 기본(Noto Sans KR) 웨이트 400/500만 | 기획서 금지 목록 |
| 목 지역 | 김포시 = 법정동코드 `41570` 하드코딩 | 기획서 첫 구현 단계 5번 "지역 하드코딩" |
| 전화 버튼(P1) | `url_launcher`로 `tel:` 실제 실행 (에뮬레이터 다이얼러 열림) | 목 단계에서도 핵심 전환 경로를 끝까지 확인하려고 |

---

## 2. 아키텍처

```
┌──────────────────────────────── Flutter (P1) ────────────────────────────────┐
│                                                                               │
│  assets/mock/jobs_41570.json ──▶ MockItemRepository ──▶ FutureBuilder ──▶ 화면 │
│  assets/mock/regions.json    ──▶ RegionRepository                             │
│  shared_preferences          ◀─▶ SettingsStore (지역코드·글자배율·알림on/off)  │
│                                                                               │
│  Splash ─▶ (첫 실행) LocationIntro ─▶ Home ◀─▶ Detail ─▶ tel:                  │
│                                       │                                       │
│                                       └─▶ Settings ─▶ RegionPicker / HowTo    │
└───────────────────────────────────────────────────────────────────────────────┘
```

**공통 JSON 스키마 (P1 목 = P2 실데이터 = P4 행사, 전 Phase 계약)**

```jsonc
{
  "schemaVersion": 1,
  "regionCode": "41570",            // 법정동 시군구 5자리
  "regionName": "김포시",
  "generatedAt": "2026-08-28T03:00:00Z",
  "items": [
    {
      "type": "job",                // "job" | "event"  ← P4 대비
      "id": "senuri:K123456",
      "title": "공원 환경정비",      // 홈 카드 1행. 줄바꿈 허용, 말줄임 금지
      "place": "김포시 사우동",      // 홈 카드 2행 (짧은 장소)
      "address": "경기도 김포시 사우동 123",
      "phone": "031-000-0000",      // null이면 전화 버튼 대신 "문의처 없음" 안내
      "org": "김포시니어클럽",
      "description": "…",           // 상세 "하는 일" 본문 (급여·시간 포함 자유 텍스트)
      "age": "60세 이상",           // null 허용
      "applyStart": "2026-08-25",   // 표시는 "8월 25일 (월)"
      "applyEnd": "2026-09-07",
      "source": "senuri",
      "sourceUrl": null             // P4 행사는 원문 링크 필수
    }
  ]
}
```

| 영역 | 선택 | 비고 |
|---|---|---|
| UI | Flutter 3.47.2, Material 3 | `useMaterial3: true`, 색은 tokens에서만 |
| 데이터 | asset JSON → Dart 모델 | `rootBundle.loadString` |
| 저장 | `shared_preferences` 🔶 | 키 3개: `regionCode`, `textScale`, `notifyOn` |
| 전화 | `url_launcher ^6.3.2` | `Uri(scheme:'tel', path:phone)`, `canLaunchUrl` 미사용 |
| 테스트 | `flutter_test` 위젯 테스트 | 노안 정량 기준을 테스트로 고정 |

---

## 3. 마일스톤

### M0 — 준비: 와이어프레임 확보 + 프로젝트 골격

#### 목표
검수 체크리스트를 통과한 와이어프레임 7장이 `docs/wireframes/`에 있고, `flutter create`로 만든 앱이 에뮬레이터에서 빈 화면으로 뜨며 `flutter test`가 통과한다.

#### 산출물
- `docs/wireframes/01-splash.png` ~ `07-howto.png` — 신설. Claude Design 결과
- `docs/wireframes/CHECKLIST.md` — 신설. 기획서 검수 13항목 × 7화면 체크표
- `pubspec.yaml` — 신설. 의존성·assets 등록
- `analysis_options.yaml` — 신설. `flutter_lints` + `prefer_const_constructors` 등
- `assets/mock/jobs_41570.json`, `jobs_41570_empty.json`, `regions.json` — 신설

#### 핵심 작업
1. Claude Design에 기획서 「와이어프레임 설계 프롬프트」의 **공통 제약 블록 + 화면별 프롬프트**를 그대로 입력해 7장 생성. 검수 체크리스트에서 ❌가 하나라도 있으면 그 화면만 재요청.
2. 프로젝트 생성:
   ```bash
   flutter create --org dev.jinkonpark --project-name still_young_days \
     --platforms android,ios still-young-days-app
   cd still-young-days-app
   flutter pub add url_launcher shared_preferences
   flutter pub add --dev flutter_lints
   ```
   `http`, `path_provider`, `geolocator`, `firebase_*`는 **P2·P3에서** 추가한다 — P1에 미리 넣어 두면 네트워크 코드를 쓰고 싶어진다.
3. `pubspec.yaml`에 `flutter: assets: [assets/mock/]` 등록.
4. 목 데이터 작성: `jobs_41570.json`에 8건. 의도적으로 포함할 케이스 — 긴 직무명(2줄 줄바꿈 확인용) 1건, `phone: null` 1건, `age: null` 1건, `description`에 급여·시간 문장이 섞인 것 2건.
5. `regions.json`: 경기도 31개 시군구는 실제 법정동코드로, 나머지 시/도는 3~4개씩 샘플. (P3에서 `sigungu.json`으로 교체)

#### 완료 기준
- `docs/wireframes/CHECKLIST.md`의 13항목 × 7화면 = 91칸이 전부 ✅
- `flutter run -d emulator` → 기본 카운터 앱 표시
- `flutter test` → 기본 `widget_test.dart` 통과
- `flutter analyze` → 이슈 0

#### 회귀 가드레일 — 깨지면 안 되는 것
- 없음 (신규 파일만)

---

### M1 — 디자인 토큰 + 공통 위젯 (노안 기준을 코드로 고정)

#### 목표
기획서 정량 기준(18~20sp, 64/72dp, 12~16dp, 7:1, 행간 1.5, 웨이트 400/500)이 `tokens.dart` 상수와 위젯 테스트로 고정되어, 이후 화면은 이 위젯만 조립하면 기준을 어길 수 없다.

#### 산출물
- `lib/theme/tokens.dart` — 신설
- `lib/theme/app_theme.dart` — 신설
- `lib/widgets/big_button.dart`, `back_bar.dart`, `persistent_notice.dart` — 신설
- `lib/main.dart`, `lib/app.dart` — 신설 (텍스트 스케일 클램프 포함)
- `test/theme/tokens_test.dart`, `test/widgets/big_button_test.dart` — 신설

#### 핵심 작업
1. 토큰 상수 — 기획서 표를 그대로 옮긴다:
   ```dart
   // lib/theme/tokens.dart
   abstract final class Tokens {
     static const double body = 20;        // sp — 18~20 중 상한 채택
     static const double title = 24;
     static const double caption = 16;
     static const double buttonMin = 64;   // dp
     static const double buttonCritical = 72;
     static const double gap = 16;         // 버튼 간 12~16 중 상한
     static const double lineHeight = 1.5;
     static const Color bg = Color(0xFFFFFFFF);
     static const Color fg = Color(0xFF1A1A1A);
     static const Color primary = Color(0xFF0B5394); // 🔶 M1에서 대비 실측
     static const Color onPrimary = Color(0xFFFFFFFF);
   }
   ```
2. `BigButton`: `label` 필수(아이콘 단독 금지 — `assert(label.isNotEmpty)`), `critical: true`면 72dp, 내부 `ConstrainedBox(minHeight:)`. **sp를 높이 계산에 쓰지 않는다** (Android 14 비선형 스케일 함정) — 높이는 dp 상수, 글자만 스케일.
3. `main.dart`에서 OS 배율 × 앱 배율을 곱한 뒤 클램프:
   ```dart
   builder: (context, child) => MediaQuery.withClampedTextScaling(
     minScaleFactor: 1.0, maxScaleFactor: 2.0, child: child!),
   ```
4. `PersistentNotice`: 닫기 버튼이 있는 배너. `SnackBar` 사용 금지는 lint로 막을 수 없으니 코드리뷰 항목으로 `CHECKLIST.md`에 적어 둔다.
5. 대비 실측: 에뮬레이터 스크린샷을 WebAIM Contrast Checker 같은 도구에 넣어 `primary`/`onPrimary`, `fg`/`bg`가 각각 **7:1 이상**인지 확인하고, 결과 수치를 `tokens.dart` 주석에 기록한다.

#### 완료 기준
- `test/widgets/big_button_test.dart`: 기본 높이 ≥ 64, `critical` 높이 ≥ 72, 텍스트 스케일 2.0에서도 라벨이 잘리지 않음(오버플로 예외 없음) — 3개 통과
- `test/theme/tokens_test.dart`: `body ≥ 18`, `buttonMin ≥ 64`, `lineHeight ≥ 1.5` 상수 검증 통과
- `tokens.dart` 주석에 실측 대비값 2개 기록 (둘 다 ≥ 7.0)

#### 회귀 가드레일 — 깨지면 안 되는 것
- M0의 `flutter analyze` 이슈 0 유지

---

### M2 — 모델 + 목 리포지토리 + 설정 저장

#### 목표
공통 JSON 스키마를 Dart 모델로 읽고, 지역·글자배율·알림 설정을 저장/복원할 수 있다. 화면 코드는 아직 없다.

#### 산출물
- `lib/models/region_item.dart`, `lib/models/region.dart` — 신설
- `lib/data/item_repository.dart`, `mock_item_repository.dart`, `region_repository.dart`, `settings_store.dart` — 신설
- `test/data/mock_item_repository_test.dart`, `test/data/settings_store_test.dart` — 신설

#### 핵심 작업
1. 모델은 `fromJson` 수동 작성 (코드 생성 패키지 없음). `type`은 enum `ItemType { job, event }`, 모르는 값은 `job`이 아니라 **예외** — 스키마 계약 위반을 조용히 넘기지 않는다.
2. 리포지토리 인터페이스 — P2에서 `RemoteItemRepository`로 갈아끼울 유일한 경계:
   ```dart
   abstract interface class ItemRepository {
     Future<RegionFeed> fetchItems(String regionCode);
   }
   ```
   `MockItemRepository`는 `assets/mock/jobs_$regionCode.json`을 읽고, 파일이 없으면 `jobs_41570_empty.json`을 돌려준다(빈 상태 확인용).
3. 날짜 포맷 헬퍼: `"2026-08-30"` → `"8월 30일 (토)"`. `intl` 없이 요일 배열로 직접 만든다.
4. `SettingsStore`: `regionCode`(기본 `"41570"`), `textScale`(기본 `1.0`), `notifyOn`(기본 `true`).

#### 완료 기준
- `mock_item_repository_test.dart`: 8건 로드, `phone == null` 1건 존재, 존재하지 않는 코드 → 0건 — 3개 통과
- `settings_store_test.dart`: 저장 후 재생성해도 값 유지 (`SharedPreferences.setMockInitialValues`) — 2개 통과
- 날짜 헬퍼 테스트: `2026-08-30 → "8월 30일 (토)"` 통과

#### 회귀 가드레일 — 깨지면 안 되는 것
- 없음 (신규 파일만)

---

### M3 — 스플래시 + 홈 카드 ★

#### 목표
앱을 열면 스플래시(1~2초, 데이터 로딩) → 홈에서 김포시 일자리 8건을 한 장씩 넘겨 볼 수 있다. 0건이면 빈 상태 화면이 뜬다.

#### 산출물
- `lib/screens/splash_screen.dart`, `home_screen.dart` — 신설
- `lib/widgets/item_card.dart` — 신설
- `test/widgets/item_card_test.dart`, `test/screens/home_screen_test.dart` — 신설

#### 핵심 작업
1. 스플래시: 앱 이름 "오늘도청춘" 제목 크기 이상 + "일자리를 불러오는 중입니다" + **굵은** 원형 인디케이터(`strokeWidth: 8`). `Future.wait([repo.fetchItems, Future.delayed(1s)])` 후 `pushReplacement`. 최소 1초는 보여 줘야 화면이 비어 보이지 않는다.
2. 홈: 상단 `현재 지역 이름` + `"${i+1} / $n"`; `PageView.builder` + 하단 `BigButton("◀ 이전")` / `BigButton("다음 ▶")`. 첫/마지막 카드에서는 버튼을 **비활성화하지 않고**, 눌러도 넘어가지 않으면서 배너로 "첫 번째예요"라고 알린다 — 비활성 회색은 저대비 금지에 걸린다.
3. `ItemCard`: `title`(body 이상, `maxLines: null`, `overflow: visible`), `place`, `BigButton("📞 전화하기")`. 카드 본체 탭 → 상세. `phone == null`이면 버튼 대신 "전화번호가 없어요 · 자세히 보기".
4. 빈 상태: "지금은 김포시에 모집 중인 일자리가 없어요" + `BigButton("다른 동네 보기")` → 지역 선택(M5).

#### 완료 기준
- `home_screen_test.dart`: "다음 ▶" 탭 → 카운터 `2 / 8`; 마지막에서 "다음" → 여전히 `8 / 8` + 안내 배너 표시; 0건 → 빈 상태 문구 표시 — 3개 통과
- `item_card_test.dart`: 긴 제목(40자)이 2줄로 렌더되고 `...` 없음; 전화 버튼 높이 ≥ 64 — 2개 통과
- 에뮬레이터: 스와이프·버튼 둘 다로 8장 왕복, 와이어프레임 03과 대조

#### 회귀 가드레일 — 깨지면 안 되는 것
- M1 `big_button_test.dart` 전부 통과 (카드가 BigButton을 커스텀하지 않았음을 보장)

---

### M4 — 상세 + 전화 걸기

#### 목표
카드를 누르면 상세가 뜨고, 하단 고정 72dp "📞 전화하기"를 누르면 다이얼러가 열린다.

#### 산출물
- `lib/screens/detail_screen.dart` — 신설
- `lib/widgets/info_row.dart` — 신설
- `test/screens/detail_screen_test.dart` — 신설

#### 핵심 작업
1. 레이아웃: `BackBar`(상단 고정) + `ListView`(제목 24sp, `InfoRow`들) + `bottomNavigationBar`에 `BigButton(critical: true)` — 스크롤해도 항상 보임.
2. 표시 항목 순서: **하는 일**(`description`) · **장소**(`address`) · **모집 나이**(`age`) · **신청 기간**(`applyStart`~`applyEnd` 요일 병기) · **기관**(`org`). "받는 돈 / 일하는 때" 없음(확정 결정).
3. `InfoRow`는 값이 `null`이거나 빈 문자열이면 **위젯 자체를 반환하지 않는다** (`SizedBox.shrink`도 간격이 남으니 상위에서 걸러낸다).
4. 전화:
   ```dart
   final uri = Uri(scheme: 'tel', path: phone);   // Uri.parse 금지 (하이픈·공백)
   await launchUrl(uri);                          // canLaunchUrl 미사용
   ```
   실패하면 `PersistentNotice("전화를 걸 수 없어요. 번호: $phone")` — 번호를 그대로 보여 줘서 어르신이 직접 걸 수 있게 한다.
5. 전화 버튼 탭을 `debugPrint('metric:call_tap')`으로 남긴다 — P3에서 실제 계측 코드로 바꿀 자리.

#### 완료 기준
- `detail_screen_test.dart`: `age == null` 항목에서 "모집 나이" 라벨이 트리에 없음; 전화 버튼 높이 ≥ 72; 스크롤한 뒤에도 전화 버튼이 화면에 남아 있음 — 3개 통과
- 에뮬레이터: 전화 버튼을 누르면 Android 다이얼러가 `031-000-0000`이 채워진 채로 열림

#### 회귀 가드레일 — 깨지면 안 되는 것
- M3 `home_screen_test.dart` 통과 (홈→상세 push가 홈 상태를 깨뜨리지 않음: 뒤로 가면 같은 카드 번호)

---

### M5 — 설정 + 지역 선택 + 글자 크기

#### 목표
설정 4항목이 동작하고, 지역을 바꾸면 홈이 그 지역 목 데이터(또는 빈 상태)로 갱신되며, 글자 크기 변경이 즉시 전 화면에 반영된다.

#### 산출물
- `lib/screens/settings_screen.dart`, `region_picker_screen.dart` — 신설
- `lib/app.dart` — 수정 (글자배율을 `MediaQuery`에 주입)
- `test/screens/region_picker_test.dart`, `test/screens/text_scale_test.dart` — 신설

#### 핵심 작업
1. 설정 행 4개(각 ≥64dp): 내 동네 바꾸기(현재값) · 글자 크기(보통/크게/아주 크게) · 알림 받기(스위치 + "켜짐/꺼짐" 글자) · 앱 사용법. 알림 스위치는 P1에서 값만 저장한다.
2. 글자 크기: `SettingsStore.textScale`을 `app.dart`의 `builder`에서 `MediaQuery(data: mq.copyWith(textScaler: mq.textScaler.scale(x)...))` 형태로 곱한다 — 합성은 `TextScaler.linear(os × app)`로 정확히 계산하고, 그 뒤에 `withClampedTextScaling`을 그대로 둔다.
3. 지역 선택 2단계: 시/도 17개를 `GridView`(2열, 각 ≥72dp)로, 그다음 시군구를 `ListView`로. **검색창 없음**. 상단 "내 위치로 다시 찾기" 버튼은 P1에서 `PersistentNotice("다음 단계에서 준비돼요")`만 띄운다.
4. 지역을 바꾸면 `Navigator.popUntil(home)` + 홈 `setState`로 다시 조회한다.

#### 완료 기준
- `region_picker_test.dart`: "경기도" → "김포시" 선택 → `SettingsStore.regionCode == "41570"`; 시/도 버튼 높이 ≥ 72 — 2개 통과
- `text_scale_test.dart`: 앱 배율 1.6 × OS 배율 1.3 → 클램프로 2.0; 홈·상세 렌더에 `RenderFlex overflowed` 예외 없음 — 2개 통과
- 에뮬레이터: 지역을 "수원시"(목 데이터 없음)로 바꾸면 홈이 빈 상태로 바뀜

#### 회귀 가드레일 — 깨지면 안 되는 것
- M3·M4 테스트 전부 통과 (배율 주입이 기존 화면 레이아웃을 깨지 않음)

---

### M6 — 앱 사용법 + 위치 안내(껍데기) + 전체 플로우 검수

#### 목표
7개 화면이 모두 연결되어 기획서 「핵심 사용자 플로우」①~④를 목 데이터로 완주하고, 검수 체크리스트를 **구현물 기준**으로 다시 통과한다.

#### 산출물
- `lib/screens/howto_screen.dart`, `location_intro_screen.dart` — 신설
- `docs/wireframes/CHECKLIST.md` — 수정 (와이어프레임 열 옆에 "구현" 열 추가)

#### 핵심 작업
1. 앱 사용법: ①②③ 큰 번호 + 한 문장 + `docs/wireframes` 축소 이미지(asset 등록) + "알겠어요" 버튼.
2. 위치 안내: "어느 동네에 사시나요?" + "내 위치로 찾기"(P1: 안내 배너를 띄운 뒤 김포시로 진행) / "직접 고를게요"(→ 지역 선택). 첫 실행 여부는 `SettingsStore`에 `onboarded` 키를 추가해 판단한다.
3. 에뮬레이터 접근성 검수: 설정에서 글꼴 크기와 표시 크기를 최대로 올린 상태로 7화면을 순회하고, TalkBack을 켜서 홈 카드·전화 버튼 라벨이 읽히는지 확인한다(`Semantics(label:)` 보강).
4. `CHECKLIST.md` 구현 열의 13항목 × 7화면을 다시 검수한다.

#### 완료 기준
- `flutter test` 전체 통과 (M1~M5 누적 ≥ 20 케이스)
- 에뮬레이터 스크린샷 7장을 `docs/wireframes/impl-*.png`로 저장, 와이어프레임과 나란히 비교
- `CHECKLIST.md` 구현 열 91칸 전부 ✅ — 특히 "탭만으로 모든 기능 도달", "글자 200%에서 레이아웃 안 깨짐"
- OS 글꼴 최대 + TalkBack에서 스플래시→홈→상세→전화 완주

#### 회귀 가드레일 — 깨지면 안 되는 것
- M1~M5 테스트 전부 통과
- `flutter analyze` 이슈 0

---

## 4. 의존성 그래프 · 병렬화 지점

```
M0 ─→ M1 ─→ M2 ─→ M3 ─→ M4 ─→ M6
              │            ↗
              └──→ M5 ────┘
```

- **M5(설정·지역)는 M3이 끝난 뒤 M4와 나란히 진행할 수 있다** — 둘 다 M2의 리포지토리·스토어에만 의존하고 서로의 파일을 건드리지 않는다.
- M0의 와이어프레임 작업과 `flutter create`는 서로 독립이라 같은 날 함께 진행한다.

---

## 5. 위험 요소와 완화책

| 위험 | 확률 | 영향 | 완화책 |
|---|---|---|---|
| 팔레트 `#0B5394`가 실측 대비 7:1에 못 미침 🔶 | 중 | M1 재작업 | M1에서 실측해 못 미치면 `#083F70`처럼 더 어둡게 — 토큰 한 곳만 바꾸면 된다 |
| `withClampedTextScaling`과 앱 자체 배율의 합성이 예상과 다르게 동작 | 중 | M5 글자 크기 기능 | `text_scale_test.dart`로 합성 결과를 수치로 고정한다. 그래도 안 되면 앱 배율을 `TextStyle.fontSize`에 직접 곱하는 방식으로 물러선다 |
| Claude Design 결과가 체크리스트를 계속 통과하지 못함 (특히 7:1·64dp) | 중 | M0 지연 | 공통 제약 블록은 절대 줄이지 말고 화면 단위로 다시 요청한다. 3회 실패하면 텍스트 설명만으로 M1을 시작하고 시안은 대조용으로만 쓴다 |
| 목 데이터 스키마가 P2 실데이터와 어긋남 | 저 | P2 M5 재작업 | **P2 파이프라인 출력 검증 테스트**가 §2 스키마를 그대로 참조하게 한다 (P2 계획서 M3) |
| `PageView` 스와이프를 어르신이 잘못 건드려 카드를 건너뜀 | 중 | 사용성 | 버튼이 항상 있어서 기능이 사라지지는 않는다. P3 어머님 테스트에서 스와이프 끄기 옵션을 검토한다 |

---

## 6. 신규 파일 목록 (전체)

```
pubspec.yaml · analysis_options.yaml
assets/mock/jobs_41570.json · jobs_41570_empty.json · regions.json
docs/wireframes/01-splash.png … 07-howto.png · CHECKLIST.md · impl-*.png
lib/main.dart · app.dart
lib/theme/tokens.dart · app_theme.dart
lib/models/region_item.dart · region.dart
lib/data/item_repository.dart · mock_item_repository.dart · region_repository.dart · settings_store.dart
lib/widgets/big_button.dart · back_bar.dart · item_card.dart · info_row.dart · persistent_notice.dart
lib/screens/splash_screen.dart · location_intro_screen.dart · home_screen.dart · detail_screen.dart
            settings_screen.dart · region_picker_screen.dart · howto_screen.dart
test/theme/tokens_test.dart
test/widgets/big_button_test.dart · item_card_test.dart
test/data/mock_item_repository_test.dart · settings_store_test.dart
test/screens/home_screen_test.dart · detail_screen_test.dart · region_picker_test.dart · text_scale_test.dart
```

---

## 7. 완료 체크리스트

(2026-08-28 갱신 — 앱 저장소 `~/myworkspace/still-young-days-app`, `flutter analyze` 0건, `flutter test` 38건 통과)

- [ ] M0: 와이어프레임 7장 체크리스트 91칸 ✅ (사용자가 Claude Design에서 제작 예정, `docs/wireframes/CHECKLIST.md` W열) / [x] `flutter create` 앱 골격·패키지명·minSdk 24
- [x] M1: 토큰·BigButton 테스트 통과 + 대비 실측 2건 ≥ 7:1 기록 (fg/bg 17.4:1, primary 7.8:1, `test/theme/tokens_test.dart`)
- [x] M2: 목 리포지토리·설정 저장·날짜 헬퍼 테스트 통과
- [x] M3: 홈 8장 왕복 + 빈 상태, 테스트 6개 통과
- [x] M4: 상세 + 다이얼러 호출(가짜 런처로 `tel:031-000-0001` 확인), 테스트 4개 통과
- [x] M5: 지역 변경·글자 크기 즉시 반영, 테스트 6개 통과
- [~] M6: 7화면 연결 + 플로우 테스트 3개 통과 / 구현 검수 91칸 I열 ✅ / TalkBack 완주는 **미완(실기기 필요)**
- [~] 전체: `flutter test` 전체 통과 ✅ / 에뮬레이터 완주 **미완** — 이 호스트의 Android 에뮬레이터가 앱 종류와 무관하게 멈춰 생략(README 참고). 실기기에서 확인 필요.

---

## 8. 오픈 이슈

| # | 태그 | 내용 | 채택한 기본값 | 다르게 정해지면 | 언제까지 |
|---|---|---|---|---|---|
| 1 | 🔶 가정 | Android 패키지명 | `dev.jinkonpark.stillyoungdays` | `flutter create --org` 인자만 바뀐다. **출시 뒤에는 못 바꾸므로** P3 M5 전에 확정한다 | M0 전 |
| 2 | 🔶 가정 | 내비게이션 방식 | `Navigator` 1.0 | 푸시 알림 딥링크(P3)로 특정 카드를 바로 열어야 하면 go_router를 검토한다 | P3 M4 전 |
| 3 | 🔶 가정 | 설정 저장 방식 | `shared_preferences` 추가 | 기획서 의존성 목록을 엄격히 지키려면 `path_provider` + JSON 파일로 바꾼다 (M2만 영향) | M2 전 |
| 4 | 🔶 가정 | 글자 크기 3단계 배율 | 1.0 / 1.3 / 1.6 | 어머님 테스트(P3 M5)에서 조정한다 — 토큰 한 곳만 고치면 된다 | P3 M5 |
| 5 | 🔶 가정 | 기본 팔레트 색상 | `#1A1A1A`/`#FFFFFF`, `#0B5394`/`#FFFFFF` | M1 실측에서 기준에 못 미치면 색만 바꾼다 | M1 |
| 6 | 🔶 가정 | 목 데이터 8건이 실데이터 분포를 대표한다 | 긴 제목·null 전화·null 나이 포함 | P2에서 실데이터를 확인한 뒤 케이스를 보강한다 | P2 M1 후 |

---

## 9. 자체 점검

- **가장 불확실한 마일스톤**: **M5** — OS 배율 × 앱 배율 × 클램프의 합성이 Flutter 3.47의 `TextScaler` API에서 어떻게 동작하는지 문서만으로 확신할 수 없다. 테스트를 먼저 쓰고 구현한다.
- **틀리면 계획이 무너지는 가정**: ① 🔶#5 팔레트 — 틀려도 토큰 한 곳만 고치면 되니 파급이 작다. ② 🔶#6 목 스키마가 실데이터를 대표한다 — 틀리면 P2 M5에서 모델을 손봐야 하므로, **P2 M1(실측)을 P1 M3보다 하루 앞당겨 함께 진행**하기를 권한다(P2 계획서 §4 참조).
- **지금 당장 뗄 첫걸음**: Claude Design을 열고 기획서의 공통 제약 블록과 화면 3(홈) 프롬프트를 붙여 넣는다 — 가장 어려운 화면부터.

## 참고

- Senuri 상세 응답 필드 조사(2026-08-28): 급여·근무시간 전용 필드 없음, `detCnts` 자유 텍스트에 포함. 출처: [data.go.kr 15015153](https://www.data.go.kr/data/15015153/openapi.do), [Sonw00/eldery_employment_chatbot](https://github.com/Sonw00/eldery_employment_chatbot/blob/main/go-main/site/app/views.py), [Chinchillas-kernel/chinchilla](https://github.com/Chinchillas-kernel/chinchilla/blob/main/chinchilla-python-rag/python_service/agent/tools/work_data.py)
