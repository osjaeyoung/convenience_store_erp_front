# 직원관리 API 스펙 (근무일정 중심)

기본 prefix: `/api/v1`

> 참고: 아래 JSON 예시는 이해를 돕기 위해 `//` 주석을 포함했습니다.  
> 실제 API 요청/응답 JSON에는 주석 없이 사용해야 합니다.

## 인증/권한

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- 경영주(owner): 본인 소유 점포만 접근 가능
- 점장(manager): 본인이 배정된 점포만 접근 가능

## 목표 범위

- 날짜별 근무일정 조회 (24시간, 30분 단위)
- 주별 근무일정 조회 (7일)
- 날짜별 저장/수정
- 주별 저장/수정
- 특정 슬롯 상태/메모 수정
- 특정 슬롯 삭제

---

## 1) 날짜별 근무일정 조회

- `GET /staff-management/branches/{branch_id}/schedules/day?date=2026-09-11`

### Request Body
없음

### Response Body (200)
```json
{
  "work_date": "2026-09-11", // 조회 대상 날짜(YYYY-MM-DD)
  "slots": [
    {
      "time": "00:00", // 30분 슬롯 시작 시각(HH:MM)
      "employees": [] // 해당 슬롯 배정 직원 목록(없으면 빈 배열)
    },
    {
      "time": "00:30", // 30분 슬롯 시작 시각(HH:MM)
      "employees": [
        {
          "schedule_id": 7001, // 스케줄 엔트리 PK
          "employee_id": 501, // 근무자 PK
          "worker_name": "이사라", // 근무자 이름
          "status": "scheduled", // scheduled|done|absent|unset
          "memo": null // 근무 메모(없으면 null)
        },
        {
          "schedule_id": 7002, // 스케줄 엔트리 PK
          "employee_id": 502, // 근무자 PK
          "worker_name": "김찬우", // 근무자 이름
          "status": "done", // 실제 근무 상태
          "memo": "교대 완료" // 관리자가 남긴 메모
        }
      ]
    }
  ]
}
```

설명:

- 1일 48개 슬롯(00:00 ~ 23:30)을 반환
- 빈 슬롯은 `employees: []`
- 한 슬롯에 여러 직원 배치 가능
- 조회 시 근로계약 룰이 있으면 자동반영 가능

---

## 2) 주별 근무일정 조회

- `GET /staff-management/branches/{branch_id}/schedules/week?week_start_date=2026-09-08`

### Request Body
없음

### Response Body (200)
```json
{
  "week_start_date": "2026-09-08", // 주 시작일(YYYY-MM-DD)
  "days": [
    {
      "work_date": "2026-09-08", // 해당 일자(주 시작일 기준)
      "slots": [
        {
          "time": "09:00", // 30분 슬롯 시작 시각
          "employees": [
            {
              "schedule_id": 7101, // 스케줄 엔트리 PK
              "employee_id": 501, // 근무자 PK
              "worker_name": "이사라", // 근무자 이름
              "status": "scheduled", // 근무 상태
              "memo": null // 메모
            }
          ]
        }
      ]
    }
  ]
}
```

---

## 3) 날짜별 근무일정 저장/수정

- `PUT /staff-management/branches/{branch_id}/schedules/day`
- 해당 날짜의 기존 일정은 입력값으로 전체 교체

### Request Body
```json
{
  "work_date": "2026-09-11", // 저장 대상 날짜
  "slots": [
    {
      "time": "09:00", // 30분 슬롯 시작 시각
      "assignments": [
        {
          "employee_id": 501, // 배정할 근무자 PK
          "status": "scheduled", // scheduled|done|absent|unset
          "memo": null // 슬롯 메모
        },
        {
          "employee_id": 502, // 배정할 근무자 PK
          "status": "done", // 근무 완료 처리
          "memo": "대체근무" // 메모
        }
      ]
    },
    {
      "time": "09:30", // 30분 슬롯 시작 시각
      "assignments": [] // 빈 슬롯 저장
    }
  ]
}
```

### Response Body (200)
```json
{
  "affected_dates": [
    "2026-09-11" // 실제 반영된 날짜 목록
  ],
  "inserted_count": 2 // 새로 저장된 스케줄 개수
}
```

---

## 4) 주별 근무일정 저장/수정

- `PUT /staff-management/branches/{branch_id}/schedules/week`
- 대상 주(7일) 기존 일정은 입력값으로 전체 교체

### Request Body
```json
{
  "week_start_date": "2026-09-08", // 저장 대상 주 시작일
  "days": [
    {
      "weekday": 0, // 0=월, 1=화, ... 6=일
      "slots": [
        {
          "time": "09:00", // 슬롯 시작 시각
          "assignments": [
            {
              "employee_id": 501, // 배정 근무자 PK
              "status": "scheduled", // 근무 상태
              "memo": null // 메모
            }
          ]
        }
      ]
    },
    {
      "weekday": 2, // 수요일
      "slots": [
        {
          "time": "13:00", // 슬롯 시작 시각
          "assignments": [
            {
              "employee_id": 502, // 배정 근무자 PK
              "status": "absent", // 결근 처리
              "memo": "병가" // 메모
            }
          ]
        }
      ]
    }
  ]
}
```

### Response Body (200)
```json
{
  "affected_dates": [
    "2026-09-08", // 주간 반영 날짜(월)
    "2026-09-09", // 화
    "2026-09-10", // 수
    "2026-09-11", // 목
    "2026-09-12", // 금
    "2026-09-13", // 토
    "2026-09-14" // 일
  ],
  "inserted_count": 2 // 주간 저장으로 생성된 스케줄 개수
}
```

---

## 5) 특정 슬롯 상태/메모 수정

- `PATCH /staff-management/branches/{branch_id}/schedules/{schedule_id}`

### Request Body
```json
{
  "status": "done", // 변경할 근무 상태
  "memo": "지각 5분" // 변경할 메모
}
```

### Response Body (200)
```json
{
  "schedule_id": 7001, // 수정된 스케줄 PK
  "status": "done", // 최종 상태
  "memo": "지각 5분", // 최종 메모
  "updated_at": "2026-09-11T10:10:00Z" // 최종 수정 시각(UTC)
}
```

---

## 6) 특정 슬롯 삭제

- `DELETE /staff-management/branches/{branch_id}/schedules/{schedule_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "deleted": true // 삭제 성공 여부
}
```

