# 경영주 홈 API 스펙

기본 prefix: `/api/v1`

## 인증

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `GET /me`는 전체 역할 사용자 호출 가능
- `/owner/home/**`는 `user_profiles.role == owner` 사용자만 호출 가능

---

## 1) 내 정보 조회 (역할별 응답)

- `GET /me`

### Request Body
없음

### Response Body (200)
```json
{
  "id": 1,
  "email": "owner@nanum.com",
  "full_name": "홍길동",
  "phone_number": "01012345678",
  "role": "owner",
  "approval_status": "pending_admin_approval",
  "signup_step": "completed",
  "signup_step1_passed": true,
  "signup_step2_passed": true,
  "is_active": true,
  "created_at": "2026-03-05T00:00:00Z",
  "owner": {
    "total_branches": 2,
    "pending_branches": 1,
    "approved_branches": 1,
    "rejected_branches": 0,
    "branches": [
      {
        "id": 10,
        "name": "나눔 강남점",
        "code": "AB12CD34",
        "review_status": "pending",
        "is_open_for_manager": true
      }
    ]
  },
  "manager": null,
  "worker": null
}
```

---

## 2) 경영주 점포 목록

- `GET /owner/home/branches`

### Request Body
없음

### Response Body (200)
```json
{
  "items": [
    {
      "id": 10,
      "name": "나눔 강남점",
      "code": "AB12CD34",
      "review_status": "pending",
      "review_note": "서류 확인 중입니다.",
      "manager_user_id": null,
      "is_open_for_manager": true,
      "created_at": "2026-03-05T00:00:00Z"
    }
  ]
}
```

### 2-1) 경영주 점포 추가

- `POST /owner/home/branches`

### Request Body
```json
{
  "branch_name": "나눔 서초점",
  "branch_code": "SEOCHO01"
}
```

- `branch_code` 미전달 시 서버가 8자리 코드를 자동 생성합니다.

### Response Body (201)
```json
{
  "id": 11,
  "name": "나눔 서초점",
  "code": "SEOCHO01",
  "review_status": "pending",
  "review_note": null,
  "manager_user_id": null,
  "is_open_for_manager": true,
  "created_at": "2026-03-05T00:00:00Z"
}
```

---

## 3) 점포 상세 (홈 메인 카드)

- `GET /owner/home/branches/{branch_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "id": 10,
  "name": "나눔 강남점",
  "code": "AB12CD34",
  "review_status": "approved",
  "review_note": null,
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "manager_candidates": [],
  "workers": [],
  "today_shift_date": "2026-03-05",
  "today_shift_rows": [],
  "monthly_labor_cost": {
    "monthly_total": 0,
    "message": "근무 스케줄/시급 데이터 연동 전입니다."
  }
}
```

---

## 4) 등록된 점장 리스트 (사전등록/연결 현황)

- `GET /owner/home/branches/{branch_id}/manager-registrations`

### Request Body
없음

### Response Body (200)
```json
{
  "items": [
    {
      "registration_id": 101,
      "manager_name": "이사라",
      "manager_phone_number": "01033333333",
      "status": "linked",
      "linked_user_id": 25,
      "created_at": "2026-03-05T02:00:00Z"
    },
    {
      "registration_id": 102,
      "manager_name": "박민수",
      "manager_phone_number": "01077778888",
      "status": "pre_registered",
      "linked_user_id": null,
      "created_at": "2026-03-05T03:00:00Z"
    }
  ]
}
```

---

## 5) 점장 등록 (점장 ID 발급 포함)

- `POST /owner/home/branches/{branch_id}/manager`

### Request Body A (기존 회원 배정)
```json
{
  "manager_user_id": 25
}
```

### Request Body B (이름+전화번호 사전등록)
```json
{
  "manager_name": "이사라",
  "manager_phone_number": "01033333333"
}
```

### Request Body C (전화번호로 기존 회원 배정)
```json
{
  "manager_phone_number": "01033333333"
}
```

