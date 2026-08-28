# 오늘도청춘 (Still Young Days) — Phase 4 개발 계획서: 전국 복지관 행사 크롤링 · 위치 기반 제공 (v0.1)

작성일: 2026-08-28 | 버전: v0.1 | 베이스 커밋: (신규 저장소 — 아직 커밋 없음)

**한 줄 요약:** 기획서 「2단계 필수」를 구현한다 — 전국 노인복지관·종합사회복지관 홈페이지를 **CMS 유형별 파서 2개(gnuboard·COREIFRAME)로 39%부터** 수집해 `events/{시군구}.json`으로 내보내고, 앱 홈에 **"일자리 | 복지관 행사"** 전환 버튼을 붙여 어르신이 자기 동네 복지관의 이번 주 행사를 보게 한다. 봇 차단 13.5%는 **설계상 포기**하고 우회하지 않는다.

관련 문서: [기획서](../../ideas/senior-jobs-app-2026-08-28.md) · 이전 장: [P3 GPS·푸시·배포](still-young-days-p3-location-push-release-plan-v0.1.md)

> **착수 조건**: P3 M5 어머님 실사용에서 R4("원하는 건 일자리가 아니다")가 확인되면 이 Phase를 **P3보다 앞당긴다**. 그러면 M0~M4는 P2 M3(파이프라인)이 끝나는 대로 착수한다 — §4 참조.

## 목차