---

## 상태 값

- `scheduled`: 근무예정
- `done`: 근무완료
- `absent`: 결근
- `unset`: 미정

## 시간/저장 정책

- 시간 포맷은 `HH:MM`
- 30분 단위만 허용 (`00`, `30`)
- 1슬롯에 0명(빈 자리) 또는 N명 배치 가능
- 하루/주 저장은 전체 교체 방식

---

## 7) 현근무자/퇴사자 비교 조회 (점포 한정)

- `GET /staff-management/branches/{branch_id}/employees/compare?q=이사라`
- `q`는 이름/근무자번호/연락처 검색

### Request Body
없음

### Response Body (200)
```json
{
  "active_workers": [
    {
      "employee_id": 501, // 근무자 PK
      "employee_number": "010-00051", // 점포 내 근무자 번호
      "name": "이사라", // 이름
      "phone_number": "01012341234", // 연락처
      "hire_date": "2025-05-12", // 입사일
      "resignation_date": null, // 퇴사일(현근무자는 null)
      "employment_status": "active", // active|retired
      "linked_user_id": 25, // 앱 사용자 계정 연결 ID
      "created_at": "2026-09-11T08:00:00Z", // 등록 시각
      "average_rating": 2.5, // 해당 점포에서 매긴 평점 평균 (리뷰 없으면 null)
      "my_rating": 3 // 현재 사용자(점장/경영주)가 해당 근무자에게 매긴 별점 (없으면 null)
    }
  ],
  "retired_workers": [
    {
      "employee_id": 502, // 근무자 PK
      "employee_number": "010-00052", // 점포 내 근무자 번호
      "name": "김찬우", // 이름
      "phone_number": "01099998888", // 연락처
      "hire_date": "2024-03-02", // 입사일
      "resignation_date": "2026-03-30", // 퇴사일
      "employment_status": "retired", // 퇴사 상태
      "linked_user_id": null, // 연결된 앱 계정 없으면 null
      "created_at": "2026-09-11T08:10:00Z", // 등록 시각
      "average_rating": null, // 리뷰 없음
      "my_rating": null // 평가한 적 없음
    }
  ]
}
```

---

## 8) 근무자 번호로 단건 조회

- `GET /staff-management/branches/{branch_id}/employees/by-number/{employee_number}`

### Request Body
없음

### Response Body (200)
```json
{
  "employee_id": 501, // 근무자 PK
  "employee_number": "010-00051", // 점포 내 근무자 번호
  "name": "이사라", // 이름
  "phone_number": "01012341234", // 연락처
  "hire_date": "2025-05-12", // 입사일
  "resignation_date": null, // 퇴사일
  "employment_status": "active", // active|retired
  "linked_user_id": 25, // 앱 사용자 계정 연결 ID
  "created_at": "2026-09-11T08:00:00Z" // 등록 시각
}
```

---

## 8-1) 앱 가입 사용자 연락처 검색 (근무자 등록용)

- `GET /staff-management/branches/{branch_id}/employees/search-users?phone=01012341234`
- 앱에 가입된 사용자 중 연락처로 검색. 해당 점포에 아직 등록되지 않은 사용자만 반환.
- **점장/경영주 자기 등록**: 자기 번호를 입력하면 본인도 결과에 포함됨 (연락처 형식 차이 `010-1234-5678` vs `01012345678` 등 대응).

### Request Body
없음

### Response Body (200)
```json
{
  "users": [
    {
      "user_id": 25,
      "name": "이사라",
      "phone_number": "01012341234"
    }
  ]
}
```

- 검색 결과 없으면 `users: []`

---

## 9) 점장/경영주 자기 자신 근무자로 등록

- `POST /staff-management/branches/{branch_id}/employees/register-self`

### Request Body
```json
{
  "name": "이사라", // 등록할 이름(미입력 시 사용자 프로필 이름 사용)
  "phone_number": "01012341234", // 등록할 연락처(미입력 시 프로필 연락처 사용)
  "hire_date": "2025-05-12" // 입사일
}
```

### Response Body (200)
```json
{
  "employee_id": 501, // 생성된 근무자 PK
  "employee_number": "010-00051", // 자동 생성된 근무자 번호
  "name": "이사라", // 이름
  "phone_number": "01012341234", // 연락처
  "hire_date": "2025-05-12", // 입사일
  "resignation_date": null, // 퇴사일
  "employment_status": "active", // 자기등록은 기본 active
  "linked_user_id": 25, // 현재 로그인 사용자 ID와 자동 연결
  "created_at": "2026-09-11T08:00:00Z" // 생성 시각
}
```

---

## 9-1) 앱 사용자를 근무자로 등록 (연락처 검색 결과 기반)

- `POST /staff-management/branches/{branch_id}/employees/from-user`
- 앱 가입 사용자를 해당 점포 근무자로 등록 (search-users 검색 결과의 user_id 사용)

### Request Body
```json
{
  "user_id": 25,
  "hire_date": "2025-05-12"
}
```

### Response Body (200)
```json
{
  "employee_id": 501,
  "employee_number": "010-00051",
  "name": "이사라",
  "phone_number": "01012341234",
  "hire_date": "2025-05-12",
  "resignation_date": null,
  "employment_status": "active",
  "linked_user_id": 25,
  "created_at": "2026-09-11T08:00:00Z"
}
```

---

## 10) 근무자 상세 조회 (직원정보 화면)