### Response Body (200, 사전등록만)
```json
{
  "branch_id": 10,
  "action": "pre_registered",
  "manager": null,
  "registration": {
    "registration_id": 101,
    "manager_name": "이사라",
    "manager_phone_number": "01033333333",
    "status": "pre_registered",
    "linked_user_id": null,
    "created_at": "2026-03-05T02:00:00Z"
  }
}
```

### Response Body (200, 사전등록+자동연결)
```json
{
  "branch_id": 10,
  "action": "pre_registered_and_linked",
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "registration": {
    "registration_id": 101,
    "manager_name": "이사라",
    "manager_phone_number": "01033333333",
    "status": "linked",
    "linked_user_id": 25,
    "created_at": "2026-03-05T02:00:00Z"
  }
}
```

### Response Body (200, 기존 회원 배정)
```json
{
  "branch_id": 10,
  "action": "assigned_existing_user",
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "registration": null
}
```

---

## 6) 점장 삭제 (현재 배정된 점장)

- `DELETE /owner/home/branches/{branch_id}/manager`

### Request Body
없음

### Response Body (200)
```json
{
  "branch_id": 10,
  "removed_manager_user_id": 25,
  "removed_registration_id": null,
  "message": "Manager assignment removed"
}
```

---

## 7) 점장 사전등록 ID 삭제

- `DELETE /owner/home/branches/{branch_id}/manager-registrations/{registration_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "branch_id": 10,
  "removed_manager_user_id": 25,
  "removed_registration_id": 101,
  "message": "Manager registration deleted"
}
```

---

## 8) 점장 회원가입 인증 (사전등록 ID 사용)

- `POST /auth/signup/complete`

### Request Body
```json
{
  "role": "manager",
  "manager_registration_id": 101,
  "manager_phone_number": "01033333333"
}
```

### Response Body (200)
```json
{
  "access_token": "jwt",
  "token_type": "bearer",
  "is_new_user": false,
  "user": {
    "id": 25,
    "email": "manager@nanum.com",
    "full_name": "이사라",
    "phone_number": "01033333333",
    "role": "manager",
    "signup_step": "completed",
    "approval_status": "approved_by_owner",
    "is_active": true,
    "created_at": "2026-03-05T00:00:00Z",
    "requested_branch_id": 10
  }
}
```

---

## 9) 미래 기능 API 명세 (미구현 초안)

직원관리/인건비 페이지 구현 시 사용할 예정 스펙입니다.

### 9-1) 지점 이슈 알림 목록
- `GET /owner/home/branches/{branch_id}/alerts`

#### Request Body
없음

#### Response Body (200)
```json
{
  "items": [
    {
      "alert_id": 9001,
      "title": "퇴직금 발생",
      "content": "3개월 내 퇴직금을 지급해야 하는 직원이 있어요.",
      "is_open": true,
      "priority": "high"
    }
  ]
}
```

### 9-2) 지점 이슈 알림 펼침/닫힘
- `PATCH /owner/home/branches/{branch_id}/alerts/{alert_id}`

#### Request Body
```json
{
  "is_open": false
}
```

#### Response Body (200)
```json
{
  "alert_id": 9001,
  "is_open": false
}
```

### 9-3) 오늘 근무자 현황
- `GET /owner/home/branches/{branch_id}/today-workers?date=2026-09-11`

#### Request Body
없음

#### Response Body (200)
```json
{
  "date": "2026-09-11",
  "rows": [
    {
      "shift_id": 7001,
      "time_label": "09:00",
      "worker_name": "이시현",
      "memo": "",
      "status": "scheduled"
    },
    {
      "shift_id": 7002,
      "time_label": "18:00",
      "worker_name": "이정의",
      "memo": "",
      "status": "done"
    }
  ]
}
```

### 9-4) 오늘 근무 상태 변경
- `PATCH /owner/home/branches/{branch_id}/today-workers/{shift_id}/status`

#### Request Body
```json
{
  "status": "done"
}
```

#### Response Body (200)
```json
{
  "shift_id": 7001,
  "status": "done"
}
```

