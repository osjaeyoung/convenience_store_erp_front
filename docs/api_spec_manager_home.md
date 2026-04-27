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
        "application_count": 2,
        "today_applicants_count": 2,
        "new_applicant_chat_count": 2,
        "active_postings_count": 2,
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
    "application_count": 2,
    "today_applicants_count": 2,
    "new_applicant_chat_count": 2,
    "active_postings_count": 2,
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
- 홈 대시보드와 구인 모듈이 동일 데이터를 보도록 아래 기준으로 집계
  - `application_count`: 해당 지점의 게시된 공고(`published`) 지원 건수
  - `today_applicants_count`: 오늘 접수된 지원 건수
  - `new_applicant_chat_count`: 채용 문의/계약 통합 채팅방 중 현재 로그인 사용자 기준 **읽지 않은 메시지가 있는 채팅방 수**
  - `active_postings_count`: 현재 게시중(`published`) 공고 수
- 프론트는 홈 카드의 `새로운 지원자 채팅` 표시를 위해 `GET /chats?branch_id={branch_id}` 응답 중 `unread_count > 0`인 채팅방 개수를 우선 사용합니다. 이 API의 `new_applicant_chat_count`도 같은 기준으로 내려와야 합니다.
- 채팅 상세 진입 후 `PATCH /chats/{chat_id}/read`가 성공하면 해당 사용자의 `GET /chats` 응답에서 해당 채팅방 `unread_count`는 `0`이어야 하며, 홈 `new_applicant_chat_count`에서도 제외되어야 합니다.

### Request Body
없음

### Response Body (200)
```json
{
  "application_count": 2,
  "today_applicants_count": 2,
  "new_applicant_chat_count": 2,
  "active_postings_count": 2,
  "updated_at": "2026-09-11T08:00:00Z"
}
```

---

## 5) 알림 목록 조회

- `GET /manager/home/branches/{branch_id}/alerts`
- 홈 화면의 '오늘의 알림' 영역에 노출될 알림(운영/상태 관련 알림) 목록을 반환합니다.
- (참고) '채용 현황' 영역의 알림(새로운 지원자 등)은 이 API가 아닌 `4) 채용 현황 조회`에서 내려주는 데이터로 보여집니다.
- 기획된 '오늘의 알림' 예시:
  - `새로운 인건비 절감 포인트가 있습니다.`
  - `[알바생 명] 근로 계약 완료`
  - `[알바생 명] 연소득자 근로 계약 완료`
  - `[알바생 명] 친권자 동의서 완료`
  
### Request Body
없음

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

> 서버는 `today-workers`를 별도 테이블이 아닌 `staff-management` 스케줄(`WorkScheduleEntry`)에서 직접 만들어 반환합니다.  
> 따라서 `GET /staff-management/branches/{branch_id}/schedules/day`와 동일한 근무 데이터가 30분 슬롯 단위로 노출됩니다.

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
      "status": "done",
      "memo": null,
      "updated_at": "2026-09-11T09:10:00Z"
    },
    {
      "status_id": 7002,
      "work_date": "2026-09-11",
      "time_label": "09:30",
      "worker_name": "이시현",
      "status": "done",
      "memo": null,
      "updated_at": "2026-09-11T09:10:00Z"
    },
    {
      "status_id": 7010,
      "work_date": "2026-09-11",
      "time_label": "13:00",
      "worker_name": "이시현",
      "status": "unset",
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

허용 상태값:

- `scheduled`: 근무예정
- `done`: 근무완료
- `absent`: 결근
- `unset`: 미정
- `planned`: (`scheduled`로 자동 변환)
- `pending`: (`unset`으로 자동 변환)

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
