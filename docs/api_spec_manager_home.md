# 점장 홈 API 스펙

기본 prefix: `/api/v1`

## 인증

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `/manager/home/**`는 `user_profiles.role == manager` 사용자만 호출 가능

---

## 1) 점장 지점 권한 받기 (공유 ID 인증)

- `POST /manager/home/branches/join`

### Request Body
```json
{
  "manager_registration_id": 101,
  "manager_phone_number": "01033333333"
}
```

### Response Body (200)
```json
{
  "branch_id": 10,
  "branch_name": "나눔 강남점",
  "registration_id": 101,
  "status": "linked"
}
```

### 1-1) 이름+전화번호로 등록 점포 목록 조회

- `POST /manager/home/branches/lookup`

### Request Body
```json
{
  "manager_name": "홍길동",
  "manager_phone_number": "01033333333"
}
```

### Response Body (200)
```json
{
  "items": [
    {
      "registration_id": 101,
      "branch_id": 10,
      "branch_name": "나눔 강남점",
      "branch_code": "AB12CD34",
      "registration_status": "pre_registered",
      "linked_user_id": null,
      "created_at": "2026-09-11T09:00:00Z"
    }
  ]
}
```

### 1-2) 이름+전화번호 매칭 점포 일괄 적용

- `POST /manager/home/branches/join-bulk`

### Request Body
```json
{
  "manager_name": "홍길동",
  "manager_phone_number": "01033333333"
}
```

### Response Body (200)
```json
{
  "items": [
    {
      "registration_id": 101,
      "branch_id": 10,
      "branch_name": "나눔 강남점",
      "status": "linked",
      "result": "linked",
      "reason": null
    }
  ],
  "linked_count": 1,
  "failed_count": 0
}
```

---

## 2) 점장 홈 지점 목록

- `GET /manager/home/branches?date=2026-09-11`

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
      "review_status": "approved",
      "recruitment": {
        "waiting_interviews": 2,
        "new_applicants": 2,
        "new_contacts": 2,
        "updated_at": "2026-09-11T08:00:00Z"
      },
      "open_alert_count": 1,
      "today_worker_count": 6
    }
  ]
}
```

---

## 3) 점장 홈 지점 상세

- `GET /manager/home/branches/{branch_id}?date=2026-09-11`

### Request Body
없음

### Response Body (200)
```json
{
  "id": 10,
  "name": "나눔 강남점",
  "code": "AB12CD34",
  "review_status": "approved",
  "recruitment": {
    "waiting_interviews": 2,
    "new_applicants": 2,
    "new_contacts": 2,
    "updated_at": "2026-09-11T08:00:00Z"
  },
  "open_alert_count": 1,
  "today_worker_count": 6,
  "fetched_date": "2026-09-11",
  "fetched_at": "2026-09-11T09:00:00Z"
}
```

---

## 4) 채용 현황 조회

- `GET /manager/home/branches/{branch_id}/recruitment-status`

### Request Body
없음

### Response Body (200)
```json
{
  "waiting_interviews": 2,
  "new_applicants": 2,
  "new_contacts": 2,
  "updated_at": "2026-09-11T08:00:00Z"
}
```

---

## 5) 알림 목록 조회

- `GET /manager/home/branches/{branch_id}/alerts`

### Request Body
없음

### Response Body (200)
```json
{
  "items": [
    {
      "alert_id": 9001,
      "title": "퇴직금 발생",
      "content": "3개월 내 퇴직금 지급 대상자가 있습니다.",
      "priority": "high",
      "is_open": true,
      "created_at": "2026-09-11T09:00:00Z"
    }
  ]
}
```

---

## 6) 알림 펼침/닫힘

- `PATCH /manager/home/branches/{branch_id}/alerts/{alert_id}`

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

## 7) 오늘 근무자 현황 조회

- `GET /manager/home/branches/{branch_id}/today-workers?date=2026-09-11`

### Request Body
없음

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
      "status": "scheduled",
      "memo": null,
      "updated_at": "2026-09-11T09:10:00Z"
    }
  ]
}
```

---

## 8) 오늘 근무자 상태/메모 저장

- `PUT /manager/home/branches/{branch_id}/today-workers/status`

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

## 9) 오늘 근무자 메모 삭제

- `DELETE /manager/home/branches/{branch_id}/today-workers/{status_id}/memo`

### Request Body
없음

### Response Body (200)
```json
{
  "status_id": 7001,
  "memo": null
}
```

---

## 경영주도 가능한 동일 기능 API

근무 상태/메모 수정은 경영주도 동일하게 가능합니다.

- `GET /owner/home/branches/{branch_id}/recruitment-status`
- `GET /owner/home/branches/{branch_id}/alerts`
- `PATCH /owner/home/branches/{branch_id}/alerts/{alert_id}`
- `GET /owner/home/branches/{branch_id}/today-workers?date=YYYY-MM-DD`
- `PUT /owner/home/branches/{branch_id}/today-workers/status`
- `DELETE /owner/home/branches/{branch_id}/today-workers/{status_id}/memo`
