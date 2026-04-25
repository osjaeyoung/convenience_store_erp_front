# 경영주 홈 API 스펙

기본 prefix: `/api/v1`

## 인증

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `/owner/home/**`는 `user_profiles.role == owner` 사용자만 호출 가능

---

## 1) 경영주 점포 목록

- `GET /owner/home/branches`

### Response Body (200)

```json
{
  "items": [
    {
      "id": 10,
      "name": "나눔 강남점",
      "code": "AB12CD34",
      "review_status": "approved",
      "review_note": null,
      "manager_user_id": 25,
      "is_open_for_manager": false,
      "created_at": "2026-03-05T00:00:00Z"
    }
  ]
}
```

---

## 2) 경영주 점포 추가

- `POST /owner/home/branches`

### Request Body

```json
{
  "branch_name": "나눔 서초점",
  "branch_code": "SEOCHO01"
}
```

- `branch_code` 미전달 시 서버가 8자리 코드를 자동 생성

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

## 3) 점포 상세

- `GET /owner/home/branches/{branch_id}`
- 문서 정본(canonical) 응답 shape는 아래 1개로 고정

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
    "monthly_total": 9157430,
    "message": "2026.03 급여명세 기준 인건비입니다."
  }
}
```

---

## 4) 점장 등록 요청 목록

- `GET /owner/home/branches/{branch_id}/manager-registrations`

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
    }
  ]
}
```

---

## 5) 점장 등록 (사전등록)

- `POST /owner/home/branches/{branch_id}/manager`

### Request Body

```json
{
  "manager_name": "이사라",
  "manager_phone_number": "01033333333"
}
```

### Response Body (200)

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

---

## 6) 채용 현황 조회

- `GET /owner/home/branches/{branch_id}/recruitment-status`
- 홈 대시보드와 구인 모듈이 동일 데이터를 보도록 아래 기준으로 집계
  - `application_count`: 해당 지점의 게시된 공고(`published`) 지원 건수
  - `today_applicants_count`: 오늘 접수된 지원 건수
  - `new_applicant_chat_count`: `GET /chats?branch_id={branch_id}`에서 현재 로그인 경영주/점장에게 실제로 보이는 채팅방 수
    - 미읽음 메시지 수가 아니라 채팅방 개수입니다.
    - 삭제/숨김 처리된 채팅방은 제외합니다.
    - 계약 문서 카드 메시지는 마지막 메시지/미읽음 수에는 반영되지만, 이 카운트는 한 채팅방당 1건만 셉니다.
  - `active_postings_count`: 현재 게시중(`published`) 공고 수
- 프론트는 홈 카드의 `새로운 지원자 채팅` 표시를 채팅 탭과 동일하게 맞추기 위해 `GET /chats?branch_id={branch_id}` 목록 개수를 우선 사용합니다. 이 API의 `new_applicant_chat_count`도 같은 기준으로 내려와야 합니다.

### Response Body (200)

```json
{
  "application_count": 5,
  "today_applicants_count": 2,
  "new_applicant_chat_count": 2,
  "active_postings_count": 2,
  "updated_at": "2026-09-11T08:00:00Z"
}
```

---

## 7) 점포 알림 목록

- `GET /owner/home/branches/{branch_id}/alerts`
- 홈 화면의 '오늘의 알림' 영역에 노출될 알림(운영/상태 관련 알림) 목록을 반환합니다.
- (참고) '채용 현황' 영역의 알림(새로운 지원자 등)은 이 API가 아닌 `6) 채용 현황 조회`에서 내려주는 데이터로 보여집니다.
- 기획된 '오늘의 알림' 예시:
  - `새로운 인건비 절감 포인트가 있습니다.`
  - `[알바생 명] 근로 계약 완료`
  - `[알바생 명] 연소득자 근로 계약 완료`
  - `[알바생 명] 친권자 동의서 완료`

### Response Body (200)

```json
{
  "items": [
    {
      "alert_id": 9001,
      "title": "[김알바] 근로 계약 완료", // 이 필드가 화면에 그대로 노출됨
      "content": "김알바님의 근로 계약서 작성이 완료되었습니다.",
      "priority": "high",
      "is_open": true,
      "created_at": "2026-09-11T09:00:00Z"
    }
  ]
}
```

---

## 8) 점포 알림 읽음 토글

