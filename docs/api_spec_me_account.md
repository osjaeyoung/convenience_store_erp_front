# 내 계정 정보 API (개인 공간)

기본 prefix: `/api/v1`

Figma 파일 `개인 공간`의 계정·설정 플로우에 맞춘 API입니다.  
전화번호 인증은 **Firebase에서만** 처리하고, 서버는 인증이 끝난 뒤 전달받은 전화번호 기준으로 계정을 조회/동기화합니다.

## Figma 화면 ↔ API

| 노드 ID | 화면명 | 서버 API |
|---------|--------|----------|
| 2634:16151 | 설정 (메뉴) | `GET /me/account` + 클라이언트 라우팅 |
| 2634:16115 | 내정보설정 (하위 메뉴) | 클라이언트 네비게이션 |
| 2634:16280 | 내 정보 설정 (이름·사용유형·전화·비밀번호) | `GET /me/account` |
| 2634:16329 | 내 정보 설정 (소셜, 비밀번호 행 없음) | `GET /me/account` + `has_password_login` |
| 2634:16196 | 비밀번호 변경 (본인 확인: 전화·이름) | Firebase 인증 후 `POST /auth/password/reset/by-phone` 또는 `PATCH /me/account` |
| 2634:16243 | 비밀번호 변경 (새 비밀번호) | `POST /me/account/password` |
| - | 전화번호 가입 여부 확인 | `GET /auth/phone-number-exists` |
| - | 공지사항 목록/상세 | `GET /me/notices`, `GET /me/notices/{notice_id}` |
| - | 문의하기 / 내 문의 보기 | `POST /me/inquiries`, `GET /me/inquiries`, `GET /me/inquiries/{inquiry_id}` |
| 2634:16082 | 로그아웃 확인 | 클라이언트에서 토큰 삭제 + `POST /auth/logout` 있으면 사용 |
| 2634:16384 | 탈퇴 확인 | `POST /me/account/withdraw` |

## 인증

- `Authorization: Bearer {access_token}`: `/me/**`
- 인증 불필요: `GET /auth/phone-number-exists`, `POST /auth/password/reset/by-phone`

---

## GET `/me/account`

### Response (200) 주요 필드

- `usage_type_label_ko`: Figma 사용 유형 (`owner` → `사업주`, `manager` → `점장`, `worker` → `근무자`)
- `role_label_ko`: 기존 표기 (`owner` → `경영주` 등)
- `settings_links`: 외부 링크용 (`support_url`, `notices_url`, `policy_url`)
- `has_password_login`: 비밀번호 행 표시 여부 힌트
- `birth_date`, `birth_year`, `birth_month`, `birth_day`, `gender`, `address`: 회원정보 수정 화면용
- `session_refresh_required`: 이메일 변경 직후 재로그인/토큰 갱신 필요 여부

```json
{
  "user_id": 2,
  "email": "test1@test.com",
  "full_name": "Test Owner 1",
  "phone_number": "01011112222",
  "phone_number_masked": "010-****-2222",
  "role": "owner",
  "role_label_ko": "경영주",
  "usage_type_label_ko": "사업주",
  "approval_status": "approved_by_admin",
  "approval_status_label_ko": "관리자 승인 완료",
  "signup_step": "completed",
  "signup_step1_passed": true,
  "signup_step2_passed": true,
  "is_active": true,
  "member_since": "2026-01-01T00:00:00Z",
  "birth_date": "1999-03-08",
  "birth_year": 1999,
  "birth_month": 3,
  "birth_day": 8,
  "gender": "male",
  "address": "부산 해운대구 반송동",
  "branches": [],
  "settings_links": {
    "support_url": null,
    "notices_url": null,
    "policy_url": null
  },
  "has_password_login": true,
  "session_refresh_required": false
}
```

---

## PATCH `/me/account`

이메일·이름·생년월일·성별·전화번호·주소 갱신. **보낸 필드만** 수정합니다.

### Request Body

```json
{
  "email": "worker1@test.com",
  "full_name": "홍길동",
  "birth_year": 1999,
  "birth_month": 3,
  "birth_day": 8,
  "gender": "male",
  "phone_number": "01012345678",
  "address": "부산 해운대구 반송동"
}
```

### Response (200)

`GET /me/account`와 동일 스키마.

- 이메일이 변경된 경우 `session_refresh_required=true`
- 이메일 중복이면 `400`
- 생년월일은 연/월/일을 모두 보내야 하며, 잘못된 날짜면 `400`

---

## POST `/me/account/password`

로그인 상태에서 현재 비밀번호를 확인한 뒤 비밀번호 변경.

### Request Body

```json
{
  "current_password": "기존비밀번호",
  "new_password": "새비밀번호8자이상"
}
```

### Response (200)

```json
{
  "updated": true,
  "message": "비밀번호가 변경되었습니다."
}
```

- 현재 비밀번호 불일치 시 `400`

---

## POST `/auth/password/reset/by-phone`

비로그인 상태에서 **Firebase 전화번호 인증이 끝난 직후** 호출하는 비밀번호 재설정 API.  
서버는 전달된 `phone_number` 기준으로 활성 계정을 찾아 비밀번호를 새 값으로 교체합니다.

### Request Body

```json
{
  "phone_number": "01012345678",
  "new_password": "새비밀번호8자이상"
}
```

### Response (200)

```json
{
  "reset": true,
  "message": "비밀번호가 재설정되었습니다.",
  "has_password_login": true
}
```

### 실패 케이스