### 9-5) 인건비 요약 카드
- `GET /owner/home/branches/{branch_id}/labor-cost/summary?month=2026-09`

#### Request Body
없음

#### Response Body (200)
```json
{
  "month": "2026-09",
  "total_labor_cost": 9157430,
  "change_rate_percent": 110.3,
  "change_direction": "up"
}
```

### 9-6) 인건비 절감 포인트
- `GET /owner/home/branches/{branch_id}/labor-cost/insights?month=2026-09`

#### Request Body
없음

#### Response Body (200)
```json
{
  "month": "2026-09",
  "points": [
    "3개월 내 퇴직금을 지급해야하는 직원이 있어요. 퇴직금 발생 전 직원 교체를 권장해요",
    "근무자 4명을 더 채용하시면 주휴수당을 절감할 수 있습니다."
  ]
}
```

### 9-7) 근무자 운영 설정 조회
- `GET /owner/home/branches/{branch_id}/worker-settings`

#### Request Body
없음

#### Response Body (200)
```json
{
  "target_worker_count": 6,
  "min_workers_per_shift": 2,
  "night_shift_enabled": true,
  "max_weekly_hours_per_worker": 40
}
```

### 9-8) 근무자 운영 설정 저장
- `PUT /owner/home/branches/{branch_id}/worker-settings`

#### Request Body
```json
{
  "target_worker_count": 7,
  "min_workers_per_shift": 2,
  "night_shift_enabled": true,
  "max_weekly_hours_per_worker": 40
}
```

#### Response Body (200)
```json
{
  "saved": true
}
```
# 경영주 홈 API 스펙

기본 prefix: `/api/v1`

## 인증

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `GET /me`는 전체 역할 사용자 호출 가능
- `/owner/home/**`는 `user_profiles.role == owner` 사용자만 호출 가능

---

## 1) 내 정보 조회 (역할별 응답)

- `GET /me`

### Request Body

없음

### Response Body (200)

```json
{
  "id": 1,
  "email": "owner@nanum.com",
  "full_name": "홍길동",
  "phone_number": "01012345678",
  "role": "owner",
  "approval_status": "pending_admin_approval",
  "signup_step": "completed",
  "signup_step1_passed": true,
  "signup_step2_passed": true,
  "is_active": true,
  "created_at": "2026-03-05T00:00:00Z",
  "owner": {
    "total_branches": 2,
    "pending_branches": 1,
    "approved_branches": 1,
    "rejected_branches": 0,
    "branches": [
      {
        "id": 10,
        "name": "나눔 강남점",
        "code": "AB12CD34",
        "review_status": "pending",
        "is_open_for_manager": true
      }
    ]
  },
  "manager": null,
  "worker": null
}
```

---

## 2) 경영주 점포 목록

- `GET /owner/home/branches`

### Request Body

없음

### Response Body (200)

```json
{
  "items": [
    {
      "id": 10,
      "name": "나눔 강남점",
      "code": "AB12CD34",
      "review_status": "pending",
      "review_note": "서류 확인 중입니다.",
      "manager_user_id": null,
      "is_open_for_manager": true,
      "created_at": "2026-03-05T00:00:00Z"
    }
  ]
}
```

---

## 3) 점포 상세 (홈 메인 카드 기반)

- `GET /owner/home/branches/{branch_id}`

### Request Body

없음

### Response Body (200)

```json
{
  "id": 10,
  "name": "나눔 강남점",
  "code": "AB12CD34",
  "review_status": "approved",
  "review_note": null,
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "manager_candidates": [],
  "workers": [],
  "today_shift_date": "2026-03-05",
  "today_shift_rows": [],
  "monthly_labor_cost": {
    "monthly_total": 0,
    "message": "근무 스케줄/시급 데이터 연동 전입니다."
  }
}
```

---

## 4) 등록된 점장 리스트(사전등록/연결 현황)

- `GET /owner/home/branches/{branch_id}/manager-registrations`

### Request Body

없음

### Response Body (200)

