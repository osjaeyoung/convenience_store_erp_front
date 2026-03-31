# 내 계정 정보 API (개인 공간)

기본 prefix: `/api/v1`

Figma 파일 `개인 공간`의 계정·설정 플로우에 맞춘 API입니다.  
전화번호 **인증**은 Firebase에서 처리하고, 인증 후 앱이 `PATCH /me/account`로 `phone_number`만 동기화하면 됩니다.

## Figma 화면 ↔ API

| 노드 ID | 화면명 | 서버 API |
|---------|--------|----------|
| 2634:16151 | 설정 (메뉴) | `GET /me/account` → `settings_links` + 클라이언트 라우팅 |
| 2634:16115 | 내정보설정 (하위 메뉴) | 클라이언트 네비게이션 |
| 2634:16280 | 내 정보 설정 (이름·사용유형·전화·비밀번호) | `GET /me/account` |
| 2634:16329 | 내 정보 설정 (소셜, 비밀번호 행 없음) | `GET /me/account` + `has_password_login`로 분기 |
| 2634:16196 | 비밀번호 변경 (본인 확인: 전화·이름) | Firebase 인증 후 `PATCH /me/account` 등 |
| 2634:16243 | 비밀번호 변경 (새 비밀번호) | `POST /me/account/password` |
| 2634:16082 | 로그아웃 확인 | 클라이언트에서 토큰 삭제 + `POST /auth/logout` 있으면 사용 |
| 2634:16384 | 탈퇴 확인 | `POST /me/account/withdraw` |

## 인증

- `Authorization: Bearer {access_token}`

---

## GET `/me/account`

### Response (200) 주요 필드

- `usage_type_label_ko`: Figma **사용 유형** (`owner` → `사업주`, `manager` → `점장`, `worker` → `근무자`)
- `role_label_ko`: 기존 표기 (`owner` → `경영주` 등)
- `settings_links`: `support_url`, `notices_url`, `policy_url` — `.env`의 `ACCOUNT_*_URL` (미설정 시 `null`)
- `has_password_login`: 비밀번호 변경 행 표시 여부 힌트

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
  "branches": [],
  "settings_links": {
    "support_url": null,
    "notices_url": null,
    "policy_url": null
  },
  "has_password_login": true
}
```

---

## PATCH `/me/account`

이름·전화번호 갱신. **보낸 필드만** 수정합니다.

### Request Body

```json
{
  "full_name": "홍길동",
  "phone_number": "01012345678"
}
```

### Response (200)

`GET /me/account`와 동일 스키마.

---

## POST `/me/account/password`

로그인 상태에서 비밀번호 변경.

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

- 현재 비밀번호 불일치 시 400.

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

## 환경변수 (설정 화면 링크)

- `ACCOUNT_SUPPORT_URL` — 고객센터/문의하기
- `ACCOUNT_NOTICES_URL` — 공지사항
- `ACCOUNT_POLICY_URL` — 이용정책

---

## 기존 `GET /me`와의 관계

- `GET /me`: 역할별 홈용 요약.
- `GET /me/account`: **계정/설정 UI**용 통합 응답.

점장은 `GET /me`의 `manager.assigned_branches`에 배정된 모든 점포가 포함됩니다.

---

## Cursor + Figma MCP 연결

1. **Figma Desktop**에서 해당 파일을 연 뒤, 로컬 MCP(예: `http://127.0.0.1:3845/mcp`)가 실행 중이어야 합니다.
2. 프로젝트 루트 `.cursor/mcp.json`에 서버를 등록합니다.
3. Cursor **Settings → MCP**에서 해당 서버가 **Enabled / Connected**인지 확인합니다.  
   에이전트 도구 목록에 `project-…-local-mcp` 형태로 나타날 수 있습니다.
