# Push API Spec (Mobile App)

이 문서는 편의점 ERP Flutter 앱(iOS/Android) 푸시 연동의 최종 기준 문서다.  
목표는 아래 2가지를 동시에 만족하는 것이다.

- 푸시 탭 시 항상 **안전하게 화면 이동**한다. (최소 탭/목록 화면 보장)
- 가능한 경우 `branch_id + entity_id`를 이용해 **상세 화면까지 진입**한다.

---

## 0) 구현 원칙

### 0-1. 라우팅 우선순위

1. `target_route`가 있으면 최우선 사용
2. 없으면 `type` 기반 fallback
3. 그것도 없으면 `target_role + tab` 기반 fallback
4. 최종 실패 시 기본 메인(`/manager` 또는 `/job-seeker`)

### 0-2. 상세 진입 원칙

- 상세 진입에는 최소 `entity_type`, `entity_id`가 필요
- 경영/점장 상세는 대부분 `branch_id`도 필요
- 상세 조회 실패 시 앱은 크래시 없이 목록 화면 유지

---

## 1) Device Token 등록/갱신

- Method: `POST`
- Path: `/api/v1/push/device-tokens`
- Auth: `Bearer access token`
- Purpose: 앱에서 발급받은 FCM 토큰을 사용자 계정에 upsert

### Request Body

```json
{
  "token": "fcm_device_token_string",
  "platform": "ios",
  "app_version": "1.0.0",
  "os_version": "17.4",
  "device_model": "iPhone15,2"
}
```

- `token` (string, required): FCM device token
- `platform` (string, required): `ios` | `android`
- `app_version` (string, optional): 앱 버전
- `os_version` (string, optional): OS 버전
- `device_model` (string, optional): 디바이스 모델

### Response

- `200 OK` 또는 `201 Created`

```json
{
  "ok": true,
  "device_token_id": 2345
}
```

---

## 2) 앱 알림함 API

## 2-1) 내 푸시 알림 목록 조회

- Method: `GET`
- Path: `/api/v1/push/notifications`
- Auth: `Bearer access token`

### Query Params

- `only_unread` (bool, optional, default=false)
- `page` (int, optional, default=1)
- `page_size` (int, optional, default=20, max=100)

### Response

```json
{
  "items": [
    {
      "notification_id": 101,
      "title": "[점포 명] 근로계약서가 왔습니다.",
      "body": "새로운 계약 요청을 확인해주세요.",
      "type": "manager_contract",
      "target_role": "manager",
      "target_route": "/manager?tab=0",
      "tab": "0",
      "recruitment_tab": null,
      "labor_cost_tab": null,
      "branch_id": "12",
      "entity_type": "contract_chat",
      "entity_id": "9876",
      "is_read": false,
      "read_at": null,
      "created_at": "2026-04-07T10:20:30Z"
    }
  ],
  "total_count": 12,
  "unread_count": 5,
  "page": 1,
  "page_size": 20
}
```

## 2-2) 푸시 알림 읽음 상태 변경

- Method: `PATCH`
- Path: `/api/v1/push/notifications/{notification_id}/read`
- Auth: `Bearer access token`

### Request Body

```json
{
  "is_read": true
}
```

### Response

```json
{
  "notification_id": 101,
  "is_read": true,
  "read_at": "2026-04-07T10:21:10Z"
}
```

## 2-3) 푸시 알림 삭제

- Method: `DELETE`
- Path: `/api/v1/push/notifications/{notification_id}`
- Auth: `Bearer access token`

### Response

```json
{
  "deleted": true,
  "notification_id": 101
}
```

## 2-4) 푸시 테스트 알림 생성 (개발/테스트)

- Method: `POST`
- Path: `/api/v1/push/notifications/test`
- Auth: `Bearer access token`
- Purpose: 앱 라우팅/상세 진입 QA

### Request Body

```json
{
  "title": "[점포 명] 근로계약서가 왔습니다.",
  "body": "새로운 계약 요청을 확인해주세요.",
  "type": "manager_contract",
  "target_role": "manager",
  "target_route": "/manager?tab=0",
  "branch_id": "12",
  "entity_type": "contract_chat",
  "entity_id": "9876"
}
```

---

## 3) FCM Data Payload 규격 (Server -> App)

앱은 payload의 `data`를 기준으로 라우팅/상세 진입을 수행한다.

### 3-1) 필드 정의