- 일치하는 활성 계정이 없으면 `404`
- 동일 전화번호 활성 계정이 여러 개면 `409`
- 비밀번호 정책 위반이면 `400`

---

## GET `/auth/phone-number-exists?phone_number=01012345678`

이미 가입된 전화번호인지 확인.  
비밀번호 찾기 진입 전 또는 회원가입 중복 체크에 사용.

### Response (200)

```json
{
  "phone_number": "01012345678",
  "exists": true,
  "has_password_login": true
}
```

- `exists=false`면 가입 이력이 없는 번호
- 소셜 계정만 있고 비밀번호가 아직 없으면 `exists=true`, `has_password_login=false`

---

## POST `/me/account/withdraw`

회원 탈퇴(계정 `is_active=false`). 이후 토큰으로는 API 호출 불가.

### Request Body

```json
{
  "confirm": true
}
```

### Response (200)

```json
{
  "withdrawn": true,
  "message": "탈퇴 처리되었습니다. 이용해 주셔서 감사합니다."
}
```

---

## GET `/me/notices`

일반 사용자 공지사항 목록.

### Query

- `page` (default=1)
- `page_size` (default=20)

### Response (200)

```json
{
  "items": [
    {
      "notice_id": 101,
      "title": "서비스 점검 안내",
      "content": "2026년 4월 10일 02:00~04:00 동안 점검이 진행됩니다.",
      "published_at": "2026-04-05T09:00:00Z"
    }
  ],
  "total_count": 1,
  "page": 1,
  "page_size": 20
}
```

---

## GET `/me/notices/{notice_id}`

공지사항 상세.

### Response (200)

```json
{
  "notice_id": 101,
  "title": "서비스 점검 안내",
  "content": "2026년 4월 10일 02:00~04:00 동안 점검이 진행됩니다.",
  "published_at": "2026-04-05T09:00:00Z"
}
```

---

## POST `/me/inquiries`

일반 사용자가 문의 등록.

### Request Body

```json
{
  "inquiry_type": "account",
  "title": "로그인이 안 돼요",
  "content": "전화번호 인증은 끝났는데 로그인 단계에서 막힙니다."
}
```

허용 예시:

- `account`
- `service`
- `recruitment`
- `payment`
- `etc`

### Response (201)

```json
{
  "inquiry_id": 501,
  "inquiry_type": "account",
  "title": "로그인이 안 돼요",
  "content": "전화번호 인증은 끝났는데 로그인 단계에서 막힙니다.",
  "created_at": "2026-04-05T10:30:00Z",
  "is_answered": false,
  "is_answer_checked": false,
  "answer": null,
  "answered_at": null
}
```

---

## GET `/me/inquiries`

내 문의 목록.

### Query

- `page` (default=1)
- `page_size` (default=20)

### Response (200)

```json
{
  "items": [
    {
      "inquiry_id": 501,
      "inquiry_type": "account",
      "title": "로그인이 안 돼요",
      "content": "전화번호 인증은 끝났는데 로그인 단계에서 막힙니다.",
      "created_at": "2026-04-05T10:30:00Z",
      "is_answered": true,
      "is_answer_checked": false,
      "answer": "앱을 최신 버전으로 업데이트한 뒤 다시 시도해 주세요.",
      "answered_at": "2026-04-05T11:00:00Z"
    }
  ],
  "total_count": 1,
  "page": 1,
  "page_size": 20
}
```

---

## GET `/me/inquiries/{inquiry_id}`

내 문의 상세 + 답변 확인 여부 조회.

### Response (200)

```json
{
  "inquiry_id": 501,
  "inquiry_type": "account",
  "title": "로그인이 안 돼요",
  "content": "전화번호 인증은 끝났는데 로그인 단계에서 막힙니다.",
  "created_at": "2026-04-05T10:30:00Z",
  "is_answered": true,
  "is_answer_checked": false,
  "answer": "앱을 최신 버전으로 업데이트한 뒤 다시 시도해 주세요.",
  "answered_at": "2026-04-05T11:00:00Z"
}
```

---

## POST `/me/inquiries/{inquiry_id}/answer-check`

사용자가 답변을 열람했음을 표시.

### Request Body

없음

### Response (200)

```json
{
  "inquiry_id": 501,
  "is_answer_checked": true,
  "checked_at": "2026-04-05T11:05:00Z"
}
```

---

## 환경변수 (설정 화면 링크)

- `ACCOUNT_SUPPORT_URL` — 외부 고객센터 링크
- `ACCOUNT_NOTICES_URL` — 외부 공지 페이지가 따로 있을 때만 사용
- `ACCOUNT_POLICY_URL` — 이용정책

앱 내 공지/문의는 각각 `GET /me/notices`, `GET/POST /me/inquiries`로 처리합니다.

---

## 기존 `GET /me`와의 관계

- `GET /me`: 역할별 홈용 요약
- `GET /me/account`: 계정/설정 UI용 통합 응답

점장은 `GET /me`의 `manager.assigned_branches`에 배정된 모든 점포가 포함됩니다.

---

## Cursor + Figma MCP 연결

1. **Figma Desktop**에서 해당 파일을 연 뒤, 로컬 MCP(예: `http://127.0.0.1:3845/mcp`)가 실행 중이어야 합니다.
2. 프로젝트 루트 `.cursor/mcp.json`에 서버를 등록합니다.
3. Cursor **Settings → MCP**에서 해당 서버가 **Enabled / Connected**인지 확인합니다.  
   에이전트 도구 목록에 `project-…-local-mcp` 형태로 나타날 수 있습니다.