- `GET /staff-management/branches/{branch_id}/employees/{employee_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "branch_name": "나눔 강남 테스트점", // 근무지(점포) 명
  "employee": {
    "employee_id": 501, // 근무자 PK
    "employee_number": "010-00051", // 점포 내 근무자 번호
    "name": "이사라", // 이름
    "phone_number": "01012341234", // 연락처
    "hire_date": "2025-05-12", // 입사일
    "resignation_date": null, // 퇴사일
    "employment_status": "active", // active|retired
    "linked_user_id": 25, // 연결 사용자 ID
    "created_at": "2026-09-11T08:00:00Z" // 등록 시각
  },
  "labor_contracts": [
    {
      "rule_id": 1, // 근로계약 근무룰 PK
      "employee_id": 501, // 대상 근무자 PK
      "weekday": 1, // 0=월, ... 6=일
      "start_time": "09:00", // 시작 시각
      "end_time": "18:00", // 종료 시각
      "is_active": true // 룰 활성 여부
    }
  ],
  "work_histories": [
    {
      "schedule_id": 7001, // 근무이력(스케줄) PK
      "employee_id": 501, // 근무자 PK
      "worker_name": "이사라", // 근무자 이름
      "start_time": "09:00", // 시작 시각
      "end_time": "09:30", // 종료 시각
      "status": "done", // 근무 상태
      "memo": "정상근무", // 근무 메모
      "schedule_source": "manual_daily_slot", // 생성 출처
      "updated_at": "2026-09-11T10:10:00Z" // 마지막 수정 시각
    }
  ],
  "payroll_statements": [], // 급여명세 목록
  "hr_records": [], // 인사자료 목록
  "etc_records": [], // 기타자료 목록
  "reviews": [
    {
      "review_id": 31, // 리뷰 PK
      "rating": 3, // 1~3점
      "comment": "우수사원", // 리뷰 코멘트
      "author_user_id": 2, // 작성자 사용자 ID
      "author_name": "점장 홍길동", // 작성자 이름
      "created_at": "2026-09-11T12:00:00Z" // 작성 시각
    }
  ]
}
```

카테고리 매핑:

1. 인적사항: `employee`
2. 근로계약: `labor_contracts`
3. 근무이력: `work_histories`
4. 급여명세: `payroll_statements`
5. 인사자료: `hr_records`
6. 기타자료: `etc_records`

---

## 11) 근무자 인적사항 수정 (입사일/퇴사일 포함)

- `PATCH /staff-management/branches/{branch_id}/employees/{employee_id}`

### Request Body
```json
{
  "name": "이사라", // 수정할 이름
  "phone_number": "01012341234", // 수정할 연락처
  "hire_date": "2025-05-12", // 수정할 입사일
  "resignation_date": "2026-03-30", // 수정할 퇴사일
  "employment_status": "retired" // active|retired
}
```

### Response Body (200)
```json
{
  "employee_id": 501, // 근무자 PK
  "employee_number": "010-00051", // 점포 내 근무자 번호
  "name": "이사라", // 이름
  "phone_number": "01012341234", // 연락처
  "hire_date": "2025-05-12", // 입사일
  "resignation_date": "2026-03-30", // 퇴사일
  "employment_status": "retired", // 변경된 재직 상태
  "linked_user_id": 25, // 연결 사용자 ID
  "created_at": "2026-09-11T08:00:00Z" // 최초 등록 시각
}
```

---

## 12) 리뷰 등록 (점장/경영주 입력 가능)

- `POST /staff-management/branches/{branch_id}/employees/{employee_id}/reviews`

### Request Body
```json
{
  "rating": 3, // 1~3점
  "comment": "책임감 있고 응대가 우수함" // 평가 코멘트
}
```

### Response Body (200)
```json
{
  "review_id": 31, // 리뷰 PK
  "rating": 3, // 평가 점수
  "comment": "책임감 있고 응대가 우수함", // 코멘트
  "author_user_id": 2, // 작성자 사용자 ID
  "author_name": "점장 홍길동", // 작성자 이름
  "created_at": "2026-09-11T12:00:00Z" // 작성 시각
}
```

---

## 13) 리뷰 삭제

- `DELETE /staff-management/branches/{branch_id}/employees/{employee_id}/reviews/{review_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "deleted": true // 삭제 성공 여부
}
```

---

## 14) 급여명세 자동 채우기 (작성 화면 초기값)

- `GET /staff-management/branches/{branch_id}/employees/{employee_id}/payroll-auto-fill?year=2025&month=12`
- 근무자+연월 기준으로 **총근무시간, 시급, 기본급, 주휴수당** 자동 산출 (프론트에서 계산하지 않고 백엔드에서 반환)
- 사용자는 저장 전 수정 가능

### Request Body
없음 (쿼리: `year`, `month`)

### Response Body (200)
```json
{
  "total_work_minutes": 8400, // 해당월 총 근무시간(분) - 근무일정 기준
  "hourly_wage": 9860, // 시급(원) - 근로계약 또는 이전 급여명세 기준
  "base_pay": 1380400, // 기본급 (총근무시간×시급)
  "weekly_allowance": 206400, // 주휴수당(원) - 주 15시간 이상인 주만 산정
  "resident_id_masked": null,
  "overtime_pay": 0,
  "taxable_salary": null,
  "gross_salary": null
}
```

- 이 값을 calculate 또는 저장 API 요청 body에 넣어 사용. 공제·실지급액은 백엔드에서 계산.

---

## 15) 급여명세 미리계산 (저장 안함)

- `POST /staff-management/branches/{branch_id}/employees/{employee_id}/payroll-statements/calculate`
- 공제항목을 공식대로 계산만 해서 미리보기

### Request Body
```json
{
  "year": 2025, // 급여 연도
  "month": 12, // 급여 월(1~12)
  "resident_id_masked": "992222-1******", // 주민번호 마스킹 값
  "total_work_minutes": 8400, // 총 근무시간(분)
  "hourly_wage": 9860, // 시급(원)
  "weekly_allowance": 206400, // 주휴수당(원)
  "overtime_pay": 0, // 연장/야간/휴일 수당(원)
  "taxable_salary": null, // 과세급여 직접입력(없으면 자동계산)
  "gross_salary": null // 총급여 직접입력(없으면 자동계산)
}
```

### Response Body (200)
```json
{
  "payroll_id": 0, // 계산 전용 응답(미저장)
  "year": 2025, // 급여 연도
  "month": 12, // 급여 월
  "resident_id_masked": "992222-1******", // 주민번호 마스킹 값
  "total_work_minutes": 8400, // 총 근무시간(분)
  "hourly_wage": 9860, // 시급
  "base_pay": 1380400, // 기본급(총근무시간*시급)
  "weekly_allowance": 206400, // 주휴수당
  "overtime_pay": 0, // 연장수당
  "taxable_salary": 1586800, // 과세급여
  "gross_salary": 1586800, // 총급여
  "national_pension": 71406, // 국민연금
  "health_insurance": 56252, // 건강보험
  "employment_insurance": 14281, // 고용보험
  "long_term_care_insurance": 7284, // 장기요양보험료
  "income_tax": 47604, // 소득세
  "local_income_tax": 4760, // 지방소득세
  "total_deduction": 201587, // 공제합계
  "net_pay": 1385213, // 실지급액
  "s3_file_key": null, // 파일은 별도 파일저장 API에서 저장
  "s3_file_url": null, // 파일은 별도 파일저장 API에서 저장
  "created_at": "2026-09-30T09:00:00Z" // 응답 생성 시각
}
```