- `type` (string, required): 알림 분류 코드
- `target_role` (string, optional): `manager` | `owner` | `job_seeker`
- `target_route` (string, optional): 앱 내부 이동 경로 (최우선)
- `tab` (string/int, optional): 메인 탭 인덱스
- `recruitment_tab` (string/int, optional): 구인 탭 인덱스
- `labor_cost_tab` (string/int, optional): 인건비 탭 인덱스
- `branch_id` (string/int, strongly recommended): 점포 식별자
- `entity_type` (string, strongly recommended): 상세 리소스 타입
- `entity_id` (string/int, strongly recommended): 상세 리소스 ID
- `notification_id` (string/int, optional): 앱 알림함 row 식별자

### 3-2) 최소 권장 payload

```json
{
  "type": "recruitment_application",
  "target_role": "manager",
  "target_route": "/manager?tab=4&recruitmentTab=1",
  "branch_id": "12",
  "entity_type": "recruitment_application",
  "entity_id": "345"
}
```

---

## 4) 앱 라우팅 규칙

### 4-1) target_route 우선

- `/manager?tab=4&recruitmentTab=1`
- `/job-seeker?tab=3`

### 4-2) fallback 매핑(type 기반)

- `manager_alert`, `manager_contract`, `manager_notice` -> `/manager?tab=0`
- `manager_recruitment`, `recruitment_application` -> `/manager?tab=4&recruitmentTab=1`
- `job_seeker_recruitment` -> `/job-seeker?tab=0`
- `job_seeker_application` -> `/job-seeker?tab=1`
- `job_seeker_contract` -> `/job-seeker?tab=3`

### 4-3) 상세 진입 규칙

- 앱은 먼저 메인/탭 이동 후 상세 진입 시도
- 상세 진입 조건:
  - `entity_type` + `entity_id` 존재
  - 경영/점장 도메인은 `branch_id` 존재
- 조건 미충족 시 목록 화면에서 종료 (정상 동작)

---

## 5) FCM HTTP v1 발송 예시

```json
{
  "message": {
    "token": "fcm_device_token_string",
    "notification": {
      "title": "내 채용 게시글에 지원한 지원자가 있습니다.",
      "body": "홍길동님이 지원했습니다."
    },
    "data": {
      "type": "recruitment_application",
      "target_role": "manager",
      "target_route": "/manager?tab=4&recruitmentTab=1",
      "branch_id": "12",
      "entity_type": "recruitment_application",
      "entity_id": "345",
      "notification_id": "7788"
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "default"
        }
      }
    },
    "android": {
      "priority": "high"
    }
  }
}
```

---

## 6) 알림 타입별 권장 payload

### 6-1) 계약 요청 전송 시 (사업장 -> 근로자)

- 트리거: `PATCH /contract-chats/{contract_id}/document` with `action=send_to_worker`
- 수신자: `worker_user_id`
- title: `[{branch.name}] 근로계약서가 왔습니다.`
- body: `새로운 계약 요청을 확인해주세요.`
- type: `job_seeker_contract`
- target_route: `/job-seeker?tab=3`
- entity_type: `contract_chat`
- entity_id: `{contract_id}`
- branch_id: `{branch_id}`

### 6-2) 계약 완료 시 (근로자 -> 사업장)

- 트리거: `PATCH /contract-chats/{contract_id}/document` with `action=complete`
- 수신자: `owner_user_id`, `manager_user_id`
- title: `[{worker_name}] 근로 계약 완료되었습니다.`
- body: `작성 완료된 근로계약서를 확인해주세요.`
- type: `manager_contract`
- target_route: `/manager?tab=0`
- entity_type: `contract_chat`
- entity_id: `{contract_id}`
- branch_id: `{branch_id}`

### 6-3) 지원자 발생 시 (근로자 지원 -> 공고 작성자)

- 트리거: `POST /worker/recruitment/postings/{posting_id}/applications`
- 수신자: `recruitment_posts.created_by_user_id`
- title: `내 채용 게시글에 지원한 지원자가 있습니다.`
- body: `{지원자명}님이 지원했습니다.`
- type: `recruitment_application`
- target_route: `/manager?tab=4&recruitmentTab=1`
- entity_type: `recruitment_application`
- entity_id: `{application_id}`
- branch_id: `{branch_id}`

---

## 7) 서버 구현 체크리스트

- 사용자 1:N 디바이스 토큰 관리 (멀티 디바이스)
- 토큰 무효(`UNREGISTERED`) 즉시 비활성 처리
- 알림 저장 시 `type`, `target_route`, `branch_id`, `entity_type`, `entity_id` 저장
- 푸시 발송 실패와 앱 내 알림 저장 실패를 분리 로깅
- 상세 진입 필요한 이벤트는 `branch_id + entity_type + entity_id`를 필수화
- 앱 알림함 API 운영:
  - `GET /push/notifications`
  - `PATCH /push/notifications/{notification_id}/read`
  - `DELETE /push/notifications/{notification_id}`
  - `POST /push/notifications/test`