- `PATCH /owner/home/branches/{branch_id}/alerts/{alert_id}`

### Request Body

```json
{
  "is_open": false
}
```

### Response Body (200)

```json
{
  "alert_id": 9001,
  "is_open": false
}
```

---

## 9) 오늘 근무자 현황 조회

- `GET /owner/home/branches/{branch_id}/today-workers?date=2026-09-11`
- `WorkScheduleEntry` 기반으로 30분 슬롯으로 확장된 행을 반환

### Response Body (200)

```json
{
  "date": "2026-09-11",
  "rows": [
    {
      "status_id": 7001,
      "work_date": "2026-09-11",
      "time_label": "09:00",
      "worker_name": "이시현",
      "status": "done",
      "memo": null,
      "updated_at": "2026-09-11T09:20:00Z"
    }
  ]
}
```

---

## 10) 오늘 근무자 상태/메모 저장

- `PUT /owner/home/branches/{branch_id}/today-workers/status`

### Request Body

```json
{
  "work_date": "2026-09-11",
  "time_label": "09:00",
  "worker_name": "이시현",
  "status": "done",
  "memo": "지각 5분"
}
```

허용 상태값:
- `scheduled`
- `done`
- `absent`
- `unset`
- `planned` (`scheduled`로 변환)
- `pending` (`unset`으로 변환)

### Response Body (200)

```json
{
  "status_id": 7001,
  "work_date": "2026-09-11",
  "time_label": "09:00",
  "worker_name": "이시현",
  "status": "done",
  "memo": "지각 5분",
  "updated_at": "2026-09-11T09:20:00Z"
}
```

---

## 11) 오늘 근무자 메모 삭제

- `DELETE /owner/home/branches/{branch_id}/today-workers/{status_id}/memo`

### Response Body (200)

```json
{
  "status_id": 7001,
  "memo": null
}
```

---

## 12) 점장 해제

- `DELETE /owner/home/branches/{branch_id}/manager`

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

## 13) 점장 등록 요청 삭제

- `DELETE /owner/home/branches/{branch_id}/manager-registrations/{registration_id}`

### Response Body (200)

```json
{
  "branch_id": 10,
  "removed_manager_user_id": 25,
  "removed_registration_id": 101,
  "message": "Manager registration deleted"
}
```
# 경영주 홈 API 스펙

기본 prefix: `/api/v1`

## 인증

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `/owner/home/**`는 `user_profiles.role == owner` 사용자만 호출 가능

---

## 1) 경영주 점포 목록

- `GET /owner/home/branches`

### Response Body (200)

```json
{
  "items": [
    {
      "id": 10,
      "name": "나눔 강남점",
      "code": "AB12CD34",
      "review_status": "approved",
      "review_note": null,
      "manager_user_id": 25,
      "is_open_for_manager": false,
      "created_at": "2026-03-05T00:00:00Z"
    }
  ]
}
```

---

## 2) 경영주 점포 추가

- `POST /owner/home/branches`

### Request Body

```json
{
  "branch_name": "나눔 서초점",
  "branch_code": "SEOCHO01"
}
```

- `branch_code` 미전달 시 서버가 8자리 코드를 자동 생성

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

## 3) 점포 상세

- `GET /owner/home/branches/{branch_id}`
- 문서 정본(canonical) 응답 shape는 아래 1개로 고정

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
    "monthly_total": 9157430,
    "message": "2026.03 급여명세 기준 인건비입니다."
  }
}
```

---

## 4) 점장 등록 요청 목록

- `GET /owner/home/branches/{branch_id}/manager-registrations`

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
    }
  ]
}
```

---

## 5) 점장 등록 (사전등록)

- `POST /owner/home/branches/{branch_id}/manager`

### Request Body

```json
{
  "manager_name": "이사라",
  "manager_phone_number": "01033333333"
}
```

### Response Body (200)

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

---

## 6) 채용 현황 조회

- `GET /owner/home/branches/{branch_id}/recruitment-status`
- 홈 대시보드와 구인 모듈이 동일 데이터를 보도록 아래 기준으로 집계
  - `application_count`: 해당 지점의 게시된 공고(`published`) 지원 건수
  - `today_applicants_count`: 오늘 접수된 지원 건수
  - `new_applicant_chat_count`: `GET /chats?branch_id={branch_id}`에서 현재 로그인 경영주/점장에게 실제로 보이는 채팅방 수
    - 미읽음 메시지 수가 아니라 채팅방 개수입니다.
    - 삭제/숨김 처리된 채팅방은 제외합니다.
    - 계약 문서 카드 메시지는 마지막 메시지/미읽음 수에는 반영되지만, 이 카운트는 한 채팅방당 1건만 셉니다.
  - `active_postings_count`: 현재 게시중(`published`) 공고 수