- **공제 공식**: 국민연금=과세급여×4.5%, 건강보험=과세급여×3.545%, 고용보험=과세급여×0.9%,
  장기요양=건강보험×12.95%, 소득세=총급여×3%, 지방소득세=소득세×10%

---

## 16) 급여명세 저장 (글 데이터 + 파일)

- `POST /staff-management/branches/{branch_id}/employees/{employee_id}/payroll-statements`
- **중복 허용**: 같은 근무자·같은 연/월이라도 여러 건 생성 가능 (제목 동일해도 됨)
- **파일 함께 저장 가능**: `files` 배열에 file_key, file_url, file_name 포함 시 저장 시점에 첨부

### Request Body
```json
{
  "year": 2025,
  "month": 12,
  "resident_id_masked": "992222-1******",
  "total_work_minutes": 8400,
  "hourly_wage": 9860,
  "weekly_allowance": 206400,
  "overtime_pay": 0,
  "taxable_salary": null,
  "gross_salary": null,
  "files": [
    {
      "file_key": "payroll/branch-1/employee-501/2025-12.pdf",
      "file_url": "https://your-bucket.s3.../2025-12.pdf",
      "file_name": "2025-12-급여명세.pdf"
    }
  ]
}
```
- `files`는 선택(없으면 빈 배열). 있으면 저장 시 함께 첨부됨.

### Response Body (200)
```json
{
  "payroll_id": 88, // 저장된 급여명세 PK
  "year": 2025, // 급여 연도
  "month": 12, // 급여 월
  "resident_id_masked": "992222-1******", // 주민번호 마스킹 값
  "total_work_minutes": 8400, // 총 근무시간(분)
  "hourly_wage": 9860, // 시급
  "base_pay": 1380400, // 기본급
  "weekly_allowance": 206400, // 주휴수당
  "overtime_pay": 0, // 연장수당
  "taxable_salary": 1586800, // 과세급여
  "gross_salary": 1586800, // 총급여
  "national_pension": 71406, // 국민연금
  "health_insurance": 56252, // 건강보험
  "employment_insurance": 14281, // 고용보험
  "long_term_care_insurance": 7284, // 장기요양보험료
  "income_tax": 47604, // 소득세
  "local_income_tax": 4760, // 지방소득세
  "total_deduction": 201587, // 공제합계
  "net_pay": 1385213, // 실지급액
  "s3_file_key": null, // 파일 key(파일 저장 전이면 null)
  "s3_file_url": null, // 파일 URL(파일 저장 전이면 null)
  "files": [], // 첨부파일 목록(여러 개 가능)
  "created_at": "2026-09-30T09:00:00Z" // 저장 시각
}
```

---

## 16-1) 급여명세 파일 전용 등록

- `POST /staff-management/branches/{branch_id}/employees/{employee_id}/payroll-statements/file-only`
- **글 데이터 없이 파일만으로 등록**: 연/월만 지정하고 수치 데이터는 0으로 저장. `files` 필수(최소 1개).

### Request Body
```json
{
  "year": 2025,
  "month": 12,
  "files": [
    {
      "file_key": "payroll/branch-1/employee-501/2025-12.pdf",
      "file_url": "https://your-bucket.s3.../2025-12.pdf",
      "file_name": "2025-12-급여명세.pdf"
    }
  ]
}
```

### Response Body (200)
`16) 급여명세 저장`의 Response와 동일 (수치 필드 0, files에 첨부파일 반영)

---

## 17) 급여명세 목록 조회

- `GET /staff-management/branches/{branch_id}/employees/{employee_id}/payroll-statements?year=2025&month=12`
- `year`, `month` 쿼리는 선택값(필터)

### Request Body
없음

### Response Body (200)
```json
{
  "items": [
    {
      "payroll_id": 88, // 급여명세 PK
      "year": 2025, // 급여 연도
      "month": 12, // 급여 월
      "resident_id_masked": "992222-1******", // 주민번호 마스킹 값
      "total_work_minutes": 8400, // 총 근무시간(분)
      "hourly_wage": 9860, // 시급
      "base_pay": 1380400, // 기본급
      "weekly_allowance": 206400, // 주휴수당
      "overtime_pay": 0, // 연장수당
      "taxable_salary": 1586800, // 과세급여
      "gross_salary": 1586800, // 총급여
      "national_pension": 71406, // 국민연금
      "health_insurance": 56252, // 건강보험
      "employment_insurance": 14281, // 고용보험
      "long_term_care_insurance": 7284, // 장기요양보험료
      "income_tax": 47604, // 소득세
      "local_income_tax": 4760, // 지방소득세
      "total_deduction": 201587, // 공제합계
      "net_pay": 1385213, // 실지급액
      "s3_file_key": "payroll/branch-1/employee-501/2025-12.pdf", // S3 object key
      "s3_file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/payroll/branch-1/employee-501/2025-12.pdf", // S3 URL
      "files": [
        {
          "file_id": 11, // 첨부파일 PK
          "file_key": "payroll/branch-1/employee-501/2025-12.pdf", // S3 object key
          "file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/payroll/branch-1/employee-501/2025-12.pdf", // S3 URL
          "file_name": "2025-12-급여명세.pdf", // 표시용 파일명
          "created_at": "2026-09-30T09:01:00Z" // 업로드 시각
        }
      ], // 첨부파일 목록(여러 개 가능)
      "created_at": "2026-09-30T09:00:00Z" // 저장 시각
    }
  ]
}
```

---

## 18) 급여명세 상세 조회

- `GET /staff-management/branches/{branch_id}/employees/{employee_id}/payroll-statements/{payroll_id}`

### Request Body
없음

### Response Body (200)
`16) 급여명세 저장`의 Response와 동일

---

## 19) 급여명세 삭제

- `DELETE /staff-management/branches/{branch_id}/employees/{employee_id}/payroll-statements/{payroll_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "deleted": true
}
```

---

## 20) 급여명세 파일 저장 (파일만)