```json
{
  "items": [
    {
      "registration_id": 101,
      "manager_name": "이사라",
      "manager_phone_number": "01033333333",
      "status": "linked",
      "linked_user_id": 25,
      "created_at": "2026-03-05T02:00:00Z"
    },
    {
      "registration_id": 102,
      "manager_name": "박민수",
      "manager_phone_number": "01077778888",
      "status": "pre_registered",
      "linked_user_id": null,
      "created_at": "2026-03-05T03:00:00Z"
    }
  ]
}
```

---

## 5) 점장 등록 (점장 ID 발급 포함)

- `POST /owner/home/branches/{branch_id}/manager`

### Request Body A: 기존 회원 바로 배정

```json
{
  "manager_user_id": 25
}
```

### Request Body B: 이름+전화번호로 사전 등록 (권장)

```json
{
  "manager_name": "이사라",
  "manager_phone_number": "01033333333"
}
```

### Request Body C: 전화번호로 기존 점장 검색 후 배정

```json
{
  "manager_phone_number": "01033333333"
}
```

### Response Body (200) - 사전등록만 된 경우

```json
{
  "branch_id": 10,
  "action": "pre_registered",
  "manager": null,
  "registration": {
    "registration_id": 101,
    "manager_name": "이사라",
    "manager_phone_number": "01033333333",
    "status": "pre_registered",
    "linked_user_id": null,
    "created_at": "2026-03-05T02:00:00Z"
  }
}
```

### Response Body (200) - 사전등록 + 계정 자동연결

```json
{
  "branch_id": 10,
  "action": "pre_registered_and_linked",
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "registration": {
    "registration_id": 101,
    "manager_name": "이사라",
    "manager_phone_number": "01033333333",
    "status": "linked",
    "linked_user_id": 25,
    "created_at": "2026-03-05T02:00:00Z"
  }
}
```

### Response Body (200) - 기존 회원 배정

```json
{
  "branch_id": 10,
  "action": "assigned_existing_user",
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "registration": null
}
```

---

## 6) 점장 삭제 (현재 배정된 점장 삭제)

- `DELETE /owner/home/branches/{branch_id}/manager`

### Request Body

없음

### Response Body (200)

```json
{
  "branch_id": 10,
  "removed_manager_user_id": 25,
  "removed_registration_id": null,
  "message": "Manager assignment removed"
}
```

---

## 7) 점장 사전등록 ID 삭제

- `DELETE /owner/home/branches/{branch_id}/manager-registrations/{registration_id}`

### Request Body

없음

### Response Body (200)

```json
{
  "branch_id": 10,
  "removed_manager_user_id": 25,
  "removed_registration_id": 101,
  "message": "Manager registration deleted"
}
```

---

## 8) 점장 회원가입 시 인증 방법

경영주가 발급한 `registration_id`로 점장이 본인 인증을 진행할 수 있습니다.

- `POST /auth/signup/complete`

### Request Body

```json
{
  "role": "manager",
  "manager_registration_id": 101,
  "manager_phone_number": "01033333333"
}
```

### Response Body (200)

```json
{
  "access_token": "jwt",
  "token_type": "bearer",
  "is_new_user": false,
  "user": {
    "id": 25,
    "email": "manager@nanum.com",
    "full_name": "이사라",
    "phone_number": "01033333333",
    "role": "manager",
    "signup_step": "completed",
    "approval_status": "approved_by_owner",
    "is_active": true,
    "created_at": "2026-03-05T00:00:00Z",
    "requested_branch_id": 10
  }
}
```

---

## 9) 미래 기능 API 명세 (직원관리/인건비 페이지용, 예정)

아래 API는 **지금은 미구현**이며, 이후 화면 개발 시 사용할 스펙 초안입니다.

### 9-1) 지점 이슈 알림 목록

- `GET /owner/home/branches/{branch_id}/alerts`

#### Request Body

없음

#### Response Body (200)

```json
{
  "items": [
    {
      "alert_id": 9001,
      "title": "퇴직금 발생",
      "content": "3개월 내 퇴직금을 지급해야 하는 직원이 있어요.",
      "is_open": true,
      "priority": "high"
    }
  ]
}
```

