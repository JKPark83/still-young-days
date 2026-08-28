# 오늘도청춘 (Still Young Days) — Phase 3 개발 계획서: GPS 지역 판정 · 주 1회 푸시 · 내부 테스트 배포 (v0.1)

작성일: 2026-08-28 | 버전: v0.1 | 베이스 커밋: (신규 저장소 — 아직 커밋 없음)

**한 줄 요약:** 김포시 하드코딩을 걷어내고 **오프라인 폴리곤으로 GPS→시군구**를 판정하며, 파이프라인에서 **매주 월요일 FCM 토픽 푸시**를 보내고, **Play 내부 테스트 트랙**으로 어머님 폰에 설치해 1단계 MVP를 완성한다. 이 Phase가 끝나면 기획서 1단계 「포함」 7항목이 전부 동작한다.

관련 문서: [기획서](../../ideas/senior-jobs-app-2026-08-28.md) · 이전 장: [P2 데이터 파이프라인](still-young-days-p2-data-pipeline-plan-v0.1.md) · 다음 장: [P4 복지관 행사 크롤링](still-young-days-p4-welfare-events-plan-v0.1.md)

## 목차

0. [레포 디렉터리 구조](#0-레포-디렉터리-구조) · 1. [확정 결정](#1-확정-결정-모음) · 2. [아키텍처](#2-아키텍처) · 3. [마일스톤](#3-마일스톤) · 4. [의존성](#4-의존성-그래프--병렬화-지점) · 5. [위험](#5-위험-요소와-완화책) · 6. [신규 파일](#6-신규-파일-목록-전체) · 7. [체크리스트](#7-완료-체크리스트) · 8. [오픈 이슈](#8-오픈-이슈) · 9. [자체 점검](#9-자체-점검)

---

## 0. 레포 디렉터리 구조

P1·P2 트리에 새로 더해지는 파일만 적었다.

```
still-young-days-data/
├── pyproject.toml                       # 수정: shapely, pyproj, google-auth 추가
├── geo/
│   ├── build_sgg_geojson.py             # admdongkor 읍면동 GeoJSON → sgg 기준 dissolve + 단순화 + bbox
│   └── neighbors.py                     # 시군구 인접 테이블 생성 (폴리곤 touches)
├── tables/
│   ├── sgg_boundaries.geojson           # 출력: 시군구 ~250 폴리곤, EPSG:4326, 단순화. 앱 asset으로 복사
│   └── neighbors.json                   # {"41570": ["41570 인접 코드…"]}
├── pipeline/
│   ├── notify.py                        # FCM HTTP v1: 시군구 토픽별 "이번 주 새 일자리 N개"
│   └── weekly_diff.py                   # 지난 월요일 index 대비 신규 id 수 산출
├── .github/workflows/notify.yml         # 매주 월 09:00 KST
└── tests/test_geo.py · test_weekly_diff.py

still-young-days-app/
├── android/app/build.gradle.kts         # 수정: minSdk 24, targetSdk 35, google-services 플러그인
├── android/app/google-services.json     # Firebase (gitignore, CI secret)
├── android/app/src/main/AndroidManifest.xml  # ACCESS_COARSE_LOCATION, POST_NOTIFICATIONS
├── assets/geo/sgg_boundaries.geojson    # 신설 (data 레포 산출물 복사)
├── assets/geo/neighbors.json
├── assets/regions.json                  # 교체: P2 sigungu.json에서 생성한 시도→시군구 전체 목록
├── lib/location/
│   ├── region_locator.dart              # GPS 좌표 → 시군구 코드 (bbox 프리필터 + turf PIP)
│   └── location_service.dart            # geolocator 권한·현재 위치 (COARSE)
├── lib/push/push_service.dart           # FCM 초기화·토픽 구독·알림 탭 라우팅
├── lib/metrics/metrics.dart             # 전화 탭 등 로컬 카운트 (P3는 로컬 저장만)
├── lib/screens/location_intro_screen.dart   # 수정: 실제 권한 요청
├── lib/screens/region_picker_screen.dart    # 수정: 실제 목록 + "내 위치로 다시 찾기"
├── lib/screens/settings_screen.dart         # 수정: 알림 스위치 → 토픽 구독/해제
└── test/location/region_locator_test.dart · test/push/push_service_test.dart
```

---

## 1. 확정 결정 모음

| 항목 | 확정값 | 근거 |
|---|---|---|
| 경계 데이터 원본 | `vuski/admdongkor` `ver20260701/HangJeongDong_ver20260701.geojson` (33MB, EPSG:4326) | 조사: 시군구 GeoJSON 없음, 읍면동만. 2026-07-01 통합특별시 반영 완료 |
| 시군구 폴리곤 생성 | 빌드 타임에 `sgg` 속성으로 dissolve → 단순화 → `assets/geo/sgg_boundaries.geojson` | 조사에서 권장한 구조. 33MB를 그대로 앱에 넣을 수는 없다 |
| 속성 필드명 | GeoJSON은 **`sgg`**(5자리)·`sggnm`·`sido`·`sidonm` — `sggcd`는 parquet 쪽 이름 | 조사 실측. 기획서 표기 `sggcd`는 정정 |
| 단순화 허용 오차 | `shapely.simplify(0.0005)` (≈50m), 목표 파일 ≤ 3MB 🔶 가정 | 시군구 판정에 50m 오차는 무시 가능. 오픈 이슈 #1 |
| 라이선스 표기 | 설정 → 앱 사용법 하단에 "행정경계: 통계청 SGIS(공공누리 1유형) 가공 vuski/admdongkor, CC BY 4.0" | 조사: 데이터 CC BY 4.0, 출처표시 필수 |
| PIP 패키지 | **`turf` 0.0.12 고정** (`turf: 0.0.12`, 캐럿 없이) | 조사: MultiPolygon과 구멍까지 지원하면서 관리가 이어지는 유일한 패키지. 0.0.x라 버전을 고정한다 |
| 후보 축소 | 폴리곤별 bbox를 빌드 타임에 계산해 GeoJSON `bbox`에 기록 → 앱에서 bbox 안에 든 후보만 PIP | 조사: turf의 bbox 조기 탈락은 `bbox`가 채워져 있을 때만 동작. rbush는 250개짜리엔 과하다 |
| 위치 정확도 | `LocationAccuracy.low` (COARSE) + 타임아웃 8초 | 기획서 |
| 권한 거부 시 | 지역 선택 화면으로 보내고 앱 기능은 100% 그대로 | 기획서 가드레일 "거부율 30% 미만, 거부해도 동작" |
| 인접 지역 | `neighbors.json` — P3에선 **빈 화면의 "옆 동네(○○시) 보기" 버튼**에만 쓴다 | 기획서 "경계 거주자 대응" 최소 구현 |
| 푸시 | FCM HTTP v1 + 서비스 계정 OAuth2, 토픽 `region_{code}` | 기획서 함정 (레거시 404) |
| 푸시 시각·문구 | 매주 **월 09:00 KST**, "이번 주 김포시 새 일자리 3개" (0개면 발송 안 함) | 기획서 플로우 ⑤ |
| 페이로드 | `notification` + `data:{regionCode}` — OS가 표시, 탭하면 홈 | 기획서 (`flutter_local_notifications` 불필요) |
| targetSdk / minSdk | 35 / 24 | 기획서 (33+ 필수, url_launcher minSdk 24) |
| 알림 권한 | Android 13+ `POST_NOTIFICATIONS` 런타임 요청 — 설정에서 "알림 받기"를 켤 때만 | 첫 실행부터 권한 팝업이 연달아 두 번 뜨면 어르신에게 부담이다 |
| 계측 | 전화 탭·앱 실행·푸시 탭을 **로컬 카운트**(shared_preferences)로만 센다. 원격 분석 없음 🔶 가정 | 개인 사이드프로젝트라 서버가 없다. 어머님 폰에서 직접 읽는다 — 오픈 이슈 #2 |
| 배포 | Play Console 내부 테스트 트랙, 테스터 = 가족 이메일 | 기획서 |
| 서명 | Play App Signing + 업로드 키 로컬 보관 | 표준 |

---

## 2. 아키텍처

```
 [빌드 타임, data 레포]                         [앱 런타임]
 admdongkor 읍면동 GeoJSON (33MB)               geolocator(COARSE) ─▶ (lat,lng)
   └ build_sgg_geojson.py                                │
       dissolve by sgg → simplify → bbox              RegionLocator
       └ sgg_boundaries.geojson (≤3MB) ──copy──▶ assets/geo ─┤ bbox 후보 → turf PIP
                                                          ▼
                                                  regionCode ─▶ SettingsStore ─▶ RemoteItemRepository(P2)
                                                          │
                                                          └▶ FCM subscribeToTopic("region_41570")

 [매주 월 09:00 KST, Actions notify.yml]
 weekly_diff.py: index(오늘) − index(지난주) → 시군구별 신규 수
   └ notify.py: google-auth 서비스계정 → FCM v1 /messages:send  topic=region_{code}
```

| 영역 | 선택 | 비고 |
|---|---|---|
| 경계 가공 | Python `shapely`, `pyproj` 불필요(이미 4326) | dissolve = `unary_union` |
| PIP | `turf` 0.0.12 `booleanPointInPolygon` | bbox 프리필터 후 호출 |
| 위치 | `geolocator ^14.0.3` | `LocationAccuracy.low` |
| 푸시 | `firebase_core ^4.14.0`, `firebase_messaging ^16.6.0` | HTTP v1 |
| 서버측 인증 | `google-auth` (Python) | 서비스 계정 JSON은 Actions secret |
| 배포 | `flutter build appbundle --release` | Play App Signing |

---

## 3. 마일스톤

### M0 — 준비: 의존성 · Firebase · Play 계정 · 경계 원본

#### 목표
앱이 Firebase에 연결된 채로 빌드되고, geolocator가 에뮬레이터의 가짜 위치를 읽으며, Play Console 계정 검증이 진행 중인 상태.

#### 산출물
- `pubspec.yaml` — 수정 (`geolocator`, `firebase_core`, `firebase_messaging`, `turf: 0.0.12`)
- `android/app/build.gradle.kts`, `AndroidManifest.xml` — 수정
- `android/app/google-services.json` — 신설 (gitignore)
- data 레포 `pyproject.toml` — 수정 (`shapely`, `google-auth`)
- Play Console 개발자 계정 ($25) — 신청

#### 핵심 작업
1. `flutter pub add geolocator firebase_core firebase_messaging` + `pubspec.yaml`에 `turf: 0.0.12` 직접 기입.
2. Firebase 프로젝트 생성 → Android 앱 등록(패키지명 = P1 오픈 이슈 #1 **여기서 최종 확정**) → `flutterfire configure`.
3. Manifest: `ACCESS_COARSE_LOCATION`, `POST_NOTIFICATIONS`. `ACCESS_FINE_LOCATION`은 **넣지 않는다**.
4. **Play Console 계정 검증은 M0 첫날 신청한다** — 걸리는 기간이 🔵(기획서)인 데다 여기서 가장 오래 기다린다.
5. admdongkor GeoJSON은 data 레포 `geo/raw/`에 내려받되 33MB라 **커밋하지 않고**, 빌드 스크립트가 URL에서 직접 받게 한다.

#### 완료 기준
- `flutter run` 시 로그에 Firebase 초기화 성공 + FCM 토큰 출력
- 에뮬레이터 Extended Controls로 위치를 김포(37.615, 126.716)로 설정 → `Geolocator.getCurrentPosition` 좌표 로그
- Play Console 검증 신청 완료 스크린샷

#### 회귀 가드레일 — 깨지면 안 되는 것
- P1·P2 `flutter test` 전부 통과 (의존성을 더해도 기존 테스트가 깨지지 않는다)

---

### M1 — 시군구 폴리곤 빌드 (data 레포)

#### 목표
`tables/sgg_boundaries.geojson`(≤3MB, bbox 포함)과 `neighbors.json`이 생성되고, 김포·세종·서귀포·수원 영통구·전남광주 동구 좌표가 올바른 코드로 판정된다.

#### 산출물
- `geo/build_sgg_geojson.py`, `geo/neighbors.py` — 신설
- `tables/sgg_boundaries.geojson`, `tables/neighbors.json` — 신설
- `tests/test_geo.py` — 신설

#### 핵심 작업
1. dissolve:
   ```python
   feats = load_geojson(URL)["features"]
   by_sgg = defaultdict(list)
   for f in feats: by_sgg[f["properties"]["sgg"]].append(shape(f["geometry"]))
   out = []
   for sgg, geoms in by_sgg.items():
       g = unary_union(geoms).simplify(0.0005, preserve_topology=True)
       out.append({"type":"Feature","bbox":list(g.bounds),
                   "properties":{"sgg":sgg,"sggnm":..., "sidonm":...},
                   "geometry":mapping(g)})
   ```
2. 좌표를 소수점 5자리(≈1m)로 반올림 — 파일 크기가 절반으로 준다.
3. `sgg`와 P2 `sigungu.json` 코드를 **전수 대조**한다 — 한쪽에만 있는 코드를 목록으로 뽑고, 나오면 P2 오픈 이슈 #4로 `aliases.json`에 흡수한다. 일반구(수원 4구)가 GeoJSON에 들어 있는지도 확인 — 기획서에 "구 결합형 39개 존재"라고 했으니 `sgg`가 구 단위여야 한다.
4. `neighbors.py`: `g_a.touches(g_b) or g_a.distance(g_b) < 0.001` → 인접.
5. 회귀 테스트(Python, shapely `contains`):
   | 좌표 | 기대 |
   |---|---|
   | 김포시청 37.6153,126.7156 | `41570` |
   | 세종시청 36.4800,127.2890 | `36110` |
   | 서귀포시청 33.2541,126.5600 | `50130` |
   | 수원 영통구청 37.2596,127.0466 | `41117` |
   | 광주 동구청 35.1460,126.9232 | `12xxx` (M1에서 확정값 기입) |

#### 완료 기준
- `ls -la tables/sgg_boundaries.geojson` ≤ 3MB, 피처 수 = `sigungu.json` 항목 수(일반구 기준) ±0
- `pytest tests/test_geo.py` 5개 통과
- 코드 대조 스크립트 출력 "mismatch: 0"

#### 회귀 가드레일 — 깨지면 안 되는 것
- P2 `test_regions.py` 5개 통과 (`aliases.json`을 고쳐도 주소 판정이 깨지지 않는다)

---

### M2 — 앱 GPS 판정 + 권한 플로우

#### 목표
첫 실행 "내 위치로 찾기" → 권한 허용 → 1~2초 안에 "김포시"로 설정되고 홈이 뜬다. 거부·실패·해외 좌표는 모두 지역 선택 화면으로 넘어간다.

#### 산출물
- `assets/geo/sgg_boundaries.geojson`, `assets/geo/neighbors.json` — 신설 (복사)
- `lib/location/region_locator.dart`, `location_service.dart` — 신설
- `lib/screens/location_intro_screen.dart` — 수정
- `test/location/region_locator_test.dart` — 신설

#### 핵심 작업
1. `RegionLocator.load()`는 스플래시에서 **한 번만** 파싱하고(`compute()`로 isolate) 그대로 메모리에 들고 있는다.
2. 판정:
   ```dart
   String? locate(double lat, double lng) {
     final p = Position(lng, lat);                       // turf는 (x=lng, y=lat)
     for (final f in features.where((f) => f.bbox!.contains(lng, lat))) {
       if (booleanPointInPolygon(p, f)) return f.properties['sgg'];
     }
     return null;                                         // 해외·바다
   }
   ```
3. `LocationService.current()`: `checkPermission` → `denied`면 `requestPermission` → `deniedForever`면 `null`을 돌려준다(설정 앱으로 보내지 않는다 — 어르신에게는 무리다). `getCurrentPosition(desiredAccuracy: low, timeLimit: 8s)`.
4. 결과가 `null`이면 `RegionPicker`로 보내고, 아니면 `SettingsStore.regionCode`에 저장하고 `onboarded = true`로 바꾼다.
5. 지역 선택 화면의 "내 위치로 다시 찾기" 버튼을 실제로 연결한다.
6. 일자리가 없어 빈 화면일 때 `neighbors.json` 첫 항목으로 "옆 동네(○○시) 보기" 버튼을 띄운다.

#### 완료 기준
- `region_locator_test.dart`: M1 표의 5좌표 → 기대 코드; 도쿄(35.68,139.69) → `null`; 경계 좌표(김포·고양 사이)에서 예외 없음 — 7개 통과
- 에뮬레이터 가짜 위치 김포 → 홈 상단 "김포시"; 위치 서울 강남 → "강남구"
- 권한 거부 → 지역 선택 화면 → 직접 선택 → 홈 (앱이 죽거나 로딩이 멈추는 일 없음)
- 파싱 시간 로그 ≤ 1,000ms (중급 에뮬레이터 기준) 🔶 — 넘으면 오픈 이슈 #1대로 단순화를 더 세게 건다

#### 회귀 가드레일 — 깨지면 안 되는 것
- P1 `region_picker_test.dart`, P2 `remote_item_repository_test.dart` 통과

---

### M3 — 지역 목록 실데이터 + 설정 정리

#### 목표
지역 선택이 전국 시도 17개 × 시군구 전체(P2 `sigungu.json` 기준)로 동작하고, 일반구는 "수원시"로 접혀 보이며, 고르면 산하 구 코드로 저장된다.

#### 산출물
- `assets/regions.json` — 교체 (data 레포 `sigungu.json`에서 생성 스크립트로)
- `lib/screens/region_picker_screen.dart`, `lib/data/region_repository.dart` — 수정

#### 핵심 작업
1. `regions.json` 생성 규칙: `display`가 같은 항목(수원시 4구)은 **한 행**으로 묶고 `codes: ["41111",…]` 배열을 둔다. 고르면 첫 코드를 `regionCode`로 저장한다 — P2에서 모시 주소를 모든 구에 복제해 뒀으니 어느 구를 골라도 모시 전체 일자리가 보인다.
2. 시도 표시명은 어르신에게 익숙한 말로 쓴다. "전남광주통합특별시"는 그대로 두되 두 줄까지 허용한다(줄바꿈은 되고 말줄임은 안 된다).
3. 설정의 "내 동네 바꾸기" 현재값이 GPS로 정해진 값이면 옆에 "(내 위치)"를 같이 적는다.

#### 완료 기준
- `region_picker_test.dart` 갱신: "경기도" → 시군구 행 수 = 경기도 시군구(일반구를 접은 뒤) 수; "수원시" 선택 → `regionCode == "41111"` — 2개 통과
- 에뮬레이터: 17개 시도 그리드가 2열·각 칸 ≥72dp로, 스크롤 없이 또는 한 번만 스크롤해서 다 보인다

#### 회귀 가드레일 — 깨지면 안 되는 것
- P1 `text_scale_test.dart` (긴 시도명 2줄에서 오버플로 없음)

---

### M4 — 주 1회 푸시 (파이프라인 + 앱)

#### 목표
매주 월 09:00 KST에, 구독한 시군구에 새 일자리가 있으면 "이번 주 김포시 새 일자리 3개" 알림이 오고 탭하면 홈이 열린다. 설정에서 끄면 오지 않는다.

#### 산출물
- data 레포 `pipeline/weekly_diff.py`, `pipeline/notify.py`, `.github/workflows/notify.yml`, `tests/test_weekly_diff.py` — 신설
- data 레포 `data/index_history/{YYYY-MM-DD}.json` — 신설 (주간 diff용 스냅샷, collect.yml이 월요일에 저장)
- 앱 `lib/push/push_service.dart`, `test/push/push_service_test.dart` — 신설
- 앱 `lib/screens/settings_screen.dart`, `lib/main.dart` — 수정

#### 핵심 작업
1. `weekly_diff.py`: 이번 주 `index.json`의 지역별 id 집합에서 지난 월요일 스냅샷을 빼 `{code: newCount}`를 만든다. 0인 지역은 뺀다.
2. `notify.py`:
   ```python
   creds = service_account.Credentials.from_service_account_info(json.loads(SA_JSON),
             scopes=["https://www.googleapis.com/auth/firebase.messaging"])
   creds.refresh(Request())
   for code, n in diff.items():
       body = {"message": {"topic": f"region_{code}",
               "notification": {"title": "오늘도청춘", "body": f"이번 주 {name} 새 일자리 {n}개"},
               "data": {"regionCode": code}}}
       httpx.post(f"https://fcm.googleapis.com/v1/projects/{PID}/messages:send",
                  headers={"Authorization": f"Bearer {creds.token}"}, json=body)
   ```
   토픽이 250개면 호출도 250번 — v1 한도 안에 든다. 실패한 코드는 로그로 남긴다.
3. 앱: 지역이 정해지면 `subscribeToTopic('region_$code')`를 부르고, 지역을 바꾸면 이전 토픽을 해제한다. 설정에서 "알림 받기"를 켤 때 `POST_NOTIFICATIONS`를 요청하고 구독하며, 끄면 해제한다.
4. 알림을 탭하면(`onMessageOpenedApp`, `getInitialMessage`) 홈으로 보낸다. P1 오픈 이슈 #2(Navigator 1.0)는 홈만 열면 되니 **그대로 둔다**.
5. 알림 문구는 어르신 눈높이에 맞춘다. 숫자와 지역명만 쓰고 이모지는 넣지 않는다.

#### 완료 기준
- `test_weekly_diff.py`: 신규 3건 / 0건 / 지역이 새로 생긴 경우 — 3개 통과
- `notify.yml`을 `workflow_dispatch`로 실행 → 에뮬레이터(김포 구독)에 알림 도착 → 탭 → 홈
- 설정에서 알림을 끈 뒤 다시 발송하면 오지 않는다
- Firebase 콘솔에서 토픽 `region_41570` 구독 수 ≥ 1 확인

#### 회귀 가드레일 — 깨지면 안 되는 것
- P2 `collect.yml`이 여전히 매일 성공 (스냅샷 저장 단계를 더해도 수집이 깨지지 않는다)

---

### M5 — 계측 · 내부 테스트 배포 · 어머님 실사용 ★

#### 목표
어머님 폰에 Play 스토어로 앱이 설치되고, 2주 동안 전화 탭·앱 실행 횟수가 폰 안에 쌓이며, 옆에서 지켜본 기록이 남는다.

#### 산출물
- `lib/metrics/metrics.dart` — 신설 (로컬 카운트: `open_count`, `call_tap_count`, `push_open_count`, 마지막 시각)
- 설정 → 앱 사용법 하단 "사용 기록" 작은 행(자녀가 볼 용도) — `howto_screen.dart` 수정
- `android/` 서명 설정, `key.properties` (gitignore) — 신설
- 앱 레포 `docs/field-test/2026-09-XX-observation.md` — 신설 (관찰 기록)

#### 핵심 작업
1. P1 M4의 `debugPrint('metric:call_tap')` 자리를 `Metrics.inc('call_tap')`로 바꾼다.
2. `flutter build appbundle --release` → Play Console **내부 테스트 트랙**에 업로드 → 테스터 목록에 가족 이메일 추가 → 링크로 어머님 폰에 설치.
3. 첫 설정은 **자녀가 대신 해준다**(기획서 R1 완화책). 설치 → 위치 허용 → 홈 화면 첫 페이지에 아이콘 두기 → 사용법 화면을 같이 한 번 본다.
4. 관찰: 처음 쓰는 10분을 옆에서 **거들지 않고** 지켜본다. 기록할 것: 막힌 지점, 누른 것과 안 누른 것, 글자를 키워 달라고 하는지, 스와이프와 버튼 중 어느 쪽을 편해하는지.
5. 2주 뒤 설정 → 사용 기록에서 카운트를 읽어 기획서 보조 지표(월 4회 열람)와 견줘 본다.

#### 완료 기준
- Play Console 내부 테스트가 "사용 가능" 상태이고, 어머님 폰에 스토어를 거쳐 설치됨
- `docs/field-test/*.md`에 관찰 기록 1건 이상
- 2주 뒤 `open_count`, `call_tap_count`를 기록 → 기획서 R1 판정(열람이 0회면 플랜 B 검토 시작)

#### 회귀 가드레일 — 깨지면 안 되는 것
- release 빌드에서 `flutter test` 통과 + 스플래시부터 전화 걸기까지 끝까지 진행 (debug 전용 코드가 남아 있지 않다)

---

## 4. 의존성 그래프 · 병렬화 지점

```
M0 ─┬→ M1 ─→ M2 ─→ M3 ─→ M5
    │                 ↗
    └→ M4 ───────────┘
```

- **M4(푸시)는 M1~M3와 나란히 진행할 수 있다** — 토픽 이름에 지역 코드만 있으면 되고 GPS와는 상관없다.
- M1은 data 레포, M2·M3는 앱 레포라 혼자 해도 왔다 갔다 하는 부담이 적다.
- Play 계정 검증(M0)은 기다리는 시간이 길어 **M0 첫날**에 신청한다.

---

## 5. 위험 요소와 완화책

| 위험 | 확률 | 영향 | 완화책 |
|---|---|---|---|
| 단순화해도 GeoJSON > 3MB 또는 파싱 > 1초 🔶 | 중 | M1·M2 | 허용 오차를 0.001(≈100m)로 올린다. 그래도 크면 시도 17개 파일로 쪼개, GPS로 시도를 먼저 가린 뒤 해당 파일만 로드 |
| `turf` 0.0.12 API가 문서와 다름 | 중 | M2 | 버전을 고정하고 `region_locator_test` 7개로 동작을 확인한다. 안 되면 직접 짠 ray-casting 60줄로 대체(MultiPolygon 순회) |
| 법정동 시군구 코드 ≠ admdongkor `sgg` (P2 🔵#4) | 중 | M1 | M1 코드 대조 결과 "mismatch: 0"을 완료 기준으로 둔다 |
| 서비스 계정 JSON 유출 | 저 | 보안 | Actions secret에만 두고, 로컬 `.env`는 gitignore, 키 교체 절차는 README에 적는다 |
| Play 계정 검증 지연 (🔵 기획서) | 중 | M5 | M0 첫날에 신청한다. 늦어지면 **제한적 배포 계정(무료, 20대)**으로 대신한다(기획서 배포표) |
| 어머님 폰 Android 버전 < 7 (minSdk 24 미만) 🔵 | 저 | M5 전체 | **M0에서 확인한다** — 오픈 이슈 #3 |

---

## 6. 신규 파일 목록 (전체)

```
still-young-days-data/
  geo/build_sgg_geojson.py · neighbors.py
  tables/sgg_boundaries.geojson · neighbors.json
  pipeline/weekly_diff.py · notify.py(내용 채움)
  .github/workflows/notify.yml
  data/index_history/*.json
  tests/test_geo.py · test_weekly_diff.py
still-young-days-app/
  android/app/google-services.json(gitignore) · android/key.properties(gitignore)
  assets/geo/sgg_boundaries.geojson · neighbors.json
  lib/location/region_locator.dart · location_service.dart
  lib/push/push_service.dart
  lib/metrics/metrics.dart
  test/location/region_locator_test.dart · test/push/push_service_test.dart
  docs/field-test/2026-09-XX-observation.md
```

---

## 7. 완료 체크리스트

- [ ] M0: Firebase 초기화 로그 + 에뮬레이터 좌표 읽기 + Play 검증 신청
- [ ] M1: GeoJSON ≤ 3MB, 5좌표 테스트 통과, 코드 대조 mismatch 0
- [ ] M2: 가짜 위치 김포 → "김포시", 권한 거부 → 지역 선택, 테스트 7개 통과
- [ ] M3: 전국 시군구 목록, 수원시 접기, 테스트 2개 통과
- [ ] M4: 수동 발송 → 알림 도착 → 홈, 끄면 오지 않음
- [ ] M5: 스토어를 거친 설치 + 관찰 기록 + 2주 카운트
- [ ] 전체: **어머님 폰에서 GPS로 김포시가 자동 설정되고, 실제 일자리를 보고 전화까지 걸리며, 월요일 푸시도 온다 — 기획서 1단계 「포함」 7항목 전부 동작**

---

## 8. 오픈 이슈

| # | 태그 | 내용 | 채택한 기본값 | 다르게 정해지면 | 언제까지 |
|---|---|---|---|---|---|
| 1 | 🔶 가정 | 폴리곤 단순화 허용 오차와 파일 크기 | 0.0005 / ≤3MB / 파싱 ≤1s | 시도별 분할 로드로 바꾼다 (M2 로더만 손보면 된다) | M1 |
| 2 | 🔶 가정 | 계측은 로컬 카운트만 | shared_preferences 카운터 | 전국 사용자 지표(기획서 핵심 15%)를 보려면 Firebase Analytics를 붙인다 — 개인정보 고지가 필요하다 | 전국 배포 전 |
| 3 | 🔵 오픈 질문 | 어머님 폰 기종과 Android 버전 | — | minSdk 24 미만이면 기기를 바꾸지 않는 한 M5를 할 수 없다 | M0 |
| 4 | 🔵 오픈 질문 | Play Console 계정 검증에 걸리는 기간 (기획서 🔵) | — | 길어지면 제한적 배포 계정으로 M5를 진행한다 | M5 전 |
| 5 | 🔵 오픈 질문 | 전남광주 동구의 법정동 시군구 코드 확정값 (기획서 회귀 5번 "12110대") | — | M1 대조 결과를 P2 `test_regions.py`와 P3 `test_geo.py` 양쪽에 적는다 | M1 |

---

## 9. 자체 점검

- **가장 불확실한 마일스톤**: **M1** — 33MB짜리 읍면동을 시군구로 합쳐 3MB 이하, 1초 이하로 만드는 일이 한 번에 될지, 법정동 코드와 `sgg`가 광주·전남에서 맞아떨어질지 둘 다 직접 재 보기 전엔 모른다.
- **틀리면 계획이 무너지는 가정**: ① 🔵#3 어머님 폰 OS — 카톡으로 "설정 → 휴대전화 정보" 스크린샷 한 장만 받으면 끝난다. ② 🔵#5 코드 체계 일치 — M1 대조 스크립트로 확인한다. ③ 🔶#1 파일 크기 — 안 되면 분할 로드로 넘길 수 있다.
- **지금 당장 뗄 첫걸음**: Play Console 개발자 계정 결제와 검증 신청(가장 오래 기다려야 한다). 그다음이 `flutter pub add geolocator firebase_core firebase_messaging`.