- `PATCH /staff-management/branches/{branch_id}/employees/{employee_id}/payroll-statements/{payroll_id}/file`
- 한번 요청에 여러 파일 저장 가능(append)
- 응답의 `s3_file_url`, `files[].file_url`로 **미리보기** 가능 (웹뷰/이미지뷰에 URL 사용)

### Request Body
```json
{
  "files": [
    {
      "file_key": "payroll/branch-1/employee-501/2025-12.pdf", // S3 object key
      "file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/payroll/branch-1/employee-501/2025-12.pdf", // S3 URL
      "file_name": "2025-12-급여명세.pdf" // 표시용 파일명
    },
    {
      "file_key": "payroll/branch-1/employee-501/2025-12-부속.pdf", // S3 object key
      "file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/payroll/branch-1/employee-501/2025-12-appendix.pdf", // S3 URL
      "file_name": "2025-12-부속자료.pdf" // 표시용 파일명
    }
  ]
}
```

### Response Body (200)
`16) 급여명세 저장`의 Response와 동일

---

## 21) 인사자료(HR)/기타자료(ETC) 목록/등록/상세/삭제

- 목록:
  - `GET /staff-management/branches/{branch_id}/employees/{employee_id}/records/hr`
  - `GET /staff-management/branches/{branch_id}/employees/{employee_id}/records/etc`
- 등록:
  - `POST /staff-management/branches/{branch_id}/employees/{employee_id}/records/hr`
  - `POST /staff-management/branches/{branch_id}/employees/{employee_id}/records/etc`
- 단건:
  - `GET /staff-management/branches/{branch_id}/employees/{employee_id}/records/{record_type}/{record_id}`
- 삭제:
  - `DELETE /staff-management/branches/{branch_id}/employees/{employee_id}/records/{record_id}`

- **파일 전용 등록**: `file_url`만 제공하면 `title` 없이 등록 가능. `record_type`이 `hr`이면 제목 자동 "인사자료", `etc`이면 "기타자료".

### 등록 Request Body (HR/ETC 공통)
```json
{
  "title": "기타 자료", // 자료 제목 (선택. file_url만 있으면 파일 전용 등록, title 생략 시 자동 생성)
  "note": "메모", // 설명/메모
  "file_url": "https://files.example.com/hr-contract-2026.pdf", // 첨부 파일 URL
  "issued_date": "2026-01-05" // 문서 발행일
}
```
- `title` 또는 `file_url` 중 하나는 반드시 필요. `file_url`만 있으면 파일 전용 등록.

### 등록 Response Body (200)
```json
{
  "record_id": 91, // 자료 PK
  "record_type": "etc", // hr | etc
  "title": "기타 자료", // 제목
  "note": "메모", // 메모
  "file_url": "https://files.example.com/hr-contract-2026.pdf", // 파일 URL
  "issued_date": "2026-01-05", // 발행일
  "created_at": "2026-01-05T09:00:00Z" // 등록 시각
}
```

### 목록 Response Body (200)
```json
{
  "items": [
    {
      "record_id": 91, // 자료 PK
      "record_type": "etc", // hr | etc
      "title": "기타 자료", // 제목
      "note": "메모", // 메모
      "file_url": "https://files.example.com/etc-2026-01.pdf", // 파일 URL
      "issued_date": "2026-01-05", // 작성일/발행일
      "created_at": "2026-01-05T09:00:00Z" // 등록 시각
    }
  ]
}
```

### 단건 Response Body (200)
등록 Response Body와 동일

### 삭제 Response Body (200)
```json
{
  "deleted": true // 삭제 성공 여부
}
```

---

## 22) 근로계약서 목록 조회 (임시저장 포함)

- `GET /staff-management/branches/{branch_id}/employees/{employee_id}/employment-contracts?status=draft&template_version=guardian_consent_v1`
- `status`는 선택값(`draft` 또는 `completed`)
- `template_version`도 선택값(`standard_v1`, `minor_standard_v1`, `guardian_consent_v1`)

### Request Body
없음

### Response Body (200)
```json
{
  "items": [
    {
      "contract_id": 301, // 근로계약서 PK
      "title": "김현수 표준 근로계약서", // 문서 제목
      "status": "draft", // draft(임시저장)|completed(완료)
      "template_version": "standard_v1", // 템플릿 버전
      "completion_rate": 56, // 필수항목 입력률(0~100)
      "form_values": {
        "employer_name": "나눔편의점", // 사업주명
        "worker_name": "김현수", // 근로자명
        "contract_start_date": "2026-03-01" // 근로개시일(예시)
      },
      "contract_file_key": null, // S3 object key
      "contract_file_url": null, // S3 URL
      "files": [], // 첨부파일 목록(여러 개 가능)
      "created_by_user_id": 2, // 작성자 사용자 ID
      "finalized_at": null, // 완료 시각(임시저장은 null)
      "created_at": "2026-03-05T09:00:00Z", // 생성 시각
      "updated_at": "2026-03-05T09:10:00Z" // 마지막 수정 시각
    }
  ]
}
```

---

## 23) 근로계약서 생성 (초안 저장/즉시완료, 글 데이터 + 파일)

- `POST /staff-management/branches/{branch_id}/employees/{employee_id}/employment-contracts`
- 앱에서 빈칸 값을 입력해 `form_values`로 전송
- `template_version=minor_standard_v1` 선택 시 연소근로자 표준근로계약 템플릿으로 저장
- `template_version=guardian_consent_v1` 선택 시 친권자(후견인) 동의서 템플릿으로 저장
- `status=draft`면 중간 저장, `status=completed`면 **필수 항목 모두 입력 후** 완료 저장
- **파일 함께 저장 가능**: `files` 배열 포함 시 저장 시점에 첨부

### 완료 처리(`status=completed`) 시 필수 항목

`status=completed`로 요청할 때는 아래 `form_values` 키가 모두 채워져 있어야 합니다. 하나라도 비어 있으면 400 에러를 반환합니다.

**자동 보정:** `employer_name`이 비어 있고 `employer_business_name`이 있으면, 서버가 `employer_name`을 `employer_business_name`으로 채웁니다. (표준/연소근로자 템플릿만 해당)