### 9-2) 지점 이슈 알림 펼침/닫힘

- `PATCH /owner/home/branches/{branch_id}/alerts/{alert_id}`

#### Request Body

```json
{
  "is_open": false
}
```

#### Response Body (200)

```json
{
  "alert_id": 9001,
  "is_open": false
}
```

### 9-3) 오늘 근무자 현황

- `GET /owner/home/branches/{branch_id}/today-workers?date=2026-09-11`

#### Request Body

없음

#### Response Body (200)

```json
{
  "date": "2026-09-11",
  "rows": [
    {
      "shift_id": 7001,
      "time_label": "09:00",
      "worker_name": "이시현",
      "memo": "",
      "status": "scheduled"
    },
    {
      "shift_id": 7002,
      "time_label": "18:00",
      "worker_name": "이정의",
      "memo": "",
      "status": "done"
    }
  ]
}
```

### 9-4) 오늘 근무 상태 변경

- `PATCH /owner/home/branches/{branch_id}/today-workers/{shift_id}/status`

#### Request Body

```json
{
  "status": "done"
}
```

#### Response Body (200)

```json
{
  "shift_id": 7001,
  "status": "done"
}
```

### 9-5) 인건비 요약 카드

- `GET /owner/home/branches/{branch_id}/labor-cost/summary?month=2026-09`

#### Request Body

없음

#### Response Body (200)

```json
{
  "month": "2026-09",
  "total_labor_cost": 9157430,
  "change_rate_percent": 110.3,
  "change_direction": "up"
}
```

### 9-6) 인건비 절감 포인트

- `GET /owner/home/branches/{branch_id}/labor-cost/insights?month=2026-09`

#### Request Body

없음

#### Response Body (200)

```json
{
  "month": "2026-09",
  "points": [
    "3개월 내 퇴직금을 지급해야하는 직원이 있어요. 퇴직금 발생 전 직원 교체를 권장해요",
    "근무자 4명을 더 채용하시면 주휴수당을 절감할 수 있습니다."
  ]
}
```

### 9-7) 근무자 운영 설정 조회

- `GET /owner/home/branches/{branch_id}/worker-settings`

#### Request Body

없음

#### Response Body (200)

```json
{
  "target_worker_count": 6,
  "min_workers_per_shift": 2,
  "night_shift_enabled": true,
  "max_weekly_hours_per_worker": 40
}
```

### 9-8) 근무자 운영 설정 저장

- `PUT /owner/home/branches/{branch_id}/worker-settings`

#### Request Body

```json
{
  "target_worker_count": 7,
  "min_workers_per_shift": 2,
  "night_shift_enabled": true,
  "max_weekly_hours_per_worker": 40
}
```

#### Response Body (200)

```json
{
  "saved": true
}
```
# 경영주 홈 API 스펙

기본 prefix: `/api/v1`

## 인증

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `user_profiles.role == owner` 사용자만 호출 가능 (`GET /me`는 전체 역할 가능)

---

## 1) 내 정보 조회 (역할별 응답)

- `GET /me`

### Request Body

없음

### Response Body (200)

```json
{
  "id": 1,
  "email": "owner@nanum.com",
  "full_name": "홍길동",
  "phone_number": "01012345678",
  "role": "owner",
  "approval_status": "pending_admin_approval",
  "signup_step": "completed",
  "signup_step1_passed": true,
  "signup_step2_passed": true,
  "is_active": true,
  "created_at": "2026-03-05T00:00:00Z",
  "owner": {
    "total_branches": 2,
    "pending_branches": 1,
    "approved_branches": 1,
    "rejected_branches": 0,
    "branches": [
      {
        "id": 10,
        "name": "나눔 강남점",
        "code": "AB12CD34",
        "review_status": "pending",
        "is_open_for_manager": true
      }
    ]
  },
  "manager": null,
  "worker": null
}
```

---

## 2) 경영주 점포 목록

- `GET /owner/home/branches`

### Request Body

없음

### Response Body (200)