- 프론트는 홈 카드의 `새로운 지원자 채팅` 표시를 채팅 탭과 동일하게 맞추기 위해 `GET /chats?branch_id={branch_id}` 목록 개수를 우선 사용합니다. 이 API의 `new_applicant_chat_count`도 같은 기준으로 내려와야 합니다.

### Response Body (200)

```json
{
  "application_count": 5,
  "today_applicants_count": 2,
  "new_applicant_chat_count": 2,
  "active_postings_count": 2,
  "updated_at": "2026-09-11T08:00:00Z"
}
```

---

## 7) 점포 알림 목록

- `GET /owner/home/branches/{branch_id}/alerts`
- 홈 화면의 '오늘의 알림' 영역에 노출될 알림(운영/상태 관련 알림) 목록을 반환합니다.
- (참고) '채용 현황' 영역의 알림(새로운 지원자 등)은 이 API가 아닌 `6) 채용 현황 조회`에서 내려주는 데이터로 보여집니다.
- 기획된 '오늘의 알림' 예시:
  - `새로운 인건비 절감 포인트가 있습니다.`
  - `[알바생 명] 근로 계약 완료`
  - `[알바생 명] 연소득자 근로 계약 완료`
  - `[알바생 명] 친권자 동의서 완료`

### Response Body (200)

```json
{
  "items": [
    {
      "alert_id": 9001,
      "title": "[김알바] 근로 계약 완료", // 이 필드가 화면에 그대로 노출됨
      "content": "김알바님의 근로 계약서 작성이 완료되었습니다.",
      "priority": "high",
      "is_open": true,
      "created_at": "2026-09-11T09:00:00Z"
    }
  ]
}
```

---

## 8) 점포 알림 읽음 토글

- `PATCH /owner/home/branches/{branch_id}/alerts/{alert_id}`

### Request Body

```json
{
  "is_open": false
}
```

### Response Body (200)

```json
{
  "alert_id": 9001,
  "is_open": false
}
```

---

## 9) 오늘 근무자 현황 조회

- `GET /owner/home/branches/{branch_id}/today-workers?date=2026-09-11`
- `WorkScheduleEntry` 기반으로 30분 슬롯으로 확장된 행을 반환

### Response Body (200)

```json
{
  "date": "2026-09-11",
  "rows": [
    {
      "status_id": 7001,
      "work_date": "2026-09-11",
      "time_label": "09:00",
      "worker_name": "이시현",
      "status": "done",
      "memo": null,
      "updated_at": "2026-09-11T09:20:00Z"
    }
  ]
}
```

---

## 10) 오늘 근무자 상태/메모 저장

- `PUT /owner/home/branches/{branch_id}/today-workers/status`

### Request Body

```json
{
  "work_date": "2026-09-11",
  "time_label": "09:00",
  "worker_name": "이시현",
  "status": "done",
  "memo": "지각 5분"
}
```

허용 상태값:
- `scheduled`
- `done`
- `absent`
- `unset`
- `planned` (`scheduled`로 변환)
- `pending` (`unset`으로 변환)

### Response Body (200)

```json
{
  "status_id": 7001,
  "work_date": "2026-09-11",
  "time_label": "09:00",
  "worker_name": "이시현",
  "status": "done",
  "memo": "지각 5분",
  "updated_at": "2026-09-11T09:20:00Z"
}
```

---

## 11) 오늘 근무자 메모 삭제

- `DELETE /owner/home/branches/{branch_id}/today-workers/{status_id}/memo`

### Response Body (200)

```json
{
  "status_id": 7001,
  "memo": null
}
```

---

## 12) 점장 해제

- `DELETE /owner/home/branches/{branch_id}/manager`

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

## 13) 점장 등록 요청 삭제

- `DELETE /owner/home/branches/{branch_id}/manager-registrations/{registration_id}`

### Response Body (200)