**400 에러 응답 예시:**
```json
{
  "detail": {
    "message": "완료 처리할 수 없습니다. 필수 입력 항목이 누락되었습니다.",
    "missing_fields": ["contract_start_date", "job_description", "work_place"],
    "missing_fields_labels": {
      "contract_start_date": "근로개시일",
      "job_description": "업무 내용",
      "work_place": "근무 장소"
    }
  }
}
```
- `missing_fields`: 누락된 form_values 키 목록
- `missing_fields_labels`: 클라이언트 표시용 한글 라벨 맵

#### standard_v1 (표준 근로계약서)

**폼 UI ↔ API 필드 매핑 (계약서 화면 기준)**

| form_values 키 | 한글 라벨 | 폼 위치 |
|----------------|-----------|---------|
| `employer_name` | 사업주명 | 상단 첫 번째 칩 (사업주) |
| `worker_name` | 근로자명 | 상단 두 번째 칩 (근로자) |
| `contract_start_date` | 근로개시일 | 근로계약기간 칩 → 시작일 (YYYY-MM-DD) |
| `work_place` | 근무 장소 | 근무장소 칩 |
| `job_description` | 업무 내용 | 업무내용 칩 |
| `scheduled_work_start_time` | 소정근로 시작 | 소정근로시간 - 시작 시각 (HH:mm) |
| `scheduled_work_end_time` | 소정근로 종료 | 소정근로시간 - 종료 시각 (HH:mm) |
| `work_days_per_week` | 주당 근무일 수 | 근무일/휴일 (자동 기입 시 work_day_N 조합에서 산출) |
| `weekly_holiday_day` | 주휴일 요일 | 근무일/휴일 - 주휴일 요일 |
| `wage_type` | 임금 유형 | 임금 - 월/일/시간급 선택 (monthly\|daily\|hourly) |
| `wage_amount` | 임금 금액(원) | 임금 - 금액 칩 |
| `payment_day` | 임금지급일 | 임금 - 임금지급일 칩 (매월 N일) |
| `payment_method` | 지급방법 | 직접지급=`direct`, 예금통장입금=`bank_transfer` |
| `contract_signed_date` | 계약 체결일 | 날짜 연/월/일 스피너 결합 (YYYY-MM-DD) |
| `employer_business_name` | 사업체명 | 하단 사업주 - 사업체명 칩 |
| `employer_representative_name` | 대표자 성명 | 하단 사업주 - 대표자 칩 |

**주의:** `employer_name`은 상단 "사업주" 칩이고, `employer_business_name`은 하단 "사업체명" 칩입니다. `employer_name`이 비어 있으면 `employer_business_name`으로 자동 채움되므로, 사업체명만 보내도 됩니다.

**Flutter 수집 시 흔한 누락:** 하단 사업주 영역만 채우고 상단 `employer_name`, `contract_start_date`, `work_place`, `job_description`을 `form_values`에 넣지 않으면 400 에러가 납니다. 제출 직전에 위 16개 키가 모두 포함되는지 확인하세요.

#### minor_standard_v1 (연소근로자 표준 근로계약서)

표준 필수 항목 16개 **모두** + 아래 2개 추가 필수 (총 18개):

| form_values 키 | 한글 라벨 | 계약서 위치 |
|----------------|-----------|-------------|
| `family_relation_certificate_submitted` | 가족관계증명서 제출 여부 | 가족관계기록사항에 관한 증명서 제출 여부 |
| `guardian_consent_submitted` | 친권자/후견인 동의서 구비 여부 | 친권자 또는 후견인의 동의서 구비 여부 |

**연소근로자 계약서 ↔ API 전체 매핑:**
| 계약서 항목 | form_values 키 | 필수 |
|-------------|----------------|------|
| (이하 "사업주"라 함) | `employer_name` | ✓ |
| (이하 "근로자"라 함) | `worker_name` | ✓ |
| 근로계약기간 시작일 | `contract_start_date` | ✓ |
| 근로계약기간 종료일 | `contract_end_date` | 선택 |
| 근무 장소 | `work_place` | ✓ |
| 업무 내용 | `job_description` | ✓ |
| 소정근로시간 (시~분부터~시~분까지) | `scheduled_work_start_time`, `scheduled_work_end_time` | ✓ |
| 휴게시간 | `break_start_time`, `break_end_time` | 선택 |
| 근무일/휴일 (매주 N일) | `work_days_per_week` | ✓ |
| 주휴일 (매주 N요일) | `weekly_holiday_day` | ✓ |
| 월(일,시간)급 | `wage_type`, `wage_amount` | ✓ |
| 상여금 | `bonus_included`, `bonus_amount` | 선택 |
| 기타급여/식대/교통비/기타 | `other_allowance_*`, `meal_allowance`, `transport_allowance`, `extra_allowance_*` | 선택 |
| 임금지급일 | `payment_day` | ✓ |
| 지급방법 | `payment_method` | ✓ |
| 가족관계증명서 제출 여부 | `family_relation_certificate_submitted` | ✓ |
| 친권자/후견인 동의서 구비 여부 | `guardian_consent_submitted` | ✓ |
| 계약 체결일 (연/월/일) | `contract_signed_date` | ✓ |
| (사업주) 사업체명, 전화, 주소, 대표자 | `employer_business_name`, `employer_phone`, `employer_address`, `employer_representative_name` | 사업체명·대표자 필수 |
| (근로자) 주소, 연락처, 성명 | `worker_address`, `worker_phone`, `worker_signature_text` | 선택 |

#### guardian_consent_v1 (친권자 동의서)
| form_values 키 | 한글 라벨 |
|----------------|-----------|
| `guardian_name` | 친권자(후견인) 성명 |
| `guardian_resident_id_masked` | 친권자 주민번호 마스킹 |
| `guardian_address` | 친권자 주소 |
| `guardian_phone_number` | 친권자 연락처 |
| `relation_to_minor_worker` | 근로자와의 관계 |
| `minor_name` | 만 18세 미만 근로자 성명 |
| `minor_age` | 만 18세 미만 근로자 나이 |
| `minor_resident_id_masked` | 만 18세 미만 근로자 주민번호 마스킹 |
| `minor_address` | 만 18세 미만 근로자 주소 |
| `business_name` | 사업체명 |
| `business_address` | 사업장 주소 |
| `business_representative_name` | 사업주 대표자명 |
| `business_phone_number` | 사업장 연락처 |
| `consent_minor_name` | 동의서 상 근로자명 |
| `consent_signed_date` | 동의서 작성일 |
| `guardian_signature_name` | 친권자 서명 |
| `family_relation_certificate_attached` | 가족관계증명서 첨부 여부 |