0. [레포 디렉터리 구조](#0-레포-디렉터리-구조) · 1. [확정 결정](#1-확정-결정-모음) · 2. [아키텍처](#2-아키텍처) · 3. [마일스톤](#3-마일스톤) · 4. [의존성](#4-의존성-그래프--병렬화-지점) · 5. [위험](#5-위험-요소와-완화책) · 6. [신규 파일](#6-신규-파일-목록-전체) · 7. [체크리스트](#7-완료-체크리스트) · 8. [오픈 이슈](#8-오픈-이슈) · 9. [자체 점검](#9-자체-점검)

---

## 0. 레포 디렉터리 구조

P2·P3 트리 위에 추가되는 파일만.

```
still-young-days-data/
├── pyproject.toml                        # 수정: beautifulsoup4, lxml 추가 (playwright 없음 — JS 렌더 사이트는 CUSTOM으로 분류만)
├── crawl/
│   ├── __init__.py
│   ├── registry.py                       # centers.json 로드/검증
│   ├── classify.py                       # 홈페이지 → CMS 유형 판별 (GNUBOARD/COREIFRAME/CUSTOM/BLOCKED/DEAD)
│   ├── robots.py                         # robots.txt 조회·허용 검사 (urllib.robotparser)
│   ├── fetch.py                          # 공통 HTTP: UA 고정, 기관당 1 req/s, 재시도 2회, 403은 즉시 BLOCKED
│   ├── parsers/
│   │   ├── base.py                       # Parser 인터페이스: list_posts(center) / parse_post(html) → RawEvent
│   │   ├── gnuboard.py                   # ?bo_table=X&page=N 목록, &wr_id=N 상세
│   │   ├── coreiframe.py                 # COREIFRAME 벤더 패턴
│   │   └── custom/                       # 기관별 파서 (M6). 파일명 = centerId
│   ├── dates.py                          # 본문에서 행사일 추출 ("2026.09.07", "9월 7일(월)", 기간)
│   ├── normalize.py                      # RawEvent → 공통 스키마 item(type="event")
│   ├── collect_events.py                 # 전 기관 순회 → data/events/{code}.json + coverage.json
│   └── health.py                         # 기관별 7일 이동평균 대비 0건 2회 연속 → 실패
├── tables/
│   ├── centers.json                      # 모집단 ★ {id, name, sgg, url, cms, boardPath, robotsOk, status}
│   └── centers_sources.md                # 목록 출처별 추출 방법·날짜 (서울복지포털, 부산시 …)
├── data/
│   ├── events/{code}.json                # 시군구별 행사 (공통 스키마, type=event)
│   ├── coverage.json                     # 시군구별 {centersTotal, centersCovered}
│   └── crawl_health/{YYYY-MM-DD}.json    # 기관별 건수 스냅샷
├── .github/workflows/crawl.yml           # 매일 04:00 KST (collect 이후)
└── tests/
    ├── test_classify.py · test_gnuboard.py · test_coreiframe.py · test_dates.py · test_health.py
    └── fixtures/html/                    # 저장한 실제 페이지 (기관명 유지, 개인정보 없음)

still-young-days-app/
├── lib/data/remote_item_repository.dart  # 수정: kind(job|event) 인자 → jobs/ 또는 events/ 경로
├── lib/screens/home_screen.dart          # 수정: 상단 "일자리 | 복지관 행사" 2탭 (64dp 세그먼트 버튼)
├── lib/widgets/item_card.dart            # 수정: type=event면 날짜 행 + 복지관명, 전화 버튼은 복지관 대표번호
├── lib/screens/detail_screen.dart        # 수정: 행사 항목 순서 + "원문 보기" 버튼(sourceUrl)
├── lib/widgets/coverage_notice.dart      # 신설: "지금 김포시 복지관 4곳 중 3곳 정보를 보여드려요"
└── test/screens/home_tabs_test.dart · test/widgets/item_card_event_test.dart
```

---

## 1. 확정 결정 모음

| 항목 | 확정값 | 근거 |
|---|---|---|
| 모집단 확보 경로 | **지자체 포털 우선** (서울복지포털 169, 부산시 23 실증) → 타 시도 순차. 협회 목록은 봇 차단으로 불가 | 기획서 §2단계 "목록 확보 경로" |
| 모집단 1차 범위 | 서울 + 부산 + **경기(김포 포함)** = 파일럿 3개 시도 🔶 가정 | 실증 데이터가 있는 두 곳에 어머님 지역을 더했다. 전국 확대는 M6 이후 — 오픈 이슈 #1 |
| CMS 분류 기준 | HTML에 `bo_table=` → GNUBOARD; COREIFRAME 벤더 시그니처(M1에서 확정) → COREIFRAME; 403/reCAPTCHA → BLOCKED; 타임아웃·빈 HTML → DEAD; 나머지 CUSTOM | 기획서 실측 분포 |
| 봇 차단 대응 | **없음. 403은 BLOCKED로 기록하고 재시도하지 않는다.** UA 위조·프록시·CAPTCHA 우회 금지 | 기획서 (법적·윤리적 부담이 크고 효과도 없다) |
| robots.txt | `robotparser`로 매 실행 확인, 불허면 그 기관은 건너뛰고 `robotsOk:false` 기록 | 기획서 법적 검토 "원칙" |
| 요청 예절 | UA `StillYoungDaysBot/1.0 (+연락 이메일)`, 기관당 **1 req/s**, 전체 동시 10 | 기획서 비용 산정(동시 10, 지연 1초) |
| 상세 요청 | 목록의 **최근 30일 게시물만** 상세 조회 (행사일이 상세에만 있으므로) | 기획서 제약 "요청량 15배" 완화 |
| 행사일 추출 | 정규식 우선(`dates.py`), 실패 시 `eventDate: null`로 두고 **버리지 않고** 게시일로 정렬 | 어르신에겐 날짜 없는 행사도 "이런 게 있구나" 하는 정보가 된다 |
| 이미지 시간표(JPG) | P4에선 **제목만** 수집, OCR 안 함 — 원문 링크로 넘긴다 | 기획서 "OCR 필요"는 3단계 이후 |
| JS 렌더 사이트 | playwright **도입 안 함** — CUSTOM으로 분류, M6 후보에서도 후순위 | Actions 시간·복잡도. 오픈 이슈 #2 |
| 법적 근거 | 공정이용(저작권법 §35조의5) — **TDM 예외 아님**. 제목·일시·장소·요약 200자 + 원문 링크만 저장, 본문 전문 저장 금지 | 기획서 정정 사항 |
| 출력 스키마 | P1 공통 스키마 `type:"event"`, 추가 필드 `eventDate`, `eventEnd`, `centerName`, `sourceUrl`(필수) | P1 §2 |
| 전화 버튼(행사) | 복지관 **대표번호**(`centers.json.phone`) | 행사 게시물엔 번호가 없는 경우가 많다 |
| 앱 전환 UI | 홈 상단 2분할 세그먼트 "일자리 / 복지관 행사", 각 ≥64dp, 선택 상태는 색+굵은 테두리+체크 글자 3중 | 기획서 UI 기준 (색만으로 구분 금지) |
| 커버리지 고지 | 홈 행사 탭 상단 `CoverageNotice` "김포시 복지관 4곳 중 3곳" | 기획서 R6 |
| 깨짐 감지 | 기관별 7일 이동평균 대비 0건 **2회 연속** → 워크플로 실패 | 기획서 |
| 크롤링 저장소 | `still-young-days-data` 동일 private 레포 | 파이프라인 코드 공유. 기획서의 "public이면 Actions 무제한"은 private 2,000분/월과 비교해 M4에서 재판단 — 오픈 이슈 #3 |

---

## 2. 아키텍처

```
 tables/centers.json (모집단)
   │  M0: 지자체 포털에서 추출  M1: classify → cms 채움
   ▼
 crawl.yml (매일 04:00 KST, collect 뒤)
 ┌───────────────────────────────────────────────────────────────┐
 │ for center in centers where status==ACTIVE and robotsOk:       │
 │   parser = {GNUBOARD: gnuboard, COREIFRAME: coreiframe,        │
 │             CUSTOM: custom[center.id] or skip}                 │
 │   posts  = parser.list_posts(center)      # 최근 30일 게시물   │
 │   events = [parser.parse_post(fetch(p)) for p in posts]        │
 │   → dates.extract → normalize(type=event, sourceUrl 필수)      │
 │ → data/events/{sgg}.json, coverage.json, crawl_health/today    │
 │ → health.check(): 기관별 0건 2회 연속이면 exit 1 (커밋 안 함)  │
 └───────────────────────────────┬───────────────────────────────┘
                                 ▼
 Flutter  Home ── [일자리] jobs/{code}.json  (P2)
               └─ [복지관 행사] events/{code}.json + coverage.json → CoverageNotice
```

| 영역 | 선택 | 비고 |
|---|---|---|
| HTML 파싱 | `beautifulsoup4` + `lxml` | JS 렌더 없음 |
| 스케줄 | Actions cron 04:00 KST | collect(03:00) 이후 |
| 인코딩 | `resp.content` + `EUC-KR` 폴백 감지 (gnuboard 구버전) | `chardet` 대신 meta charset 우선 |
| 앱 | P1~P3 컴포넌트 재사용, 신규 위젯 1개 | 카드·상세는 `type` 분기 |

---

## 3. 마일스톤

### M0 — 준비: 모집단 확정 + robots 검사기 + 김포 파일럿

#### 목표
`centers.json`에 서울·부산·경기 복지관이 URL과 시군구 코드까지 갖춰 들어 있고, 전 기관의 robots.txt 허용 여부가 기록돼 있다. "800곳"이라는 미검증 숫자가 실측치로 바뀐다.

#### 산출물
- `tables/centers.json`, `tables/centers_sources.md` — 신설
- `crawl/registry.py`, `crawl/robots.py`, `crawl/fetch.py` — 신설
- `tests/test_registry.py` (스키마·중복 URL 검사) — 신설

#### 핵심 작업
1. 서울복지포털(169)·부산시(23) 추출 스크립트를 재실행해 최신화, 경기도는 경기복지재단/각 시군 포털에서 확보 — **출처·추출일·방법을 `centers_sources.md`에 기록**.
2. 각 기관 주소 → P2 `regions.resolve()`로 `sgg` 채움 (P2 코드 재활용). 실패한 건은 손으로 보정.
3. `centers.json` 스키마:
   ```json
   {"id":"gimpo-senior-01","name":"김포시노인종합복지관","sgg":"41570","phone":"031-…",
    "url":"https://…","cms":null,"boardPath":null,"robotsOk":null,"status":"NEW"}
   ```
4. `fetch.py`: UA 고정, `timeout=15`, 403/429는 **즉시 BLOCKED 반환**(재시도 없음), 기관별 마지막 요청 시각으로 1 req/s 보장.
5. 기획서의 김포 4곳 크롤러 설계(보관분)를 `crawl/parsers/custom/`의 첫 파서 후보로 옮겨 놓는다(구현은 M2·M6).

#### 완료 기준
- `centers.json` 건수 ≥ 192 + 경기 분, `sgg` null 0건, URL 중복 0건 (`test_registry.py` 통과)
- `python -m crawl.robots --all` → 전 기관 `robotsOk` 채움, 불허 기관 수는 README에 기록
- 기획서 🔵 "정확히 몇 곳"에 대한 **파일럿 3개 시도 기준 답**을 모집단 수로 README에 기록

#### 회귀 가드레일 — 깨지면 안 되는 것
- P2 `test_regions.py` 5개 통과 (resolve 재사용 중 수정 금지)

---

### M1 — CMS 분류기

#### 목표
모든 기관에 `cms`가 채워지고, 분포가 기획서 실측(GNUBOARD 26%, COREIFRAME 13%, BLOCKED 13.5%)과 비교 가능한 표로 나온다.

#### 산출물
- `crawl/classify.py`, `tests/test_classify.py`, `tests/fixtures/html/{gnuboard,coreiframe,blocked}.html` — 신설
- `tables/centers.json` — 수정 (`cms`, `boardPath` 채움)

#### 핵심 작업
1. 판별 규칙(순서대로):
   - 응답 403 / 본문에 reCAPTCHA·`allbandazole` → `BLOCKED`
   - 타임아웃·DNS 실패·본문 < 500B → `DEAD`
   - 링크 중 `bo_table=` 존재 → `GNUBOARD`, 게시판 후보 = 링크 텍스트가 "행사|프로그램|공지|소식"인 `bo_table` 값
   - COREIFRAME 시그니처 → `COREIFRAME` (시그니처는 M1에서 실제 페이지 3곳을 대조해 **확정하고 테스트에 고정** 🔵 오픈 이슈 #4)
   - 나머지 → `CUSTOM`
2. `boardPath`: 행사·프로그램 게시판 URL. GNUBOARD는 자동, 나머지는 `null`.
3. 분포표 출력 → README.

#### 완료 기준
- `test_classify.py`: 픽스처 3종 → 기대 유형, 403 → BLOCKED, 빈 본문 → DEAD — 5개 통과
- 전 기관 `cms != null`
- 분포표의 GNUBOARD 비율이 기획서 95% CI(19.8~32.2%) 안에 든다 — 벗어나면 오픈 이슈 #5에 원인 기록

#### 회귀 가드레일 — 깨지면 안 되는 것
- `test_registry.py` 통과 (분류 작업이 레코드 스키마를 깨지 않는다)

---

### M2 — gnuboard 파서 + 행사일 추출 (커버리지 26%)

#### 목표
GNUBOARD 기관 전부에서 최근 30일 행사 게시물을 제목·게시일·행사일·요약·원문 링크로 뽑아낸다.

#### 산출물
- `crawl/parsers/base.py`, `crawl/parsers/gnuboard.py`, `crawl/dates.py` — 신설
- `tests/test_gnuboard.py`, `tests/test_dates.py`, `tests/fixtures/html/gnuboard_list.html`, `gnuboard_view.html` — 신설

#### 핵심 작업
1. 인터페이스:
   ```python
   @dataclass
   class RawEvent: title:str; postedAt:date; url:str; body:str; eventDate:date|None=None; eventEnd:date|None=None
   class Parser(Protocol):
       def list_posts(self, center) -> list[tuple[str, date]]: ...   # (url, postedAt)
       def parse_post(self, html: str, url: str) -> RawEvent: ...
   ```
2. gnuboard 목록: `{boardPath}&page={n}`, 행 `tr` → `a[href*=wr_id]` + 날짜 셀. `postedAt < today-30d`가 나오면 페이징 중단.
3. 상세: `#bo_v_con` 본문 텍스트(이미지 alt 포함), 요약 = 앞 200자.
4. `dates.extract(text) -> (date|None, date|None)`: 패턴 우선순위 `2026.09.07`, `2026-09-07`, `9월 7일`, 기간 `~`. 연도가 없으면 게시 연도를 쓰고, 게시일보다 60일 이상 과거면 다음 해로 보정. **추출 실패는 None**.
5. 인코딩: `<meta charset>` 우선, 없으면 EUC-KR 시도 후 UTF-8.

#### 완료 기준
- `test_gnuboard.py`: 픽스처 목록 → 게시물 N건·URL·날짜; 30일 경계 중단 — 3개 통과
- `test_dates.py`: 6개 패턴 + 실패 케이스 — 7개 통과
- 실행 로그: GNUBOARD 기관 중 게시물을 1건 이상 뽑아낸 비율 ≥ 80% 🔶 (미달이면 게시판 자동 탐지 규칙 보강)

#### 회귀 가드레일 — 깨지면 안 되는 것
- 없음 (신규 파일만)

---

### M3 — COREIFRAME 파서 (누적 39%)

#### 목표
COREIFRAME 벤더를 쓰는 기관 전부를 M2와 같은 품질로 뽑아낸다.

#### 산출물
- `crawl/parsers/coreiframe.py`, `tests/test_coreiframe.py`, `tests/fixtures/html/coreiframe_*.html` — 신설

#### 핵심 작업
1. 벤더 게시판 URL·상세 패턴을 실제 기관 3곳에서 확인해 고정한다(🔵 오픈 이슈 #4도 여기서 함께 해소).
2. `dates.py`·`RawEvent` 재사용 — 파서는 목록·상세 셀렉터만 다르다.

#### 완료 기준
- `test_coreiframe.py` 3개 통과
- 실행 로그: 추출에 성공한 GNUBOARD+COREIFRAME 기관 / 전체 기관 ≥ 35%

#### 회귀 가드레일 — 깨지면 안 되는 것
- 공용 모듈을 수정했다면 `test_gnuboard.py`·`test_dates.py` 통과

---

### M4 — 정규화 · 출력 · Actions · 깨짐 감지

#### 목표
매일 04:00 `data/events/{sgg}.json`·`coverage.json`이 자동 커밋되고, 특정 기관이 조용히 죽으면 워크플로가 실패한다.

#### 산출물
- `crawl/normalize.py`, `crawl/collect_events.py`, `crawl/health.py` — 신설
- `.github/workflows/crawl.yml` — 신설
- `data/events/*.json`, `data/coverage.json`, `data/crawl_health/*.json` — 신설
- `tests/test_health.py`, `tests/test_schema.py` — 수정 (event 스키마 케이스 추가)

#### 핵심 작업
1. `normalize`: `RawEvent` → item — `id: "center:{centerId}:{wr_id}"`, `title`, `place: centerName`, `address: center.address`, `phone: center.phone`, `org: centerName`, `description: summary(≤200자)`, `eventDate`/`eventEnd`, `applyStart: null`, `source: "crawl"`, `sourceUrl: url`(필수). **본문 전문 저장 금지**(공정이용 범위).
2. 정렬: `eventDate`(없으면 `postedAt`) 오름차순, 지난 행사(`eventEnd or eventDate < today`) 제외.
3. `coverage.json`: 시군구별 `centersTotal`(NEW·BLOCKED·DEAD 포함) / `centersCovered`(오늘 추출에 성공한 기관 수).
4. `health.py`: 오늘 기관별 건수 vs 최근 7일 평균 — 평균 ≥ 2인데 오늘 0건이 **2일 연속** → exit 1, 커밋 안 함, Actions 실패 이메일.
5. `crawl.yml`: private 레포 Actions 사용 시간을 첫 주에 측정 — 월 2,000분을 넘길 것 같으면 오픈 이슈 #3을 결정한다.

#### 완료 기준
- `test_schema.py` event 케이스: `sourceUrl` 필수, `description ≤ 200자`, `type == "event"` — 3개 통과
- `test_health.py`: 2일 연속 0건 → 실패, 1일만 0건 → 통과, 신규 기관 → 통과 — 3개 통과
- `workflow_dispatch` → `data/events/41570.json` 존재 (김포 GNUBOARD 3곳 중 ≥1곳 데이터)
- 한 기관 URL을 일부러 깨서 2일 실행 → 워크플로 실패 확인

#### 회귀 가드레일 — 깨지면 안 되는 것
- P2 `collect.yml`·P3 `notify.yml` 초록 유지 (Actions 시간을 다 써서 막히는 일이 없어야 한다)

---

### M5 — 앱: 복지관 행사 탭 + 커버리지 고지

#### 목표
홈 상단 "일자리 | 복지관 행사"를 누르면 내 동네 복지관 행사가 카드로 보이고, 상세 화면에는 "원문 보기"와 복지관 전화가 있으며, 상단에 몇 곳의 정보인지 솔직하게 표시된다.

#### 산출물
- `lib/widgets/coverage_notice.dart` — 신설
- `lib/data/remote_item_repository.dart`, `lib/screens/home_screen.dart`, `lib/widgets/item_card.dart`, `lib/screens/detail_screen.dart` — 수정
- `assets/mock/events_41570.json` — 신설 (P1 방식 목 데이터로 UI 먼저)
- `test/screens/home_tabs_test.dart`, `test/widgets/item_card_event_test.dart` — 신설

#### 핵심 작업
1. **P1 원칙 반복**: 목 `events_41570.json`으로 UI를 먼저 만들고 M4 실데이터로 교체.
2. `RemoteItemRepository.fetchItems(code, kind)` — `kind == event`면 `events/` 경로 + `coverage.json` 동시 요청. 캐시 키 분리.
3. 홈 세그먼트: `BigButton` 2개를 가로로 배치하고, 선택된 쪽은 진한 바탕에 "✓ 일자리" 글자. 선택 상태는 `SettingsStore.lastKind`에 저장해 다시 켜도 유지한다.
4. 카드(event): 1행은 제목, 2행은 "9월 7일 (월) · 김포시노인종합복지관", 전화 버튼은 복지관 대표번호. `eventDate == null`이면 2행에 복지관명만 넣는다.
5. 상세(event): 언제(`eventDate`) · 어디서(`place`+`address`) · 내용(요약) · **"원문 보기"** `BigButton`(`launchUrl(sourceUrl, mode: externalApplication)`) · 하단 고정 전화.
6. `CoverageNotice`: "지금 김포시 복지관 4곳 중 3곳 정보를 보여드려요" — 0곳이면 "아직 김포시 복지관 정보는 준비 중이에요" + 일자리 탭 유도.
7. P3 푸시는 **일자리만 유지** — 행사 푸시는 오픈 이슈 #6.

#### 완료 기준
- `home_tabs_test.dart`: 탭 전환 → 리포지토리 `kind` 인자 변경; 세그먼트 높이 ≥ 64; 다시 켰을 때 마지막 탭 유지 — 3개 통과
- `item_card_event_test.dart`: 날짜에 요일 함께 표시; `eventDate`가 null이면 날짜 숨김; 전화 버튼은 대표번호 — 3개 통과
- 에뮬레이터: 김포 실데이터 행사 카드 → 상세 → "원문 보기"로 복지관 페이지 열림
- P1~P3 `flutter test` 전부 통과

#### 회귀 가드레일 — 깨지면 안 되는 것
- P1 `home_screen_test.dart`·`detail_screen_test.dart` — 일자리 탭 동작은 그대로 유지
- P2 `remote_item_repository_test.dart` — 시그니처를 바꾼 뒤에도 4개 케이스가 통과하도록 갱신

---

### M6 — CUSTOM 대도시 선별 파서 (누적 50%+ 목표)

#### 목표
서울·부산·경기의 CUSTOM 기관 중 **시군구마다 최소 1곳**은 커버되도록 개별 파서를 추가해, 파일럿 3개 시도 커버리지 50%를 넘긴다.

#### 산출물
- `crawl/parsers/custom/{centerId}.py` × N — 신설
- `tests/test_custom_{centerId}.py` × N — 신설

#### 핵심 작업
1. 우선순위: `coverage.json`에서 `centersCovered == 0`인 시군구 → 그 시군구의 CUSTOM 기관 중 게시판 URL 패턴이 단순한 곳(`?page=N` 형태) 순. 암호화 파라미터(`zipEncode=`)·JS 렌더는 **제외**.
2. 파서 하나 = `Parser` 프로토콜 구현 + 픽스처 2장 + 테스트 2개. 하루 2~3개 속도로 만든다.
3. 기관별 파서는 `centers.json`에 `cms: "CUSTOM"` + `parser: "{centerId}"`로 등록한다.

#### 완료 기준
- 파일럿 3개 시도 커버리지(`sum(centersCovered)/sum(centersTotal)`) ≥ 50%
- `centersCovered == 0`인 시군구 수가 M5 시점 대비 절반 이하
- 신규 테스트 전부 통과

#### 회귀 가드레일 — 깨지면 안 되는 것
- `health.py`가 기존 기관 기준선을 그대로 유지 (기관별로 계산하므로 신규 기관을 추가해도 평균이 흔들리지 않는다)

---

## 4. 의존성 그래프 · 병렬화 지점

```
M0 ─→ M1 ─┬→ M2 ─┬→ M4 ─→ M5(실데이터 교체) ─→ M6
          │      │
          └→ M3 ─┘        M5(목 UI 부분)는 M0 직후 병렬 가능
```

- **M2·M3는 병렬로 간다** — 파서끼리 서로 독립이고, `dates.py`만 공유한다(M2에서 먼저 만든 뒤).
- **M5의 목 데이터 UI는 M0 직후** 시작할 수 있다 — P1과 같은 방식. 실데이터 교체만 M4 뒤로 미룬다.
- **앞당기는 경우**(R4 확인 시): P2 M3까지만 끝나 있으면 M0~M4를 착수한다. P3(GPS·푸시)는 뒤로 밀린다.

---

## 5. 위험 요소와 완화책

| 위험 | 확률 | 영향 | 완화책 |
|---|---|---|---|
| 경기도 복지관 목록 출처가 서울·부산만큼 깔끔하지 않다 🔶 | 높 | M0 | 경기는 김포를 포함한 **상위 10개 시**만 1차로 하고 나머지는 M6 이후 — 오픈 이슈 #1 |
| COREIFRAME 시그니처·게시판 패턴이 기관마다 미묘하게 다르다 🔵 | 중 | M1·M3 | 실제 기관 3곳을 대조해 고정하고, 안 맞는 기관은 CUSTOM으로 재분류 |
| 행사일 추출 실패가 잦아 카드 대부분에 날짜가 없다 | 중 | M2·M5 | `eventDate`가 null이어도 표시하는 설계라 정보가 사라지지는 않는다. 패턴은 실패 로그가 많은 것부터 추가 |
| private 레포 Actions 월 2,000분 초과 (일 24.5분 × 30 = 735분 + collect·notify) | 저 | M4 | 첫 주에 실측하고, 넘치면 출력 `data/`만 public 저장소로 분리(P2 🔵#2와 같은 해법) |
| 특정 기관이 항의하거나 차단을 요청 | 저 | 법적 | UA에 연락처를 명시하고, 요청이 오면 즉시 `status: OPTOUT`으로 제외. 절차는 README에 |
| 기관 사이트 개편으로 파서가 무더기로 실패 | 중 | 운영 | `health.py`로 기관별 감시 + 픽스처 갱신 절차 |

---

## 6. 신규 파일 목록 (전체)

```
still-young-days-data/
  crawl/__init__.py · registry.py · classify.py · robots.py · fetch.py · dates.py · normalize.py · collect_events.py · health.py
  crawl/parsers/base.py · gnuboard.py · coreiframe.py · custom/{centerId}.py…
  tables/centers.json · centers_sources.md
  data/events/*.json · coverage.json · crawl_health/*.json
  .github/workflows/crawl.yml
  tests/test_registry.py · test_classify.py · test_gnuboard.py · test_coreiframe.py · test_dates.py · test_health.py · test_custom_*.py
  tests/fixtures/html/*.html
still-young-days-app/
  assets/mock/events_41570.json
  lib/widgets/coverage_notice.dart
  test/screens/home_tabs_test.dart · test/widgets/item_card_event_test.dart
```

---

## 7. 완료 체크리스트

- [ ] M0: `centers.json` 서울·부산·경기, robots 전수, 모집단 실측치 기록
- [ ] M1: 전 기관 CMS 분류, 분포표가 기획서 CI 안에 든다
- [ ] M2: gnuboard 파서 + 날짜 추출, 테스트 10개, 성공 기관 ≥ 80%
- [ ] M3: COREIFRAME 파서, 합산 ≥ 35%
- [ ] M4: 매일 자동 커밋 + 기관별 깨짐 감지 실증
- [ ] M5: 앱 행사 탭·원문 보기·커버리지 고지, P1~P3 테스트 통과
- [ ] M6: 파일럿 3개 시도 커버리지 ≥ 50%
- [ ] 전체: **어머님 폰에서 "복지관 행사" 탭 → 김포시 복지관 이번 주 행사 카드 → 원문 보기·전화 완주. 기획서 2단계 필수 항목 충족**

---

## 8. 오픈 이슈

| # | 태그 | 내용 | 채택한 기본값 | 다르게 정해지면 | 언제까지 |
|---|---|---|---|---|---|
| 1 | 🔶 가정 | 모집단 1차 범위 | 서울·부산·경기 | 곧바로 전국으로 가면 M0에만 몇 주가 든다 — 시도별 포털 조사가 먼저 | M0 |
| 2 | 🔶 가정 | JS 렌더 사이트 미지원 | playwright 없음 | 주요 기관이 JS 렌더면 M6에서 playwright 도입(Actions 시간 3~5배) | M6 |
| 3 | 🔶 가정 | 크롤링을 private 레포 Actions에서 실행 | 동일 레포 | 월 2,000분을 넘기면 `data/`를 public으로 분리 | M4 첫 주 |
| 4 | 🔵 오픈 질문 | COREIFRAME 벤더 시그니처·게시판 URL 패턴 | — | 모르면 M1 분류와 M3 파서를 시작할 수 없다 | M1 |
| 5 | 🔵 오픈 질문 | 경기도 복지관 목록 출처 (기획서 🔵 "정확히 몇 곳") | — | 없으면 김포 4곳 + 수동 목록으로 M0를 축소 | M0 |
| 6 | 🔵 오픈 질문 | 행사 푸시를 보낼지 (주 1회 일자리 푸시와 합칠지) | 보내지 않음 | 합치면 P3 `notify.py` 문구·diff를 확장 | M5 후 |
| 7 | 🔶 가정 | gnuboard 기관 추출 성공률 ≥ 80% | 게시판 자동 탐지 규칙 | 미달이면 `boardPath`를 직접 지정 | M2 |

---

## 9. 자체 점검

- **가장 불확실한 마일스톤**: **M0** — 경기도 모집단 출처가 없다. 서울·부산은 실증됐지만 경기는 조사조차 안 됐다. 안 나오면 "김포 4곳 파일럿"으로 줄여도 어머님 검증에는 충분하다.
- **틀리면 계획이 무너지는 가정**: ① 🔵#4 COREIFRAME 패턴 — 실제 기관 3곳만 열어 보면 반나절이면 확인된다. ② 🔶#7 gnuboard 80% — M2 첫 실행 로그에서 바로 드러난다. ③ 🔶#1 범위 — 틀려도 범위를 줄여 흡수한다.
- **지금 당장 뗄 첫걸음**: 서울복지포털 169곳 추출 스크립트를 data 레포 `tables/centers_sources.md`에 옮겨 적고 다시 실행한다 — 기획서 조사 때 만든 결과를 코드로 고정하는 일부터.