```json
{
  "branch_id": 10,
  "removed_manager_user_id": 25,
  "removed_registration_id": 101,
  "message": "Manager registration deleted"
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
    "monthly_total": 9157430,
    "message": "2026.03 급여명세 기준 인건비입니다."
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

> 서버는 `today-workers`를 별도 테이블이 아닌 `staff-management` 스케줄(`WorkScheduleEntry`)에서 직접 만들어 반환합니다.  
> 따라서 `GET /staff-management/branches/{branch_id}/schedules/day`와 동일한 근무 데이터가 30분 슬롯 단위로 노출됩니다.

#### Request Body
없음

#### Response Body (200)
```json
{
  "date": "2026-09-11",
  "rows": [
    {
      "status_id": 7001,
      "work_date": "2026-09-11",
      "time_label": "09:00",
      "worker_name": "이시현",
      "memo": null,
      "status": "scheduled",
      "updated_at": "2026-09-11T09:20:00Z"
    },
    {
      "status_id": 7001,
      "work_date": "2026-09-11",
      "time_label": "09:30",
      "worker_name": "이시현",
      "memo": null,
      "status": "scheduled",
      "updated_at": "2026-09-11T09:20:00Z"
    }
  ]
}
```

### 9-4) 오늘 근무 상태 변경
- `PUT /owner/home/branches/{branch_id}/today-workers/status`

#### Request Body
```json
{
  "work_date": "2026-09-11",
  "time_label": "09:00",
  "worker_name": "이시현",
  "status": "done",
  "memo": "지각 5분"
}
```

#### Response Body (200)
```json
{
  "status_id": 7001,
  "work_date": "2026-09-11",
  "time_label": "09:00",
  "worker_name": "이시현",
  "status": "done",
  "memo": "지각 5분",
  "updated_at": "2026-09-11T09:20:00Z"
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
    "monthly_total": 9157430,
    "message": "2026.03 급여명세 기준 인건비입니다."
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

> 서버는 `today-workers`를 별도 테이블이 아닌 `staff-management` 스케줄(`WorkScheduleEntry`)에서 직접 만들어 반환합니다.  
> 따라서 `GET /staff-management/branches/{branch_id}/schedules/day`와 동일한 근무 데이터가 30분 슬롯 단위로 노출됩니다.

#### Request Body

없음

#### Response Body (200)

```json
{
  "date": "2026-09-11",
  "rows": [
    {
      "status_id": 7001,
      "work_date": "2026-09-11",
      "time_label": "09:00",
      "worker_name": "이시현",
      "memo": null,
      "status": "done",
      "updated_at": "2026-09-11T09:20:00Z"
    },
    {
      "status_id": 7002,
      "work_date": "2026-09-11",
      "time_label": "09:30",
      "worker_name": "이시현",
      "memo": null,
      "status": "done",
      "updated_at": "2026-09-11T09:20:00Z"
    },
    {
      "status_id": 7010,
      "work_date": "2026-09-11",
      "time_label": "13:00",
      "worker_name": "이시현",
      "memo": null,
      "status": "unset",
      "updated_at": "2026-09-11T09:20:00Z"
    }
  ]
}
```

### 9-4) 오늘 근무 상태 변경

- `PUT /owner/home/branches/{branch_id}/today-workers/status`

#### Request Body

```json
{
  "work_date": "2026-09-11",
  "time_label": "09:00",
  "worker_name": "이시현",
  "status": "done",
  "memo": "지각 5분"
}
```

#### Response Body (200)

```json
{
  "status_id": 7001,
  "work_date": "2026-09-11",
  "time_label": "09:00",
  "worker_name": "이시현",
  "status": "done",
  "memo": "지각 5분",
  "updated_at": "2026-09-11T09:20:00Z"
}
```

허용 상태값:

- `scheduled`: 근무예정
- `done`: 근무완료
- `absent`: 결근
- `unset`: 미정
- `planned`: (`scheduled`로 자동 변환)
- `pending`: (`unset`으로 자동 변환)

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
    "monthly_total": 9157430,
    "message": "2026.03 급여명세 기준 인건비입니다."
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

- 이 값은 점장 회원가입 시 계정에 저장된 `full_name` + `phone_number` 와 매칭 기준으로 사용됩니다.
- 즉, 사업주는 실제 점장 본인이 회원가입에 사용할 이름/전화번호로 등록해야 하며, 다르면 점장 `signup/complete` 또는 점장 가입 API가 실패합니다.

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