### Request Body
```json
{
  "title": "김현수 표준 근로계약서", // 문서 제목(없으면 자동 생성)
  "template_version": "minor_standard_v1", // standard_v1 | minor_standard_v1 | guardian_consent_v1
  "status": "draft", // draft|completed
  "form_values": {
    "employer_name": "나눔편의점", // (이하 "사업주")
    "worker_name": "김현수", // (이하 "근로자")
    "contract_start_date": "2026-03-01", // 근로계약 시작일
    "contract_end_date": "2027-02-28", // 근로계약 종료일(미지정 가능)
    "work_place": "서울시 강남구 OO로 12 나눔편의점", // 근무 장소
    "job_description": "매장 계산, 진열, 청소", // 업무 내용
    "scheduled_work_start_time": "09:00", // 소정근로 시작
    "scheduled_work_end_time": "18:00", // 소정근로 종료
    "break_start_time": "13:00", // 휴게 시작
    "break_end_time": "14:00", // 휴게 종료
    "work_days_per_week": 5, // 주 근무일수
    "weekly_holiday_day": "일", // 주휴일 요일
    "wage_type": "monthly", // monthly|daily|hourly
    "wage_amount": 2300000, // 월/일/시간급 금액(원)
    "bonus_included": false, // 상여금 여부
    "bonus_amount": 0, // 상여금 금액
    "other_allowance_included": true, // 기타수당 여부
    "other_allowance_amount": 150000, // 기타수당 총액
    "meal_allowance": 100000, // 식대
    "transport_allowance": 50000, // 교통비
    "extra_allowance_name": "야간수당", // 기타 항목명
    "extra_allowance_amount": 0, // 기타 항목 금액
    "payment_day": 10, // 임금지급일
    "payment_method": "bank_transfer", // direct|bank_transfer
    "annual_leave_note": "근로기준법에 따름", // 연차유급휴가 문구
    "contract_delivery_confirmed": true, // 계약서 교부 확인
    "law_reference_confirmed": true, // 근로기준법령 준수 확인
    "contract_signed_date": "2026-03-05", // 계약 체결일
    "employer_business_name": "나눔편의점 강남점", // 사업체명
    "employer_phone": "02-1234-5678", // 사업주 전화
    "employer_address": "서울시 강남구 OO로 12", // 사업주 주소
    "employer_representative_name": "홍길동", // 대표자 성명
    "employer_signature_text": "홍길동", // 사업주 서명값
    "worker_address": "서울시 송파구 OO로 20", // 근로자 주소
    "worker_phone": "010-1234-5678", // 근로자 연락처
    "worker_signature_text": "김현수", // 근로자 서명값
    "family_relation_certificate_submitted": "제출", // 가족관계증명서 제출 여부(연소근로자)
    "guardian_consent_submitted": "제출" // 친권자/후견인 동의서 구비 여부(연소근로자)
  },
  "files": [
    {
      "file_key": "contracts/branch-1/employee-501/contract-2026-03.pdf",
      "file_url": "https://your-bucket.s3.../contract-2026-03.pdf",
      "file_name": "표준근로계약서.pdf"
    }
  ]
}
```
- `files`는 선택(없으면 빈 배열). 있으면 저장 시 함께 첨부됨.

### Response Body (200)
```json
{
  "contract_id": 301, // 생성된 계약서 PK
  "title": "김현수 연소근로자 표준 근로계약서", // 문서 제목
  "status": "draft", // 저장 상태
  "template_version": "minor_standard_v1", // 템플릿 버전
  "completion_rate": 72, // 필수항목 입력률
  "form_values": {
    "employer_name": "나눔편의점", // 저장된 입력값들
    "worker_name": "김현수"
  },
  "contract_file_key": null, // 파일 key(파일 저장 전이면 null)
  "contract_file_url": null, // 파일 URL(파일 저장 전이면 null)
  "files": [], // 첨부파일 목록(여러 개 가능)
  "created_by_user_id": 2, // 작성자 사용자 ID
  "finalized_at": null, // 완료 시각
  "created_at": "2026-03-05T09:00:00Z", // 생성 시각
  "updated_at": "2026-03-05T09:00:00Z" // 수정 시각
}
```

---

## 23-1) 근로계약서/부모님동의서 파일 전용 등록

- `POST /staff-management/branches/{branch_id}/employees/{employee_id}/employment-contracts/file-only`
- **글 데이터 없이 파일만으로 등록**: form_values 없이 `template_version`과 `files`만으로 근로계약서·연소근로자 계약서·친권자(부모님) 동의서 등록. status=draft, completion_rate=0.

### Request Body
```json
{
  "template_version": "guardian_consent_v1", // standard_v1 | minor_standard_v1 | guardian_consent_v1
  "title": null, // 선택 (없으면 "근무자명 표준 근로계약서" 등 자동 생성)
  "files": [
    {
      "file_key": "contracts/branch-1/employee-501/consent.pdf",
      "file_url": "https://your-bucket.s3.../consent.pdf",
      "file_name": "친권자동의서.pdf"
    }
  ]
}
```

### Response Body (200)
`23) 근로계약서 생성`의 Response와 동일

---

## 24) 근로계약서 수정/중간저장/완료처리 (글 데이터만)

- `PATCH /staff-management/branches/{branch_id}/employees/{employee_id}/employment-contracts/{contract_id}`
- 입력 도중에는 `status=draft`로 반복 저장 가능
- 마지막 단계에서 `status=completed`로 완료 처리
- `status=completed` 시 **23)의 완료 처리 시 필수 항목**이 병합 후 모두 채워져 있어야 함

### Request Body
```json
{
  "status": "completed", // draft|completed (생략 시 기존 유지)
  "title": "김현수 표준 근로계약서", // 제목 변경 시 전달
  "form_values": {
    "work_place": "서울시 강남구 OO로 12 나눔편의점", // 수정할 필드만 전달 가능
    "job_description": "매장 계산, 진열, 청소", // 수정할 필드만 전달 가능
    "payment_method": "bank_transfer" // 수정할 필드만 전달 가능
  },
  "merge_form_values": true // true=기존값에 병합, false=전체 교체
}
```

