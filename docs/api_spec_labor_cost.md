# 인건비 API 스펙

기본 prefix: `/api/v1`

## 인증/권한

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- 경영주(owner): 본인 소유 점포만 접근 가능
- 점장(manager): 본인이 배정된 점포만 접근 가능

---

## 1) 예상 인건비 조회 (이번달 / 6개월 필터)

- `GET /labor-cost/branches/{branch_id}/expected?range_type=this_month`
- `GET /labor-cost/branches/{branch_id}/expected?range_type=six_months`
- `range_type`:
  - `this_month`: 이번달 vs 전월 비교
  - `six_months`: 최근 6개월 추이

### Request Body
없음

### Response Body (200)
```json
{
  "branch_id": 1, // 점포 ID
  "range_type": "this_month", // this_month | six_months
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
  "total_employee_count": 10, // 해당 월 급여 데이터가 있는 직원 수
  "total_work_minutes": 7250, // 총 근무 분
  "total_cost": 8525580, // 월 총 인건비
  "employees": [
    {
      "employee_id": 501, // 직원 ID
      "employee_name": "이사라", // 직원명
      "wage_type": "hourly", // monthly | hourly | daily | unknown
      "wage_type_label": "시급", // 화면 표시용
      "wage_amount": 9860, // 계약서 기준 급여 단가
      "total_work_minutes": 725, // 월 누적 근무 분
      "total_work_hours": 12.1, // 월 누적 근무 시간
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

---

## 3) 인건비 절감 상세 조회

- `GET /labor-cost/branches/{branch_id}/saving-detail?year=2025&month=9`
- 아래 3개 블록을 한 번에 조회
  - 퇴직금 발생 예정 인원
  - 주휴수당 개선안(여러 개 Point)
  - 중복 근무 발생 현황

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
          "weekly_work_minutes": 880
        },
        {
          "employee_name": "신규채용",
          "category": "개선안",
          "weekly_work_minutes": 80
        }
      ]
    },
    {
      "point_title": "Point 2",
      "before_workers": [
        {
          "employee_name": "홍승민",
          "category": "현주휴인력",
          "weekly_work_minutes": 930
        }
      ],
      "after_workers": [
        {
          "employee_name": "홍승민",
          "category": "개선안",
          "weekly_work_minutes": 870
        },
        {
          "employee_name": "신규채용",
          "category": "개선안",
          "weekly_work_minutes": 60
        }
      ]
    }
  ],
  "overlapping_work_issues": [
    {
      "work_date": "2025-02-12", // 중복 근무 발생일
      "employee_name": "홍승민", // 중복 근무 직원
      "overlap_time_range": "17:00-19:00", // 중복 시간대
      "schedule_id_pair": [1201, 1202] // 충돌 스케줄 ID 쌍
    }
  ]
}
```

---

## 한국 기준 반영 규칙(현재 API)

- 퇴직금 발생 예정 인원: `입사 1년 도달 예정` + `최근 4주 평균 주15시간(900분) 이상`인 인원
- 주휴수당 개선안: `출결 확정 데이터가 있는 경우` 해당 확정값의 `개근 + 주15시간(900분) 이상` 조건을 우선 적용
- 주휴수당 개선안: `출결 확정 데이터가 없는 경우` 기존 스케줄 기반 평균 주근로시간(15시간 이상)으로 보조 판단

---

## 에러 응답

- `400`: `range_type` 값이 잘못된 경우
- `400`: `year`, `month` 값이 잘못된 경우
- `403`: 점포 접근 권한이 없는 경우
- `404`: 점포가 없는 경우
