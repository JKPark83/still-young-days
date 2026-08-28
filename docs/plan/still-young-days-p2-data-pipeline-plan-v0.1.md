# 오늘도청춘 (Still Young Days) — Phase 2 개발 계획서: 데이터 파이프라인 + 실데이터 연결 (v0.1)

작성일: 2026-08-28 | 버전: v0.1 | 베이스 커밋: (신규 저장소 — 아직 커밋 없음)

**한 줄 요약:** private 저장소 `still-young-days-data`에 Python 수집기 + GitHub Actions를 세워 Senuri API 전량을 **시군구별 정적 JSON**으로 매일 커밋하고, Phase 1 앱의 `MockItemRepository`를 `RemoteItemRepository`로 갈아끼워 **김포시 실제 일자리**가 카드에 뜨게 한다. GPS·푸시는 여전히 없다(P3).

관련 문서: [기획서](../../ideas/senior-jobs-app-2026-08-28.md) · 이전 장: [P1 목 UI](still-young-days-p1-ui-mock-plan-v0.1.md) · 다음 장: [P3 GPS·푸시·배포](still-young-days-p3-location-push-release-plan-v0.1.md)

## 목차

0. [레포 디렉터리 구조](#0-레포-디렉터리-구조) · 1. [확정 결정](#1-확정-결정-모음) · 2. [아키텍처](#2-아키텍처) · 3. [마일스톤](#3-마일스톤) · 4. [의존성](#4-의존성-그래프--병렬화-지점) · 5. [위험](#5-위험-요소와-완화책) · 6. [신규 파일](#6-신규-파일-목록-전체) · 7. [체크리스트](#7-완료-체크리스트) · 8. [오픈 이슈](#8-오픈-이슈) · 9. [자체 점검](#9-자체-점검)

---

## 0. 레포 디렉터리 구조

데이터 저장소 `still-young-days-data` (**private**, Phase 2 종료 시점).

```
still-young-days-data/
├── pyproject.toml                   # Python 3.12, deps: httpx, pytest (XML은 표준 xml.etree)
├── .github/workflows/
│   ├── collect.yml                  # 매일 03:00 KST cron + workflow_dispatch
│   └── test.yml                     # PR·push 시 pytest
├── pipeline/
│   ├── __init__.py
│   ├── senuri_client.py             # getJobList/getJobInfo 호출, XML→dict, resultCode "0000" 검사
│   ├── probe.py                     # M1 실측: totalCount·지역분포·갱신주기 CSV
│   ├── regions.py                   # 주소 문자열 → 법정동 시군구 5자리 (별칭·세종·수원 처리)
│   ├── normalize.py                 # Senuri 레코드 → 공통 JSON 스키마 item
│   ├── collect.py                   # 전량 수집 → data/jobs/{code}.json + index.json
│   └── notify.py                    # (P3) FCM HTTP v1 — P2에선 빈 파일
├── tables/
│   ├── sigungu.json                 # 법정동 시군구 마스터 (코드·시도명·시군구명·표시명)
│   ├── aliases.json                 # 구↔신 명칭 별칭 (광주·전남→12, 강원특별자치도 등)
│   └── raw/                         # 행안부 법정동코드 전체자료 원본 (txt, 커밋)
├── data/                            # ★ Actions가 커밋하는 출력. 앱은 여기만 읽는다
│   ├── index.json                   # {generatedAt, regions:[{code,name,count}]}
│   └── jobs/
│       └── 41570.json …             # 시군구별 공통 스키마
├── probe/
│   └── 2026-08-XX-senuri-probe.csv  # M1 실측 결과 (커밋해 근거로 남김)
└── tests/
    ├── test_regions.py              # 회귀 테스트 5개 고정 ★
    ├── test_normalize.py
    ├── test_schema.py               # 출력 JSON이 P1 스키마와 일치하는지
    └── fixtures/                    # 실제 XML 응답 샘플 (키 마스킹)
```

앱 저장소 변경분(P1 트리 위에 추가):

```
still-young-days-app/
├── lib/data/remote_item_repository.dart   # 신설
├── lib/data/feed_cache.dart               # 신설: 파일 캐시 + ETag
├── lib/data/mock_item_repository.dart     # 유지 (테스트·오프라인 개발용)
├── lib/app.dart                           # 수정: Remote 주입, 캐시 폴백
└── test/data/remote_item_repository_test.dart · feed_cache_test.dart
```

---

## 1. 확정 결정 모음

| 항목 | 확정값 | 근거 |
|---|---|---|
| 파이프라인 언어 | **Python 3.12** | 사용자 답변 |
| HTTP 클라이언트 | `httpx` 🔶 가정 | 동기 호출과 재시도가 간단하다. `requests`를 써도 된다 — 오픈 이슈 #1 |
| 저장소 | `still-young-days-data` **private** | 기획서 (60일 무활동 비활성화 회피) · 사용자 답변(레포 분리) |
| 앱이 읽는 URL | `https://raw.githubusercontent.com/<owner>/still-young-days-data/main/data/jobs/{code}.json` | private이라 **읽기 전용 토큰이 있어야 한다** → 오픈 이슈 #2 (🔵) |
| 수집 주기 | 매일 03:00 KST (`cron: '0 18 * * *'` UTC) + `workflow_dispatch` | 기획서 아키텍처 "일 1회" |
| 상세 조회 | 목록 전량 → 각 `jobId`로 `getJobInfo?id=` 호출 | 조사: 상세 파라미터명은 **`id`** |
| 성공 판정 | `header/resultCode == "0000"` | 조사 (`"00"` 아님) |
| 마감 필터 | `deadline == "마감"` **또는** `toDd < 오늘` → 제외 | 조사 (문자열 필드) · 기획서 R5 |
| 일 호출 한도 | 10,000건 | 기획서. 목록 페이지 + 상세 건수 합이 한도를 넘으면 M1에서 대응책을 정한다 |
| 지역 판정 입력 | 상세 `plDetAddr`(사업장 주소) 우선, 없으면 목록 `workPlcNm` | 조사 필드명 |
| 코드 체계 | 법정동 시군구 5자리 | 기획서 |
| 광주·전남 | `aliases.json`으로 "광주광역시 동구"→`12110`계 매핑 | 기획서 함정 1 |
| 세종 | 문자열에 시군구 없어도 `36110` 고정 | 기획서 함정 2 |
| 수원처럼 구가 빠진 모시 주소 | **모시 산하 모든 구 JSON에 복제** | 사용자 답변 |
| 일반구 키 | 구 단위 5자리(`41117`), 앱 표시는 "수원시" | 기획서 함정 3 |
| 주소 정규화 | juso.go.kr **사용 안 함** — 시도·시군구 문자열 매칭 + 별칭 테이블로 충분 🔶 가정 | 시군구만 가리면 되니 읍면동은 필요 없다. 실패율은 M3에서 측정 — 오픈 이슈 #3 |
| 앱 캐시 | `path_provider` 앱 문서 폴더에 `jobs_{code}.json` + `etag_{code}` | 기획서. ETag 304면 캐시를 쓴다 |
| 인코딩 | `utf8.decode(res.bodyBytes)` | 기획서 함정 |
| 앱 "○월 ○일 기준" 표시 | `index.json.generatedAt` → 홈 상단 캡션 | 기획서 R5 |

---

## 2. 아키텍처

```
 still-young-days-data (private, GitHub Actions 매일 03:00 KST)
 ┌────────────────────────────────────────────────────────────────┐
 │ collect.py                                                      │
 │  ① getJobList pageNo=1.. numOfRows=100 → totalCount까지 페이징  │
 │  ② deadline/toDd 필터 → 살아있는 jobId 목록                     │
 │  ③ getJobInfo?id=jobId (동시 4, 0.25s 간격) → 상세 dict          │
 │  ④ regions.resolve(plDetAddr) → 시군구 5자리 (실패는 unresolved) │
 │  ⑤ normalize → item(공통 스키마) → data/jobs/{code}.json        │
 │  ⑥ index.json 갱신 → git commit && push (변경 있을 때만)         │
 └──────────────────────────────┬─────────────────────────────────┘
                                │ raw.githubusercontent.com (+ 읽기 토큰)
                                ▼
 Flutter  RemoteItemRepository ──▶ FeedCache(ETag) ──▶ RegionFeed ──▶ (P1 화면 그대로)
              └─ 실패 시 캐시 → 캐시도 없으면 "불러오지 못했어요 · 다시 시도" 배너
```

| 영역 | 선택 | 비고 |
|---|---|---|
| 수집 | Python 3.12 + httpx | 재시도 3회, 지수 백오프 |
| 파싱 | `xml.etree.ElementTree` | 외부 라이브러리 없이 표준 모듈만 |
| 스케줄 | GitHub Actions cron | 무료, private |
| 출력 | 정적 JSON, `schemaVersion: 1` | P1 §2 스키마 그대로 |
| 앱 네트워크 | `http ^1.6.0` | `If-None-Match` 헤더 |
| 앱 캐시 | `path_provider ^2.1.6` | 문서 폴더 |

---

## 3. 마일스톤

### M0 — 준비: 데이터 저장소 + API 키 + Python 환경

#### 목표
`still-young-days-data` 저장소를 만들고, data.go.kr 인증키를 Actions secret에 넣고, 로컬에서 `pytest`가 빈 테스트로 통과한다.

#### 산출물
- `pyproject.toml`, `.github/workflows/test.yml` — 신설
- `pipeline/__init__.py`, `tests/__init__.py` — 신설
- GitHub secret `DATA_GO_KR_KEY` — 설정

#### 핵심 작업
1. data.go.kr 회원가입 → [15015153](https://www.data.go.kr/data/15015153/openapi.do) 활용신청(자동승인) → 인증키 확보. **키는 커밋 금지**, `.env`는 `.gitignore`.
2. `gh repo create still-young-days-data --private`, `pyproject.toml`:
   ```toml
   [project]
   name = "still-young-days-data"; requires-python = ">=3.12"
   dependencies = ["httpx>=0.27"]
   [project.optional-dependencies]
   dev = ["pytest>=8"]
   ```
3. `test.yml`: `actions/setup-python@v5` (3.12) → `pip install -e .[dev]` → `pytest`.

#### 완료 기준
- `curl "https://apis.data.go.kr/B552474/SenuriService/getJobList?serviceKey=$KEY&pageNo=1&numOfRows=1"` → `<resultCode>0000</resultCode>` 포함
- GitHub Actions `test.yml` 초록불 (테스트 0개 통과)

#### 회귀 가드레일 — 깨지면 안 되는 것
- 없음 (신규 저장소)

---

### M1 — Senuri 실측 (🔵 3건 해소)

#### 목표
전체 건수, 갱신 주기, 시군구 분포, **김포시 건수**를 CSV로 확보해 기획서 R3("김포에 일자리가 거의 없을 수 있다")에 답한다.

#### 산출물
- `pipeline/senuri_client.py` — 신설
- `pipeline/probe.py` — 신설
- `probe/2026-08-XX-senuri-probe.csv` — 신설 (커밋)
- `tests/fixtures/joblist_page1.xml`, `jobinfo_sample.xml` — 신설 (키 마스킹한 실응답)

#### 핵심 작업
1. 클라이언트:
   ```python
   def get_job_list(page: int, rows: int = 100) -> tuple[list[dict], int]:
       r = httpx.get(BASE + "/getJobList", params={"serviceKey": KEY, "pageNo": page, "numOfRows": rows}, timeout=20)
       root = ET.fromstring(r.content)               # bytes — 인코딩 문제 회피
       if root.findtext("header/resultCode") != "0000": raise SenuriError(...)
       items = [{c.tag: c.text for c in it} for it in root.iter("item")]
       return items, int(root.findtext("body/totalCount"))

   def get_job_info(job_id: str) -> dict:            # 파라미터명은 id
       ...params={"serviceKey": KEY, "id": job_id}...
   ```
2. `probe.py`: 목록 전량 페이징 → `totalCount`, `stmId` 분포(A/B/C), `deadline` 비율, `workPlcNm` 상위 50, **`frDd` 최신값**(갱신 주기 추정). 상세는 **표본 200건만** 호출해 `plDetAddr`와 `clerkContt`의 채움률을 잰다.
3. 3일 연속 실행해 `totalCount` 변화와 신규 `jobId` 수를 기록 → 갱신 주기.
4. 결과를 CSV로 남기고, 기획서 오픈 질문에 대한 답까지 README에 표로 정리한다.

#### 완료 기준
- `probe/*.csv`에 컬럼: `date,totalCount,newJobIds,deadlineRatio,addrFillRate,phoneFillRate,gimpoCount` 3행 이상
- 일 호출 수 산정: `ceil(totalCount/100) + 살아있는 건수`를 계산해 10,000 이하인지 판정하고 기록
- 김포시(`workPlcNm` 또는 주소에 "김포") 건수 기록 — **0이면 즉시 기획 재검토 신호**

#### 회귀 가드레일 — 깨지면 안 되는 것
- 없음 (신규 파일만)

---

### M2 — 법정동코드 마스터 + 별칭 테이블 + 회귀 테스트 5개 ★

#### 목표
어떤 주소 문자열이 들어와도 `resolve()`가 시군구 5자리(여러 개이거나 `None`일 수도 있다)를 돌려주고, 기획서 회귀 테스트 5개를 CI에 고정한다.

#### 산출물
- `tables/raw/법정동코드_전체자료.txt` — 신설 (행안부 원본, 2026-07-01 이후판)
- `tables/sigungu.json`, `tables/aliases.json` — 신설
- `pipeline/regions.py` — 신설
- `tests/test_regions.py` — 신설

#### 핵심 작업
1. 행안부 「법정동코드 전체자료」 다운로드(53,388행) → 폐지여부 "존재"이고 코드 뒤 5자리가 `00000`인 행에서 시군구 추출 → `sigungu.json`:
   ```json
   {"41570": {"sido":"경기도","sgg":"김포시","display":"김포시","parent":null},
    "41117": {"sido":"경기도","sgg":"수원시 영통구","display":"수원시","parent":"41110"},
    "36110": {"sido":"세종특별자치시","sgg":"","display":"세종시","parent":null}}
   ```
2. `aliases.json` — **폐지 코드의 명칭 이력**에서 생성. 최소 항목: `"광주광역시"→"전남광주통합특별시"`, `"전라남도"→"전남광주통합특별시"`, `"강원도"→"강원특별자치도"`, `"전라북도"→"전북특별자치도"`. 시군구명은 통합 뒤에도 그대로다(admdongkor README).
3. `resolve(addr: str) -> list[str]`:
   - 시도 토큰 정규화(별칭 적용) → 시군구 토큰 매칭 → 일반구까지 있으면 그 코드 1개
   - 세종: 시도가 세종이면 무조건 `["36110"]`
   - 모시만 있고 구가 빠졌으면(`parent` 역조회) **산하 구 전부** 반환 (사용자 확정)
   - 매칭 실패 → `[]` + `unresolved.log`에 원문
4. 회귀 테스트 (기획서 그대로, 4번은 확정값 반영):
   ```python
   @pytest.mark.parametrize("addr,expected", [
     ("세종특별자치시 조치원읍 …", ["36110"]),
     ("제주특별자치도 서귀포시 …", ["50130"]),
     ("경기도 수원시 영통구 …",   ["41117"]),
     ("경기도 수원시 …",          ["41111","41113","41115","41117"]),
     ("광주광역시 동구 …",        ["12110"]),   # ★ 별칭. 실제 코드는 sigungu.json에서 확인 후 고정
   ])
   ```
   5번의 기대 코드는 **원본 자료에서 확인한 값**을 쓴다 — 조사에서 나온 예: 전남광주통합특별시 동구 `sgg = 12210`(admdongkor `adm_cd2` 기준). 법정동코드와 admdongkor `sgg`가 같은 값인지 M2에서 대조하고, 다르면 오픈 이슈 #4로 넘긴다.

#### 완료 기준
- `pytest tests/test_regions.py` 5개 통과, `test.yml`에서도 함께 돈다
- `sigungu.json` 항목 수가 행안부 자료의 시군구(+일반구) 수와 일치 (스크립트가 개수 출력, README에 기록)
- 광주·전남 구코드(29·46) 문자열이 `sigungu.json`에 **하나도 없음** (`grep -c '"29' sigungu.json` = 0)

#### 회귀 가드레일 — 깨지면 안 되는 것
- 없음 (신규 파일만)

---

### M3 — 수집기 + 정규화 + 출력 JSON

#### 목표
`python -m pipeline.collect`를 한 번 돌리면 `data/jobs/*.json`과 `index.json`이 공통 스키마로 생성되고, 스키마 테스트가 통과한다.

#### 산출물
- `pipeline/normalize.py`, `pipeline/collect.py` — 신설
- `tests/test_normalize.py`, `tests/test_schema.py` — 신설
- `data/index.json`, `data/jobs/*.json` — 신설 (첫 수집 결과 커밋)

#### 핵심 작업
1. `normalize(list_item, info) -> dict` 매핑:
   | 스키마 | Senuri |
   |---|---|
   | `id` | `"senuri:" + jobId` |
   | `title` | `wantedTitle` (없으면 `recrtTitle`) |
   | `place` | `workPlcNm` (없으면 주소의 "시군구 읍면동") |
   | `address` | `plDetAddr` |
   | `phone` | `clerkContt`를 정규화(숫자·하이픈만 남기고, 빈 값은 `null`) |
   | `org` | `plbizNm` 또는 `oranNm` |
   | `description` | `detCnts` (+ `etcItm` 있으면 줄바꿈 후 이어붙임) |
   | `age` | `age` (없으면 `ageLim`) |
   | `applyStart`/`applyEnd` | `frAcptDd`/`toAcptDd` YYYYMMDD→ISO |
   | `source`/`sourceUrl` | `"senuri"` / `null` |
2. 마감 필터: `deadline == "마감"` or `toDd < today` 제외 (기획서 R5).
3. 지역 복제: `resolve()`가 코드를 여러 개 주면 해당 파일에 모두 기록한다. 실패(`[]`)한 건은 `data/unresolved.json`에 모으고 **그 비율을 index에 남긴다**(`unresolvedRate`).
4. 출력: `data/jobs/{code}.json`은 `title` 가나다순으로 정렬하고, 파일이 없던 지역은 새로 만든다. 0건이어도 `items: []`로 **파일은 남긴다** — 앱이 404와 "정말 0건"을 구분해야 하기 때문이다.
5. `test_schema.py`: 모든 출력 파일이 필수 키를 갖고 `type == "job"`, `schemaVersion == 1`, `phone`이 `null` 또는 `^\d{2,4}-\d{3,4}-\d{4}$`.

#### 완료 기준
- 로컬 실행 1회 → `data/jobs/41570.json` 생성, 건수가 M1 김포 건수와 ±10% 이내
- `pytest` 전체 통과 (regions 5 + normalize ≥ 4 + schema ≥ 3)
- `index.json.unresolvedRate` 기록 — **5%를 넘으면 오픈 이슈 #3 재검토**(juso.go.kr 도입)

#### 회귀 가드레일 — 깨지면 안 되는 것
- `test_regions.py` 5개 통과 (collect가 regions를 우회하지 않음)

---

### M4 — GitHub Actions 일 1회 수집 + 실패 알림

#### 목표
사람 손 없이 매일 03:00 KST에 수집이 돌고, 바뀐 것만 커밋되며, 실패하면 알림이 온다.

#### 산출물
- `.github/workflows/collect.yml` — 신설
- `README.md` — 신설 (수동 실행법, 실패 시 대처)

#### 핵심 작업
1. `collect.yml`:
   ```yaml
   on: { schedule: [{cron: '0 18 * * *'}], workflow_dispatch: {} }
   permissions: { contents: write }
   jobs: collect:
     steps:
       - uses: actions/checkout@v4
       - uses: actions/setup-python@v5  # 3.12
       - run: pip install -e . && python -m pipeline.collect
         env: { DATA_GO_KR_KEY: ${{ secrets.DATA_GO_KR_KEY }} }
       - run: |
           git config user.name  "data-bot"; git config user.email "bot@users.noreply.github.com"
           git add data && git diff --cached --quiet || git commit -m "data: $(date -u +%F)" && git push
   ```
2. 실패 알림: 워크플로 실패 시 GitHub 기본 이메일(저장소 소유자에게 자동) + `index.json`의 `generatedAt`이 **48시간 이상 오래되면 앱이 "정보가 오래됐어요" 배너**(P2 M5).
3. 시군구별 0건 감시(기획서 R2): 전날과 비교해 **어느 시도 전체가 0건이 되면** 커밋하지 않고 실패로 처리한다 — 광주·전남이 소리 없이 비는 상황을 막는다.

#### 완료 기준
- `workflow_dispatch` 수동 실행 → 초록불 + `data/` 커밋 1건
- 다음날 cron 자동 실행 커밋 확인 (2일 연속)
- 인증키를 일부러 틀리게 넣고 실행 → 실패 + 이메일 수신, `data/` 커밋 없음

#### 회귀 가드레일 — 깨지면 안 되는 것
- `test.yml` 여전히 초록 (collect.yml이 test를 대체하지 않음)

---

### M5 — 앱 연결: RemoteItemRepository + 캐시 + 폴백

#### 목표
P1 앱이 김포시 **실제 일자리**를 보여주고, 비행기 모드에서도 마지막 캐시로 동작하며, 홈 상단에 "8월 28일 기준"이 뜬다.

#### 산출물
- `lib/data/remote_item_repository.dart`, `lib/data/feed_cache.dart` — 신설
- `lib/app.dart` — 수정 (`ItemRepository` 주입 지점을 Remote로)
- `lib/screens/home_screen.dart` — 수정 (기준일 캡션, 오래됨/실패 배너)
- `test/data/remote_item_repository_test.dart`, `feed_cache_test.dart` — 신설

#### 핵심 작업
1. `flutter pub add http path_provider`.
2. Remote:
   ```dart
   Future<RegionFeed> fetchItems(String code) async {
     final etag = await cache.etag(code);
     final res = await http.get(uri(code), headers: {
       if (etag != null) 'If-None-Match': etag,
       'Authorization': 'token $readToken',            // 🔵 오픈 이슈 #2
     }).timeout(const Duration(seconds: 8));
     if (res.statusCode == 304) return cache.read(code)!;
     if (res.statusCode == 200) {
       final body = utf8.decode(res.bodyBytes);          // res.body 금지
       await cache.write(code, body, res.headers['etag']);
       return RegionFeed.fromJson(jsonDecode(body));
     }
     throw FeedException(res.statusCode);
   }
   ```
3. 스플래시에서 실패했을 때: 캐시가 있으면 캐시로 홈에 들어가고 `PersistentNotice("새 정보를 못 받았어요. ○월 ○일 정보예요")`를 띄운다. 캐시도 없으면 스플래시에 `BigButton("다시 시도")`를 보여준다.
4. `generatedAt`이 48h를 넘으면 홈에 "정보가 오래됐어요" 배너를 띄운다.
5. 테스트는 `http.Client`를 주입하고 `MockClient`로 200/304/500 상황을 만든다.

#### 완료 기준
- `remote_item_repository_test.dart`: 200→파싱·캐시 저장, 304→캐시 반환, 500+캐시 있음→캐시, 500+캐시 없음→예외 — 4개 통과
- 에뮬레이터: 김포시 실데이터 카드 표시 → 상세 → 다이얼러에 **실제 담당자 번호**
- 비행기 모드로 다시 실행 → 캐시로 홈 진입 + 배너
- P1 테스트 전부 통과 (`MockItemRepository`는 테스트에서 계속 사용)

#### 회귀 가드레일 — 깨지면 안 되는 것
- P1 `home_screen_test.dart`·`detail_screen_test.dart` 통과 — 리포지토리를 갈아끼운다고 화면 코드가 바뀌면 안 된다

---

## 4. 의존성 그래프 · 병렬화 지점

```
M0 ─→ M1 ─┬→ M3 ─→ M4
          │   ↑
          └→ M2 ┘            M5는 M3 출력(첫 커밋)만 있으면 착수 가능, M4와 병렬
```

- **M2(코드 테이블)는 M1과 병렬** — 행안부 자료는 API와 상관이 없다.
- **M5(앱)는 M4(자동화)와 병렬** — 앱은 `data/jobs/41570.json`이 한 번이라도 커밋돼 있으면 된다.
- 권장: **M1을 P1 M3보다 앞으로 당겨 실행** — 김포가 0건이면 P1 이후 작업 순서가 바뀐다(P1 §9).

---

## 5. 위험 요소와 완화책

| 위험 | 확률 | 영향 | 완화책 |
|---|---|---|---|
| 상세 호출 수가 하루 10,000건을 넘김 (전국 살아있는 공고 > ~9,000) | 중 | M3·M4 | M1에서 산정한다. 넘치면 전날 `index`와 비교해 **바뀐 jobId만** 상세를 다시 부르고, 신규 건만 호출한다 |
| `plDetAddr` 채움률이 낮아 지역 판정 실패율이 5%를 넘김 🔶 | 중 | M3 | M1에서 실측한다. 높으면 `workPlcNm`을 우선 쓰고 juso.go.kr 1회성 매핑(기획서 원안)으로 물러난다 — 오픈 이슈 #3 |
| private raw URL을 쓰려다 앱에 토큰을 심는 구조가 됨 🔵 | 높 | M5 | 오픈 이슈 #2. 대안: `data/`만 **GitHub Pages(public)** 로 배포하는 별도 public 저장소에 push하고 코드는 private로 남긴다 |
| 법정동코드와 admdongkor `sgg`가 광주·전남에서 어긋남 | 중 | M2·P3 | admdongkor README도 "앞 2자리만 바꿔서는 매칭되지 않는 시군구가 있다"고 경고한다. M2에서 두 표를 대조해 차이를 `aliases.json`에 흡수한다 |
| Actions cron이 UTC 기준이라 실행이 밀림 | 저 | 데이터 신선도 | 앱 배너 기준을 48h로 넉넉히 잡는다 |

---

## 6. 신규 파일 목록 (전체)

```
still-young-days-data/
  pyproject.toml · README.md · .gitignore
  .github/workflows/test.yml · collect.yml
  pipeline/__init__.py · senuri_client.py · probe.py · regions.py · normalize.py · collect.py · notify.py(빈 파일)
  tables/sigungu.json · aliases.json · raw/법정동코드_전체자료.txt
  data/index.json · data/jobs/*.json · data/unresolved.json
  probe/2026-08-XX-senuri-probe.csv
  tests/__init__.py · test_regions.py · test_normalize.py · test_schema.py · fixtures/joblist_page1.xml · fixtures/jobinfo_sample.xml
still-young-days-app/
  lib/data/remote_item_repository.dart · feed_cache.dart
  test/data/remote_item_repository_test.dart · feed_cache_test.dart
```

---

## 7. 완료 체크리스트

- [ ] M0: 인증키로 `resultCode 0000` 확인, `test.yml` 초록
- [ ] M1: 실측 CSV 3행 + 일 호출 수 판정 + **김포 건수 기록**
- [ ] M2: 회귀 테스트 5개 CI 고정, 29·46 코드 0건
- [ ] M3: `data/jobs/41570.json` 생성, 스키마 테스트 통과, unresolvedRate ≤ 5%
- [ ] M4: cron 2일 연속 자동 커밋 + 실패 알림 실증
- [ ] M5: 실데이터 카드 → 실제 담당자 번호 다이얼러, 비행기 모드 캐시 동작
- [ ] 전체: **어머님 폰(Android 실기기)에서 김포시 실제 일자리를 보고 전화 버튼까지 완주**

---

## 8. 오픈 이슈

| # | 태그 | 내용 | 채택한 기본값 | 다르게 정해지면 | 언제까지 |
|---|---|---|---|---|---|
| 1 | 🔶 가정 | HTTP 라이브러리 | `httpx` | `requests`로 바꿔도 손볼 곳은 `senuri_client.py`뿐 | M0 |
| 2 | 🔵 오픈 질문 | **앱이 private 저장소 JSON을 어떻게 읽을 것인가** — raw URL은 토큰이 필요하고, 앱에 토큰을 심으면 유출 위험 | — | 유력안: 출력 `data/`만 별도 **public 저장소나 GitHub Pages**로 push하고 코드는 private로 둔다. 이게 정해지기 전에는 M5를 시작할 수 없다 | M5 전 |
| 3 | 🔶 가정 | 주소 정규화에 juso.go.kr은 필요 없다 | 문자열 매칭 + 별칭 | M3 unresolvedRate가 5%를 넘으면 기획서 원안(juso 1회성 매핑 테이블)을 추가 | M3 |
| 4 | 🔵 오픈 질문 | 법정동 시군구 코드 ≟ admdongkor `sgg` (특히 12xx 광주·전남) | — | 어긋나면 `aliases.json`에 코드 매핑을 추가한다. P3 GPS 판정도 이 표를 쓴다 | M2 |
| 5 | 🔵 오픈 질문 | Senuri 갱신 주기·전체 건수·김포 건수 (기획서 🔵) | — | M1에서 답이 나온다. 김포가 0건이면 기획 재검토(R3) | M1 |
| 6 | 🔶 가정 | 상세를 동시 4·간격 0.25s로 불러도 차단당하지 않는다 | 위 값 | 429나 차단이 나오면 동시 1·간격 1s로 물러난다 (24h 안에만 끝나면 된다) | M3 |

---

## 9. 자체 점검

- **가장 불확실한 마일스톤**: **M5** — 🔵#2(private 데이터 접근)가 풀리지 않으면 앱이 읽을 URL 자체가 없다. M0에서 같이 결정해야 한다. 추천안은 "코드는 private, `data/`는 public Pages"로 나누는 것이다.
- **틀리면 계획이 무너지는 가정**: ① 🔵#5 김포 건수 — 0이면 P2 이후 순서가 통째로 바뀐다 → **M1을 가장 먼저, P1과 나란히**. ② 🔶#3 주소 문자열 매칭 — M3 unresolvedRate에서 바로 드러난다. ③ 🔵#4 코드 체계 불일치 — M2에서 두 표를 한 번 대조하면 확인된다.
- **지금 당장 뗄 첫걸음**: data.go.kr 로그인 → 15015153 활용신청 → `curl`로 `resultCode 0000` 확인.
