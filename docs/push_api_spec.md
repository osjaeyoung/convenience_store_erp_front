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
- 단, `inquiry`, `owner_certification_result`처럼 **사용자 계정 기준 이벤트**는 `branch_id` 없이도 라우팅 가능하다.
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

- `unread_count`는 `only_unread` 필터와 무관하게 현재 사용자 전체 알림 중 `is_read=false`인 개수입니다.
- 프론트 상단 알림 아이콘은 `unread_count > 0`일 때 활성 상태로 표시하므로, 알림함에 미읽음 항목이 있으면 반드시 1 이상으로 내려와야 합니다.
- `only_unread=true`일 때 `items`는 반드시 `is_read=false` 항목만 내려줍니다. 프론트는 상단 알림 아이콘 동기화를 위해 `GET /push/notifications?only_unread=true&page_size=20`을 호출합니다.
- `only_unread=true` 응답에서 `items`가 1개 이상이면 `unread_count`도 반드시 1 이상이어야 합니다. 반대로 미읽음 항목이 없으면 `items=[]`, `unread_count=0`이어야 합니다.
- `unread_count`는 전체 알림 수, 전체 채팅 메시지 수, 채팅방 수가 아니라 오직 앱 알림함 row 중 `is_read=false`인 row 수입니다.

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

- 읽음 처리 성공 후 `GET /me/notifications` 또는 `GET /push/notifications`의 같은 항목은 `is_read=true`로 내려와야 하며, `unread_count`에서 제외되어야 합니다.
- 채팅방 상세 진입 또는 `PATCH /chats/{chat_id}/read`는 푸시 알림 row의 `is_read`를 자동으로 변경하지 않습니다. 상단 알림 아이콘은 사용자가 알림함에서 해당 알림을 직접 확인하거나 이 읽음 API를 호출했을 때만 사라집니다.
- 즉, **채팅 메시지 읽음 상태**와 **앱 알림함 알림 읽음 상태**는 서로 다른 상태입니다.

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
- `chat_id` (string/int, optional): 채팅 알림일 때 채팅방 ID. 채팅 상세 진입 안정성을 위해 `entity_id`와 같은 값으로 함께 내려주는 것을 권장
- `employee_id` (string/int, optional): 경영주/점장 채팅 상세 진입 보조값. `branch_id`와 함께 있으면 채팅방 재조회 fallback에 사용 가능
- `counterparty_name` 또는 `employee_name` (string, optional): 채팅 상세 상단 제목 fallback
- `profile_image_url` (string, optional): 채팅 상세 상대방 프로필 이미지 fallback
- `notification_id` (string/int, optional): 앱 알림함 row 식별자
- `title`, `body` (string, recommended): foreground/data fallback 표시용 문구. 서버는 FCM `notification`과 `data` 양쪽에 포함합니다.

### 3-1-1) Foreground 알림 표시 조건

- 앱이 실행 중(foreground)이어도 채팅 알림이 사용자에게 보여야 합니다.
- 서버는 채팅 FCM에 `notification.title/body` 또는 data `title/body` 중 하나를 반드시 포함합니다.
- data-only로 발송하더라도 프론트 fallback을 위해 최소 `type`, `entity_type`, `entity_id`, `chat_id`를 포함합니다.
- 채팅 알림 row는 FCM 발송 전후 지연 없이 생성되어야 합니다. 프론트는 foreground 수신 직후 unread count를 즉시/지연 재조회하므로, 짧은 시간 안에 `GET /push/notifications?only_unread=true`에 반영되어야 합니다.

예시 `entity_type`:
- `contract_chat`
- `recruitment_chat`
- `chat`
- `recruitment_application`
- `inquiry`
- `owner_certification`

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
- `/job-seeker`

### 4-2) fallback 매핑(type 기반)