### Response Body (200)
`22) 근로계약서 생성`의 Response와 동일

---

## 25) 근로계약서 파일 저장 (파일만)

- `PATCH /staff-management/branches/{branch_id}/employees/{employee_id}/employment-contracts/{contract_id}/file`
- 한번 요청에 여러 파일 저장 가능(append)

### Request Body
```json
{
  "files": [
    {
      "file_key": "contracts/branch-1/employee-501/contract-2026-03-final.pdf", // S3 key
      "file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/contracts/branch-1/employee-501/contract-2026-03-final.pdf", // S3 URL
      "file_name": "연소근로자-표준근로계약서.pdf" // 표시용 파일명
    },
    {
      "file_key": "contracts/branch-1/employee-501/consent-guardian.pdf", // S3 key
      "file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/contracts/branch-1/employee-501/consent-guardian.pdf", // S3 URL
      "file_name": "친권자동의서.pdf" // 표시용 파일명
    }
  ]
}
```

### Response Body (200)
`22) 근로계약서 생성`의 Response와 동일

---

## 26) 근로계약서 단건 조회

- `GET /staff-management/branches/{branch_id}/employees/{employee_id}/employment-contracts/{contract_id}`

### Request Body
없음

### Response Body (200)
`22) 근로계약서 생성`의 Response와 동일

---

## 27) 근로계약서 삭제

- `DELETE /staff-management/branches/{branch_id}/employees/{employee_id}/employment-contracts/{contract_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "deleted": true // 삭제 성공 여부
}
```

---

## 28) 친권자(후견인) 동의서 작성 템플릿

- `22) 근로계약서 생성` API를 사용하고 `template_version=guardian_consent_v1`로 저장
- `24) 근로계약서 파일 저장` API로 가족관계증명서/동의서 파일 다중 첨부 가능

### Request Body 예시
```json
{
  "title": "김현수 친권자(후견인) 동의서", // 문서 제목(없으면 자동 생성)
  "template_version": "guardian_consent_v1", // 친권자 동의서 템플릿
  "status": "draft", // draft|completed
  "form_values": {
    "guardian_name": "김민정", // 친권자(후견인) 성명
    "guardian_resident_id_masked": "800101-2******", // 주민등록번호(마스킹)
    "guardian_address": "서울시 마포구 OO로 12", // 주소
    "guardian_phone_number": "010-2222-3333", // 연락처
    "relation_to_minor_worker": "모", // 연소근로자와의 관계
    "minor_name": "김현수", // 연소근로자 성명
    "minor_age": 14, // 만 나이
    "minor_resident_id_masked": "110101-3******", // 주민등록번호(마스킹)
    "minor_address": "서울시 마포구 OO로 12", // 주소
    "business_name": "나눔편의점 강남점", // 회사명
    "business_address": "서울시 강남구 OO로 55", // 회사주소
    "business_representative_name": "홍길동", // 대표자
    "business_phone_number": "02-1234-5678", // 회사전화
    "consent_minor_name": "김현수", // 동의문에 들어갈 연소근로자명
    "consent_signed_date": "2026-03-06", // 작성일
    "guardian_signature_name": "김민정", // 친권자(후견인) 서명
    "family_relation_certificate_attached": "첨부" // 첨부: 가족관계증명서 1부
  }
}
```

### completed 처리 시 필수값

- `guardian_name`
- `guardian_resident_id_masked`
- `guardian_address`
- `guardian_phone_number`
- `relation_to_minor_worker`
- `minor_name`
- `minor_age`
- `minor_resident_id_masked`
- `minor_address`
- `business_name`
- `business_address`
- `business_representative_name`
- `business_phone_number`
- `consent_minor_name`
- `consent_signed_date`
- `guardian_signature_name`
- `family_relation_certificate_attached`

---

## 29) 주간 출결 확정 저장 (주휴수당 판단용)

- `POST /staff-management/branches/{branch_id}/attendance/weekly/confirm`
- `week_start_date`는 월요일만 허용
- `employee_ids`를 생략하면 점포 전체 직원 기준으로 확정 저장(upsert)
- 확정 데이터는 인건비 `saving-detail` API에서 주휴수당 대상 판단에 우선 반영됨

### Request Body
```json
{
  "week_start_date": "2026-03-02", // 주 시작일(월요일)
  "employee_ids": [501, 502] // 선택: 특정 직원만 확정(생략 시 전체)
}
```

### Response Body (200)
```json
{
  "items": [
    {
      "confirmation_id": 31, // 출결 확정 PK
      "employee_id": 501, // 직원 ID
      "employee_name": "이사라", // 직원명
      "week_start_date": "2026-03-02", // 주 시작일
      "week_end_date": "2026-03-08", // 주 종료일
      "scheduled_workdays": 5, // 스케줄이 잡힌 일수
      "attended_workdays": 5, // 출근 확정 일수(해당 일 모든 슬롯 done)
      "absent_workdays": 0, // 결근 일수(absent 포함 일)
      "unfinalized_workdays": 0, // 미확정 일수(scheduled/unset 포함 일)
      "total_work_minutes": 960, // 확정 주간 총 근로분
      "average_weekly_minutes": 960, // 주 평균 근로분(현재 단일 주 확정값)
      "perfect_attendance": true, // 개근 충족 여부
      "legal_weekly_hours_condition_met": true, // 주15시간(900분) 이상 여부
      "weekly_allowance_eligible": true, // 주휴수당 대상 여부(개근 + 15시간)
      "confirmed_by_user_id": 2, // 확정 처리한 사용자 ID
      "confirmed_at": "2026-03-09T10:30:00Z" // 확정 시각
    }
  ]
}
```

---

## 30) 주간 출결 확정 조회

- `GET /staff-management/branches/{branch_id}/attendance/weekly?week_start_date=2026-03-02`
- `employee_id`는 선택 필터

### Request Body
없음

### Response Body (200)
`28) 주간 출결 확정 저장`의 Response와 동일

---

## 급여 공제 계산식

- 국민연금 = 과세급여 × 4.5%
- 건강보험 = 과세급여 × 3.545%
- 고용보험 = 과세급여 × 0.9%
- 장기요양보험료 = 건강보험료 × 12.95%
- 소득세 = 총급여 × 3%
- 지방소득세 = 소득세 × 10%