```json
{
  "items": [
    {
      "id": 10,
      "name": "나눔 강남점",
      "code": "AB12CD34",
      "review_status": "pending",
      "review_note": "서류 확인 중입니다.",
      "manager_user_id": null,
      "is_open_for_manager": true,
      "created_at": "2026-03-05T00:00:00Z"
    }
  ]
}
```

---

## 3) 점포 상세 (홈 3번째 화면 기반)

- `GET /owner/home/branches/{branch_id}`

### Request Body

없음

### Response Body (200)

```json
{
  "id": 10,
  "name": "나눔 강남점",
  "code": "AB12CD34",
  "review_status": "approved",
  "review_note": null,
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "registered_managers": [
    {
      "registration_id": 101,
      "manager_name": "이사라",
      "manager_phone_number": "01033333333",
      "status": "linked",
      "linked_user_id": 25,
      "created_at": "2026-03-05T02:00:00Z"
    }
  ],
  "manager_candidates": [],
  "workers": [],
  "today_shift_date": "2026-03-05",
  "today_shift_rows": [],
  "monthly_labor_cost": {
    "monthly_total": 0,
    "message": "근무 스케줄/시급 데이터 연동 전입니다."
  }
}
```

---

## 4) 점장 등록 (점장 ID 발급 포함)

- `POST /owner/home/branches/{branch_id}/manager`

### Request Body A: 기존 회원을 바로 점장 배정

```json
{
  "manager_user_id": 25
}
```

### Request Body B: 이름/번호로 점장 사전 등록 (권장)

```json
{
  "manager_name": "이사라",
  "manager_phone_number": "01033333333"
}
```

### Request Body C: 번호로 기존 점장 계정 검색 후 배정

```json
{
  "manager_phone_number": "01033333333"
}
```

### Response Body (200) - 사전등록만 된 경우

```json
{
  "branch_id": 10,
  "action": "pre_registered",
  "manager": null,
  "registration": {
    "registration_id": 101,
    "manager_name": "이사라",
    "manager_phone_number": "01033333333",
    "status": "pre_registered",
    "linked_user_id": null,
    "created_at": "2026-03-05T02:00:00Z"
  }
}
```

### Response Body (200) - 사전등록 + 계정 자동연결

```json
{
  "branch_id": 10,
  "action": "pre_registered_and_linked",
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "registration": {
    "registration_id": 101,
    "manager_name": "이사라",
    "manager_phone_number": "01033333333",
    "status": "linked",
    "linked_user_id": 25,
    "created_at": "2026-03-05T02:00:00Z"
  }
}
```

### Response Body (200) - 기존 회원 배정

```json
{
  "branch_id": 10,
  "action": "assigned_existing_user",
  "manager": {
    "user_id": 25,
    "full_name": "이사라",
    "phone_number": "01033333333",
    "approval_status": "approved_by_owner"
  },
  "registration": null
}
```

---

## 5) 점장 삭제 (현재 배정된 점장 삭제)

- `DELETE /owner/home/branches/{branch_id}/manager`

### Request Body

없음

### Response Body (200)

```json
{
  "branch_id": 10,
  "removed_manager_user_id": 25,
  "removed_registration_id": null,
  "message": "Manager assignment removed"
}
```

---

## 6) 점장 사전등록 ID 삭제

- `DELETE /owner/home/branches/{branch_id}/manager-registrations/{registration_id}`

### Request Body

없음

### Response Body (200)

```json
{
  "branch_id": 10,
  "removed_manager_user_id": 25,
  "removed_registration_id": 101,
  "message": "Manager registration deleted"
}
```

---

## 점장 회원가입 시 인증 방법

경영주가 발급한 `registration_id`로 점장이 본인 인증을 진행할 수 있습니다.

- `POST /auth/signup/complete`

```json
{
  "role": "manager",
  "manager_registration_id": 101,
  "manager_phone_number": "01033333333"
}
```

인증 성공 시:

- 해당 점장 계정이 발급된 등록 ID와 연결됨
- 점포 점장으로 자동 배정됨