- `manager_alert`, `manager_contract`, `manager_notice` -> `/manager?tab=0`
- `manager_recruitment`, `recruitment_application` -> `/manager?tab=4&recruitmentTab=1`
- `recruitment_chat`, `chat_message` -> 경영주/점장 `/manager?tab=4&recruitmentTab=3`, 근로자 `/job-seeker?tab=3`
- `owner_certification_result` -> `/manager?tab=0`
- `user_inquiry_answer` -> `target_role=owner|manager`면 `/manager?tab=0`, `target_role=job_seeker`면 `/job-seeker`
- `job_seeker_recruitment` -> `/job-seeker?tab=0`
- `job_seeker_application` -> `/job-seeker?tab=1`
- `job_seeker_contract` -> `/job-seeker?tab=3`

### 4-3) 상세 진입 규칙

- 앱은 먼저 메인/탭 이동 후 상세 진입 시도
- 상세 진입 조건:
  - `entity_type` + `entity_id` 존재
  - 경영/점장 도메인은 `branch_id` 존재
- 채용 통합 채팅 상세 진입 조건:
  - `entity_type=recruitment_chat` 또는 `entity_type=chat`
  - `entity_id={chat_id}` 또는 `chat_id={chat_id}`
  - 경영주/점장 수신이면 `branch_id` 필수, `employee_id` 권장
  - 근로자 수신이면 `chat_id`만으로 상세 진입 가능
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

### 6-4) 채용 통합 채팅 메시지 전송 시

- 트리거: `POST /chats/{chat_id}/messages`
- 수신자: 해당 채팅방 상대방 user_id
- title: `[{branch.name}] 새 채팅 메시지`
- body: `{message.text}` (빈 값이면 `구인채용 채팅에 새 메시지가 도착했습니다.`)
- type: `recruitment_chat`
- entity_type: `recruitment_chat`
- entity_id: `{chat_id}`
- chat_id: `{chat_id}` (`entity_id`와 같은 값, 상세 진입 안정성을 위해 필수에 준해 포함)
- branch_id: `{branch_id}`
- employee_id: `{employee_id}` (경영주/점장 수신 시 권장)
- counterparty_name / employee_name: `{상대방 이름}` (선택)
- profile_image_url: `{상대방 프로필 이미지 URL}` (선택)
- 경영주/점장 수신:
  - target_role: `manager` 또는 `owner`
  - target_route: `/manager?tab=4&recruitmentTab=3`
  - recruitment_tab: `3`
- 근로자 수신:
  - target_role: `worker` 또는 `job_seeker`
  - target_route: `/job-seeker?tab=3`
- 앱이 foreground 상태여도 알림이 떠야 하므로 FCM `notification.title/body` 또는 data `title/body` 중 하나는 반드시 포함합니다.
- data-only 전송 시에도 프론트 fallback을 위해 `type=recruitment_chat`, `entity_type=recruitment_chat`, `entity_id={chat_id}`, `chat_id={chat_id}`를 포함해야 합니다.
- 앱 알림함 row(`GET /me/notifications` 또는 `GET /push/notifications`)에도 위 라우팅 payload 필드를 동일하게 저장/반환해야 합니다. 알림함에서 클릭해도 푸시 클릭과 동일하게 채팅 상세로 이동해야 합니다.
- 알림함의 `unread_count`는 새 채팅 알림 row 생성 직후 증가해야 하며, 프론트 상단 알림 아이콘은 `unread_count > 0`이면 활성 아이콘을 표시합니다.
- 채팅 상세에서 메시지를 확인해 `PATCH /chats/{chat_id}/read`가 호출되어도, 앱 알림함 row의 `is_read`는 자동으로 true 처리하지 않습니다. 사용자가 우측 상단 알림함에서 해당 알림을 확인해야 알림 badge가 사라집니다.
- `GET /push/notifications?only_unread=true`는 채팅 알림을 포함한 모든 미확인 알림만 반환해야 합니다. 채팅 알림 row가 남아 있으면 `unread_count`가 0이면 안 됩니다.
- Android 발송 시 `android.notification.channel_id`는 앱 매니페스트/로컬 채널과 같은 `high_importance_channel`을 사용합니다. 채널이 누락되면 Android 8+ 백그라운드 알림 표시가 누락될 수 있습니다.
- 서버는 채팅 메시지 푸시를 지연 큐에만 적재하지 않고 메시지 저장 직후 앱 알림 row 생성과 FCM 발송을 바로 시도합니다.

