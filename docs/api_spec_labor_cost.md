# 인건비 API 스펙

기본 prefix: `/api/v1`

Figma: [`개인 공간`](https://www.figma.com/design/unoGN3istoEgvyJKbfuICS/%EA%B0%9C%EC%9D%B8-%EA%B3%B5%EA%B0%84) — 아래 노드는 **인건비** 상단 탭(예상 인건비 / 월별 인건비 / 인건비 절감 상세)과 동일 플로우입니다.

## Figma 노드 ↔ 화면 ↔ API

| 노드 ID | 프레임(또는 컴포넌트) | 앱에서 사용할 API |
|---------|------------------------|-------------------|
| `2534:11446` | 이번달 예상 인건비 — **이번달** 구간·탭「예상 인건비」 | `GET /labor-cost/branches/{branch_id}/expected?range_type=this_month` |
| `2534:12883` | 이번달 예상 인건비 — 동일 탭 변형(레이아웃/디바이스 등) | 위와 동일 |
| `2534:12751` | 이번달 예상 인건비 — 드롭다운 **6개월**·월별 추이 차트 | `GET /labor-cost/branches/{branch_id}/expected?range_type=six_months` → `monthly_trend` 사용 |
| `2534:12453` | **Native / Status Bar** (시계·배터리 등 OS 크롬) | API 없음 · Flutter `SystemChrome` / `SafeArea` 등 |
| `2534:12492` | **인건비 절감 상세** — 탭「인건비 절감 상세」·표·아코디언 | `GET /labor-cost/branches/{branch_id}/saving-detail?year=&month=` |

상단 탭 **「월별 인건비」** (위 표에 단독 프레임은 없음): `GET /labor-cost/branches/{branch_id}/monthly-detail?year=&month=`

### 화면 필드 매핑 요약

- **예상 인건비 카드** (총액·전월 대비 %·총 근로자 수): `current_total_cost`, `previous_total_cost`, `change_rate_percent`, `headcount_current`, `headcount_previous`
- **인건비** 소계 막대(총급여·주휴·기타): `component_comparisons[]` (`총급여` = 급여명세 `base_pay` 합, `주휴수당`, `기타수당` = `overtime_pay` 합)
- **6개월 추이**: `monthly_trend[]` (막대/축 레이블은 클라이언트가 `month`, `total_cost`, `headcount` 등으로 구성)
- **절감 포인트** 카드·「상세보기»: 카드는 `saving_points[]`; 상세 화면은 `saving-detail` 전체
- 금액 단위: API는 **원(정수)**. Figma `(천원)` 표기는 표시 시 ÷1000 등 클라이언트 포맷

---

## 인증/권한

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- 경영주(owner): 본인 소유 점포만 접근 가능
- 점장(manager): 본인이 배정된 점포만 접근 가능

---

## 1) 예상 인건비 조회 (이번달 / 6개월 필터)

- `GET /labor-cost/branches/{branch_id}/expected?range_type=this_month`
- `GET /labor-cost/branches/{branch_id}/expected?range_type=six_months`
- `range_type`:
  - `this_month` (`current_month`도 허용): 이번달 vs 전월 비교
  - `six_months`: 최근 6개월 추이

### Request Body
없음

### Response Body (200)
```json
{
  "branch_id": 1, // 점포 ID
  "range_type": "this_month", // this_month(current_month 입력 시 this_month로 정규화) | six_months
  "period_label": "이번달", // 화면 표시용 라벨
  "current_total_cost": 9157430, // 현재 기간 총 인건비(원)
  "previous_total_cost": 8290000, // 비교 기준 기간 총 인건비(원)
  "change_rate_percent": 10.5, // 증감률(%)
  "headcount_previous": 28, // 비교 기준 기간 인원수
  "headcount_current": 21, // 현재 기간 인원수
  "component_comparisons": [
    {
      "component_name": "총급여", // 항목명
      "previous_amount": 5000000, // 이전 금액
      "current_amount": 6200000 // 현재 금액
    },
    {
      "component_name": "주휴수당",
      "previous_amount": 1800000,
      "current_amount": 2000000
    },
    {
      "component_name": "기타수당",
      "previous_amount": 1490000,
      "current_amount": 957430
    }
  ],
  "monthly_trend": [], // six_months일 때만 6개 데이터
  "saving_points": [
    {
      "title": "퇴직 리스크 점검", // 절감 포인트 제목
      "description": "3개월 내 퇴직 인원이 1명 있습니다. 조기 이탈 방지 정책을 점검해보세요." // 절감 포인트 설명
    }
  ]
}
```

### `range_type=six_months`일 때 `monthly_trend` 예시
```json
[
  {
    "month": "2026-01", // YYYY-MM
    "base_pay": 4200000, // 기본급
    "allowance_pay": 3900000, // 수당(주휴+기타)
    "total_cost": 8100000, // 총 인건비
    "headcount": 28 // 해당 월 인원수
  },
  {
    "month": "2026-02",
    "base_pay": 4700000,
    "allowance_pay": 4200000,
    "total_cost": 8900000,
    "headcount": 26
  }
]
```

---

## 2) 월별 인건비 직원 상세 조회 (월급/시급 포함)

- `GET /labor-cost/branches/{branch_id}/monthly-detail?year=2025&month=9`
- 월별 인건비를 직원별로 조회
- 직원별 `wage_type` / `wage_type_label`로 월급/시급/일급 구분 확인 가능

### Request Body
없음

### Response Body (200)
```json
{
  "branch_id": 1, // 점포 ID
  "year": 2025, // 조회 연도
  "month": 9, // 조회 월
  "period_label": "2025.09", // 화면 표시 라벨
  "business_days": 30, // 영업 일수
  "total_employee_count": 10, // 해당 월 급여 데이터가 있는 직원 수
  "total_work_minutes": 7250, // 총 근무 분
  "total_cost": 8525580, // 월 총 인건비
  "previous_total_cost": 4200000, // 전월 총 인건비
  "change_rate_percent": 103.0, // 전월 대비 증감률(%)
  "component_summaries": [ // 하단 요약용 수당 내역 등
    {
      "component_name": "주휴",
      "amount": 650760
    }
  ],
  "employees": [
    {
      "employee_id": 501, // 직원 ID
      "employee_name": "이사라", // 직원명
      "wage_type": "hourly", // monthly | hourly | daily | unknown
      "wage_type_label": "시급", // 화면 표시용
      "wage_amount": 9860, // 계약서 기준 급여 단가
      "total_work_minutes": 725, // 월 누적 근무 분
      "total_work_hours": 12.1, // 월 누적 근무 시간
      "contract_weekly_work_minutes": 2400, // 계약한 주 근로 분(예: 40시간). 계약값이 없으면 직원관리 수동 설정값, 둘 다 없으면 null
      "average_weekly_minutes": 960, // 주 평균 근로 분
      "base_pay": 8525580, // 총급여(기본)
      "weekly_allowance": 650760, // 주휴수당
      "overtime_pay": 0, // 기타수당/연장수당
      "total_cost": 9176340 // 직원 월 총 인건비(총급여 기준)
    }
  ]
}
```

설명:

- `wage_type`은 직원의 최신 근로계약(`standard_v1`/`minor_standard_v1`)의 `wage_type` 기준
- 해당 정보가 없으면 `unknown`/`미설정`
- `total_work_minutes`는 해당 월의 누적 총 근무시간입니다.
- `contract_weekly_work_minutes`는 화면의 `주 근로` 표시용으로, 최신 근로계약의 소정근로 시작/종료 시각과 `work_days_per_week`로 계산한 계약 주 근로시간입니다. 계약값이 없으면 직원관리의 수동 주 근로 설정값을 사용하고, 둘 다 없으면 `null`입니다.
- `average_weekly_minutes`는 월별 근무 스케줄/급여 기준의 평균 주 근로시간이며 계약 주 근로시간과 다를 수 있습니다.

---

## 3) 인건비 절감 상세 조회

- `GET /labor-cost/branches/{branch_id}/saving-detail?year=2025&month=9`
- 아래 3개 블록을 한 번에 조회
  - 퇴직금 발생 예정 인원
  - 주휴수당 개선안(여러 개 Point)
  - 중복 근무 발생 현황
- 주휴 개선안 Point마다 `after_workers`에 `"employee_name": "신규채용"` 행이 붙는 경우, 초과 주간 근로를 신규 인력에 넘겨 주휴 부담을 줄이는 안을 제시하는 것으로 보며 이때 `recommends_new_hire`는 `true`, `new_hire_weekly_minutes`는 **신규 채용 인력 전체에 분배하는 주간 분 합계**입니다.
- 분배 추천은 **60분 단위**로 계산합니다.
- 필요 시 `after_workers`에는 `"신규채용"` 행이 여러 개 내려올 수 있습니다. 각 행은 `60분 단위`이며, 주휴 기준(주 15시간 미만) 이하로 분배된 개별 제안 단위입니다.
- 신규채용 행 1개당 최소 추천 근무시간은 `180분`(3시간)입니다.
- 초과 분배가 없으면 `recommends_new_hire`는 `false`이고 나머지 두 필드는 `null`입니다.

### Request Body
없음

### Response Body (200)
```json
{
  "branch_id": 1, // 점포 ID
  "year": 2025, // 조회 연도
  "month": 9, // 조회 월
  "retirement_expected_workers": [
    {
      "employee_id": 501, // 직원 ID
      "employee_name": "이사라", // 직원명
      "hire_date": "2024-10-10", // 입사일
      "severance_eligible_date": "2025-10-10", // 퇴직금 발생 기준 도달 예정일
      "average_weekly_minutes_recent_4weeks": 980, // 최근 4주 평균 주 근로분
      "legal_weekly_hours_condition_met": true // 주15시간(900분) 이상 충족 여부
    }
  ],
  "weekly_allowance_improvement_points": [
    {
      "point_title": "Point 1", // 개선안 제목
      "legal_basis": "출결 확정 기준으로 개근 + 주 소정근로시간 15시간 이상(900분) 충족 여부를 우선 적용", // 한국 기준 안내
      "recommends_new_hire": true, // 주휴 부담 완화를 위해 초과 시간을 신규 인력에 넘기는 안을 권하는지
      "new_hire_weekly_minutes": 180, // 신규 채용 인력 전체에 분배하는 주간 근무(분) 합계. 없으면 null
      "recommendation_note": "주휴수당 부담을 줄이기 위해 초과 주간 근로시간은 신규 단기·알바 채용으로 분배하는 방안을 검토할 수 있습니다.", // 미권장 시 null
      "before_workers": [
        {
          "employee_name": "이사라", // 기존 인력
          "category": "현주휴인력", // 구분
          "weekly_work_minutes": 960 // 주 근로시간(분)
        }
      ],
      "after_workers": [
        {
          "employee_name": "이사라",
          "category": "개선안",
          "weekly_work_minutes": 780
        },
        {
          "employee_name": "신규채용",
          "category": "개선안",
          "weekly_work_minutes": 180
        }
      ]
    },
    {
      "point_title": "Point 2",
      "legal_basis": "출결 확정 기준으로 개근 + 주 소정근로시간 15시간 이상(900분) 충족 여부를 우선 적용",
      "recommends_new_hire": true,
      "new_hire_weekly_minutes": 960,
      "recommendation_note": "주휴수당 부담을 줄이기 위해 초과 주간 근로시간은 신규 단기·알바 채용으로 분배하는 방안을 검토할 수 있습니다.",
      "before_workers": [
        {
          "employee_name": "홍승민",
          "category": "현주휴인력",
          "weekly_work_minutes": 1800
        }
      ],
      "after_workers": [
        {
          "employee_name": "홍승민",
          "category": "개선안",
          "weekly_work_minutes": 840
        },
        {
          "employee_name": "신규채용",
          "category": "개선안",
          "weekly_work_minutes": 480
        },
        {
          "employee_name": "신규채용",
          "category": "개선안",
          "weekly_work_minutes": 480
        }
      ]
    }
  ],
  "overlapping_work_issues": [
    {
      "work_date": "2025-02-12", // 중복 근무 발생일
      "employee_names": ["홍승민", "이사라"], // 중복 근무 직원 목록
      "overlap_time_range": "17:00-19:00", // 중복 시간대
      "schedule_id_pair": [1201, 1202] // 충돌 스케줄 ID 쌍
    }
  ]
}
```

---

## 한국 기준 반영 규칙(현재 API)

- 퇴직금 발생 예정 인원: `입사 1년 도달 예정` + `최근 4주 평균 주15시간(900분) 이상`인 인원
- 주휴수당 산정: **계약 주 근로시간 15시간(900분) 이상** + **계약한 근로일 만근** 조건을 모두 충족한 주만 산정합니다. 결근(`absent`) 또는 미확정 상태가 있으면 해당 주는 0원입니다.
- 주휴수당 산식: `(계약 주 근로시간 / 40시간) × 8시간 × 시급`. 실제 근무시간이 계약시간을 초과해도 산식에는 계약 주 근로시간을 사용합니다.
- 주휴수당 개선안: `출결 확정 데이터가 있는 경우` 해당 확정값의 계약근로일 만근 여부와 계약 주15시간 이상 조건을 우선 적용
- 주휴수당 개선안: `출결 확정 데이터가 없는 경우` 기존 스케줄을 보조 판단하되, 지급액 산정 기준 시간은 실제 주간 합계가 아니라 계약 주 근로시간입니다.
- 주휴수당 개선안: 개선 후 기존 인력은 `60분 단위` 기준으로 주휴 기준 미만 최대치인 `840분(14시간)` 수준까지 우선 조정합니다.
- 주휴수당 개선안: 분배 시간은 `60분 단위`로 계산합니다.
- 주휴수당 개선안: 신규채용 1명당 최소 추천 근무시간은 `180분`입니다.
- 주휴수당 개선안: 초과분은 필요 시 여러 `신규채용` 행으로 분배합니다.
- 중복 근무 발생 현황:
  - **서로 다른 두 직원**이 같은 날짜에 근무 시간대가 겹치면 `employee_names`에 두 명(이름 정렬)
  - **동일 직원**에게 같은 날 두 건 이상의 스케줄이 시간으로 겹치면 `employee_names`에 한 명

---

## 에러 응답

- `400`: `range_type` 값이 잘못된 경우
- `400`: `year`, `month` 값이 잘못된 경우
- `403`: 점포 접근 권한이 없는 경우
- `404`: 점포가 없는 경우