권장 payload 예시:

```json
{
  "type": "recruitment_chat",
  "target_role": "manager",
  "target_route": "/manager?tab=4&recruitmentTab=3",
  "tab": "4",
  "recruitment_tab": "3",
  "branch_id": "12",
  "employee_id": "88",
  "entity_type": "recruitment_chat",
  "entity_id": "101",
  "chat_id": "101",
  "counterparty_name": "김수민",
  "profile_image_url": "https://cdn.example.com/profiles/worker.png",
  "notification_id": "7788",
  "title": "[나눔 강남점] 새 채팅 메시지",
  "body": "지원서 보고 연락드립니다."
}
```

### 6-5) 관리자 문의 답변 등록/수정 시 (어드민 -> 문의 작성자)

- 트리거:
  - `POST /admin/inquiries/{inquiry_id}/answer`
  - `PATCH /admin/inquiries/{inquiry_id}/answer`
- 수신자: `user_inquiries.user_id`
- title: `문의하신 내용에 답변이 등록되었습니다.`
- body: `{inquiry_title}` 또는 `고객센터 답변을 확인해주세요.`
- type: `user_inquiry_answer`
- target_role:
  - 문의 작성자가 `owner` 또는 `manager`면 해당 role
  - 근로자/일반 유저면 `job_seeker`
- target_route:
  - `owner`, `manager` -> `/manager?tab=0`
  - `job_seeker` -> `/job-seeker`
- entity_type: `inquiry`
- entity_id: `{inquiry_id}`
- branch_id: 없음(선택)

권장 payload 예시:

```json
{
  "type": "user_inquiry_answer",
  "target_role": "job_seeker",
  "target_route": "/job-seeker",
  "entity_type": "inquiry",
  "entity_id": "501"
}
```

### 6-6) 사업주 인증 승인/반려 시 (어드민 -> 경영주)

- 트리거: `PATCH /admin/owner-certifications/{branch_id}`
- 수신자: 해당 `branches.owner_user_id`
- title:
  - 승인 시: `[점포명] 사업주 인증이 승인되었습니다.`
  - 반려 시: `[점포명] 사업주 인증이 반려되었습니다.`
- body:
  - 승인 시: `이제 점포 기능을 정상적으로 이용할 수 있습니다.`
  - 반려 시: `반려 사유를 확인 후 다시 신청해주세요.`
- type: `owner_certification_result`
- target_role: `owner`
- target_route: `/manager?tab=0`
- entity_type: `owner_certification`
- entity_id: `{branch_id}`
- branch_id: `{branch_id}`

권장 payload 예시:

```json
{
  "type": "owner_certification_result",
  "target_role": "owner",
  "target_route": "/manager?tab=0",
  "branch_id": "12",
  "entity_type": "owner_certification",
  "entity_id": "12"
}
```

---

## 7) 서버 구현 체크리스트

- 사용자 1:N 디바이스 토큰 관리 (멀티 디바이스)
- 토큰 무효(`UNREGISTERED`) 즉시 비활성 처리
- 알림 저장 시 `type`, `target_route`, `branch_id`, `entity_type`, `entity_id` 저장
- 푸시 발송 실패와 앱 내 알림 저장 실패를 분리 로깅
- 상세 진입 필요한 이벤트는 `branch_id + entity_type + entity_id`를 필수화
- 관리자 액션 기반 푸시 추가:
  - 문의 답변 등록/수정 시 문의 작성자에게 `user_inquiry_answer`
  - 사업주 인증 승인/반려 시 경영주에게 `owner_certification_result`
- 앱 알림함 API 운영:
  - `GET /push/notifications`
  - `PATCH /push/notifications/{notification_id}/read`
  - `DELETE /push/notifications/{notification_id}`
  - `POST /push/notifications/test`
